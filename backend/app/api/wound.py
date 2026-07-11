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
        "patient": { age, sex, symptoms, duration, medical_history },
        "results": [{ risk_score, risk_level, recommendations, ... }, ...]
    }
"""

from typing import List

from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from pydantic import ValidationError
import logging

from schemas.wound import PatientInfo, WoundAnalysisResult, WoundAnalysisResponse
from services.wound_services import analyze_wound_image

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
        "Returns the patient context and a full risk assessment per image."
    ),
)
async def analyze_wound(
    age: str = Form(..., description="Patient age, e.g. '34'."),
    sex: str = Form(..., description="Patient biological sex: 'male', 'female', or 'other'."),
    symptoms: str = Form(..., description="JSON-encoded list of symptom strings, e.g. '[\"redness\",\"swelling\"]'."),
    duration: str = Form(..., description="Duration the wound has been present, e.g. '3 days'."),
    medical_history: str = Form(..., description="Relevant past medical conditions or medications."),
    images: List[UploadFile] = File(..., description="One or more wound images (JPEG or PNG)."),
):
    """
    Analyse one or more wound images alongside patient context.

    Processing pipeline per image:
        1. Validate patient form fields against ``PatientInfo`` schema.
        2. Read raw bytes from the uploaded file.
        3. Decode the image and compute quality metrics (blur, brightness, contrast).
        4. Reject the request with HTTP 400 if any image fails the quality gate.
        5. Pass the decoded image to the AI model for observation/classification.
        6. Run the deterministic rule engine to produce risk score, recommendations,
           referral flag, emergency flag, and follow-up timing.

    Args:
        age:             Patient age string.
        sex:             Patient biological sex ('male', 'female', or 'other').
        symptoms:        JSON-encoded list of symptom strings.
        duration:        How long the wound has been present.
        medical_history: Relevant medical background.
        images:          Uploaded image files.

    Returns:
        WoundAnalysisResponse: Validated patient info + one assessment per image.

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

    # ── Step 2-6: Process each image through the pipeline ─────────────────
    try:
        image_results: List[WoundAnalysisResult] = []
        for image in images:
            image_bytes = await image.read()

            # analyze_wound_image raises ValueError on low-quality images
            result_dict = analyze_wound_image(image_bytes, duration=duration)

            # Validate and deserialize the engine output against WoundAnalysisResult
            image_results.append(WoundAnalysisResult.model_validate(result_dict))

        return WoundAnalysisResponse(patient=patient, results=image_results)

    except ValueError as exc:
        # Raised by the image-quality gate or engine input validation
        raise HTTPException(status_code=400, detail=str(exc))

    except Exception:
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
