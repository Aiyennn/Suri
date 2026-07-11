"""
api/wound.py
============
FastAPI router for wound-analysis endpoints.

All routes in this module are mounted under the ``/wound`` prefix by
``main.py``, so the full paths are:

    POST /wound/analyze   – Submit patient info + wound images for analysis.

Request format:
    multipart/form-data with the following fields:
        age            (str)  – Patient age.
        sex            (str)  – Patient biological sex: 'male', 'female', or 'other'.
        symptoms       (str)  – JSON-encoded list of symptom strings.
        duration       (str)  – How long the wound has been present.
        medical_history(str)  – Relevant medical background.
        images         (file[])– One or more wound images (JPEG/PNG).

Response shape (see schemas/wound.py for the full Pydantic models):
    {
        "assessment_id": "<uuid>",
        "patient": { age, sex, symptoms, duration, medical_history },
        "results": [{ wound_type, severity, ..., risk_score, risk_level, ... }, ...]
    }
"""

import os
import uuid
from pathlib import Path
from typing import List

from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from pydantic import ValidationError
from sqlalchemy.orm import Session
import logging

from core.config import settings
from dependencies import get_db
from models.wound_assessment import WoundAssessment
from schemas.wound import (
    PatientInfo,
    WoundAnalysisResult,
    WoundAnalysisResponse,
    AssessmentSummary,
    AssessmentListResponse,
)
from services.wound_services import analyze_wound_image

logger = logging.getLogger(__name__)

router = APIRouter()


def _save_image_to_disk(image_bytes: bytes, assessment_id: uuid.UUID, filename: str) -> str:
    """
    Persist raw image bytes to the uploads directory.

    Directory structure: ``<UPLOAD_DIR>/<assessment_id>/<filename>``

    Returns the relative path string stored in the database.
    """
    assessment_dir = Path(settings.UPLOAD_DIR) / str(assessment_id)
    assessment_dir.mkdir(parents=True, exist_ok=True)

    # Ensure unique filenames by prepending a short UUID
    unique_filename = f"{uuid.uuid4().hex[:8]}_{filename}"
    file_path = assessment_dir / unique_filename

    file_path.write_bytes(image_bytes)
    logger.debug("Saved image to %s (%d bytes)", file_path, len(image_bytes))

    # Store as a relative path from UPLOAD_DIR for portability
    return str(Path(str(assessment_id)) / unique_filename)


@router.post(
    "/analyze",
    response_model=WoundAnalysisResponse,
    summary="Analyse wound images",
    description=(
        "Submit patient demographics and one or more wound photographs. "
        "Each image is validated for quality (blur, brightness, contrast) "
        "and then passed through the wound-risk AI model and rule engine. "
        "Returns the patient context and a full risk assessment per image. "
        "All data is persisted to the database."
    ),
)
async def analyze_wound(
    age: str = Form(..., description="Patient age, e.g. '34'."),
    sex: str = Form(..., description="Patient biological sex: 'male', 'female', or 'other'."),
    symptoms: str = Form(..., description="JSON-encoded list of symptom strings, e.g. '[\"redness\",\"swelling\"]'."),
    duration: str = Form(..., description="Duration the wound has been present, e.g. '3 days'."),
    medical_history: str = Form(..., description="Relevant past medical conditions or medications."),
    images: List[UploadFile] = File(..., description="One or more wound images (JPEG or PNG)."),
    db: Session = Depends(get_db),
):
    """
    Analyse one or more wound images alongside patient context.

    Processing pipeline per image:
        1. Validate patient form fields against ``PatientInfo`` schema.
        2. Create a ``WoundAssessment`` row with patient context.
        3. Read raw bytes from each uploaded file and save to disk.
        4. Decode the image and compute quality metrics (blur, brightness, contrast).
        5. Reject the request with HTTP 400 if any image fails the quality gate.
        6. Pass the decoded image to the AI model for observation/classification.
        7. Run the deterministic rule engine to produce risk score, recommendations,
           referral flag, emergency flag, and follow-up timing.
        8. Persist all results (image, quality, analysis) to the database.
        9. Commit the transaction and return the response.

    Args:
        age:             Patient age string.
        sex:             Patient biological sex ('male', 'female', or 'other').
        symptoms:        JSON-encoded list of symptom strings.
        duration:        How long the wound has been present.
        medical_history: Relevant medical background.
        images:          Uploaded image files.
        db:              SQLAlchemy session (injected).

    Returns:
        WoundAnalysisResponse: Assessment ID + validated patient info + one
        assessment per image.

    Raises:
        HTTPException 422: If patient input fails schema validation.
        HTTPException 400: If any image fails the quality gate.
        HTTPException 500: For unexpected internal errors.
    """
    # ── Step 1: Validate patient input ────────────────────────────────────
    try:
        patient = PatientInfo(
            age=age,
            sex=sex,
            symptoms=symptoms,   # field_validator handles JSON decoding
            duration=duration,
            medical_history=medical_history,
        )
    except ValidationError as exc:
        raise HTTPException(status_code=422, detail=exc.errors())

    # ── Step 2: Create the assessment record ──────────────────────────────
    try:
        assessment_row = WoundAssessment(
            patient_age=age,
            patient_sex=sex,
            symptoms=patient.symptoms,  # already parsed list
            duration=duration,
            medical_history=medical_history,
        )
        db.add(assessment_row)
        db.flush()  # obtain assessment_row.id for FK references

        assessment_id = assessment_row.id
        logger.info("Created assessment %s", assessment_id)

        # ── Steps 3-8: Process each image through the pipeline ────────────
        image_results: List[WoundAnalysisResult] = []
        for image in images:
            image_bytes = await image.read()

            # Save the image to disk
            image_path = _save_image_to_disk(
                image_bytes,
                assessment_id,
                image.filename or "wound_image.jpg",
            )

            # Run the analysis pipeline and persist results
            result_dict = analyze_wound_image(
                db=db,
                image_bytes=image_bytes,
                assessment_id=assessment_id,
                image_path=image_path,
                original_filename=image.filename,
                content_type=image.content_type,
                duration=duration,
            )

            # Validate and deserialize the engine output
            image_results.append(WoundAnalysisResult.model_validate(result_dict))

        # ── Step 9: Commit the transaction ────────────────────────────────
        db.commit()
        logger.info(
            "Assessment %s committed (%d images)",
            assessment_id,
            len(image_results),
        )

        return WoundAnalysisResponse(
            assessment_id=str(assessment_id),
            patient=patient,
            results=image_results,
        )

    except ValueError as exc:
        # Raised by the image-quality gate or engine input validation
        db.rollback()
        raise HTTPException(status_code=400, detail=str(exc))

    except Exception:
        db.rollback()
        logger.exception(
            "Unexpected error during wound analysis "
            "(images=%d age=%s sex=%s)",
            len(images),
            age,
            sex,
        )
        raise HTTPException(
            status_code=500,
            detail="Internal Server Error",
        )


@router.get(
    "/assessments",
    response_model=AssessmentListResponse,
    summary="List past assessments",
    description=(
        "Return all persisted wound-assessment sessions, ordered newest-first. "
        "Each item includes patient demographics and a summary of the first "
        "image's analysis result."
    ),
)
def list_assessments(
    limit: int = 50,
    offset: int = 0,
    db: Session = Depends(get_db),
) -> AssessmentListResponse:
    """
    Retrieve a paginated list of wound-assessment sessions.

    Args:
        limit:  Maximum number of assessments to return (default 50).
        offset: Number of assessments to skip for pagination (default 0).
        db:     SQLAlchemy session (injected).

    Returns:
        AssessmentListResponse containing total count and list of summaries.
    """
    from models.wound_assessment import WoundAssessment
    from models.wound_image import WoundImage
    from models.analysis_result import WoundAnalysisDBResult
    from sqlalchemy import func

    # Total count
    total = db.query(func.count(WoundAssessment.id)).scalar() or 0

    # Fetch assessments ordered by creation time descending
    rows = (
        db.query(WoundAssessment)
        .order_by(WoundAssessment.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )

    summaries: list[AssessmentSummary] = []
    for row in rows:
        # Image count
        image_count = len(row.images)

        # Grab the first image's analysis result (if any)
        first_result = None
        if row.images:
            first_image = row.images[0]
            first_result = first_image.analysis_result

        summaries.append(
            AssessmentSummary(
                id=str(row.id),
                created_at=row.created_at.isoformat(),
                patient_age=row.patient_age,
                patient_sex=row.patient_sex,
                symptoms=row.symptoms,
                duration=row.duration,
                risk_level=first_result.risk_level if first_result else None,
                risk_score=first_result.risk_score if first_result else None,
                wound_type=first_result.wound_type if first_result else None,
                emergency=first_result.emergency if first_result else None,
                image_count=image_count,
            )
        )

    return AssessmentListResponse(total=total, assessments=summaries)
