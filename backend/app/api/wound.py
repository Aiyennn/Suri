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


from fastapi import APIRouter, Depends, UploadFile, File, Form
from sqlalchemy.orm import Session
import logging

from app.dependencies import get_db
from app.models.wound_assessment import WoundAssessment
from app.schemas.wound import (
    WoundAnalysisResponse,
    AssessmentSummary,
    AssessmentListResponse,
    WoundAnalysisRequest
)

from app.services.wound_service import WoundService

logger = logging.getLogger(__name__)

router = APIRouter()


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
    request: WoundAnalysisRequest = Depends(WoundAnalysisRequest.from_form),
    images: list[UploadFile] = File(...),
    db: Session = Depends(get_db)
):

    service = WoundService(db)

    try:
        result = await service.analyze_wound(request, images)
        db.commit()
        return result
    except:
        db.rollback()
        print("Wound Analysis Failed") # Change into custom error
        raise


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
    from app.models.wound_assessment import WoundAssessment
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
