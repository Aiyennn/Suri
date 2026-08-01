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


import logging

from fastapi import APIRouter, Depends, File, UploadFile
from sqlalchemy.orm import Session

from app.dependencies import get_db
from app.schemas.wound import (
    AssessmentListResponse,
    WoundAnalysisRequest,
    WoundAnalysisResponse,
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

    service = WoundService(db)

    try:
        result = service.get_assessments(limit, offset)
        return result
    except:
        print("get list_assessments failed")
        raise