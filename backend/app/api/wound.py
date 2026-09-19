"""
api/wound.py
============
FastAPI router for wound-analysis endpoints.

All routes in this module are mounted under the ``/wound`` prefix by
``main.py``, so the full paths are:

    POST /wound/analyze   – Submit patient info + wound images for analysis.
    GET  /wound/assessments – List all past assessment sessions.

Request format for POST /wound/analyze:
    multipart/form-data with the following fields:
        age            (str)  – Patient age.
        sex            (str)  – Patient biological sex: 'male', 'female', or 'other'.
        symptoms       (str)  – JSON-encoded array of symptom strings.
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

from app.dependencies import get_db, get_wound_service
from app.models.user import User
from app.schemas.wound import (
    AssessmentListResponse,
    PatientInfo,
    WoundAnalysisResponse,
)
from app.services.auth_service import get_current_user
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
    patient: PatientInfo = Depends(PatientInfo.from_form),
    images: list[UploadFile] = File(...),
    db: Session = Depends(get_db),
    wound_service: WoundService = Depends(get_wound_service),
    current_user: User = Depends(get_current_user),
):
    try:
        result = await wound_service.analyze_wound(patient, images, current_user.id)
        db.commit()
        return result
    except Exception:
        db.rollback()
        logger.exception(
            "Wound analysis failed (age=%s sex=%s)", patient.age, patient.sex
        )
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
    wound_service: WoundService = Depends(get_wound_service),
    current_user: User = Depends(get_current_user),
) -> AssessmentListResponse:
    try:
        return wound_service.get_assessments(current_user.id, limit, offset)
    except Exception:
        logger.exception("list_assessments failed (limit=%d offset=%d)", limit, offset)
        raise