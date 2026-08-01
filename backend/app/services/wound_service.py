"""
services/wound_services.py
==========================
Orchestration layer for the wound-analysis pipeline.

This module sits between the API layer (``api/wound.py``) and the lower-level
image-processing and AI sub-systems.  It coordinates a four-step pipeline:

    1. Decode raw image bytes into a NumPy array (via ``image_processing``).
    2. Assess image quality and gate on minimum thresholds (via ``image_quality``).
    3. Run AI inference on the validated image (via ``ai.model``).
    4. Apply deterministic rule-engine assessment (via ``engine``).

The AI model (step 3) performs *observation and classification only*.
All risk scoring, recommendations, referral decisions, and follow-up
scheduling are produced exclusively by the rule engine (step 4).

After the pipeline completes, the results (image metadata, quality metrics,
and analysis output) are persisted to the database.
"""

import logging
import uuid

from fastapi import UploadFile
from pydantic import ValidationError
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.ai.model import analyze_wound
from app.engine import WoundAssessmentEngine
from app.exceptions import (
    ImageQualityError,
    InternalServerError,
    InvalidImageError,
    InvalidPatientDataError,
)
from app.models.analysis_result import WoundAnalysisDBResult
from app.models.image_quality_result import ImageQualityResult
from app.models.wound_assessment import WoundAssessment
from app.models.wound_image import WoundImage
from app.schemas.wound import (
    AssessmentListResponse,
    AssessmentSummary,
    PatientInfo,
    WoundAnalysisRequest,
    WoundAnalysisResponse,
    WoundAnalysisResult,
)
from app.services.image_processing import process_image
from app.services.image_quality import assess_image_quality
from app.utils.save_to_disk import _save_image_to_disk
from typing import List

logger = logging.getLogger(__name__)

# Module-level engine instance — initialised once, reused across requests.
_engine = WoundAssessmentEngine()

class WoundService:

    def __init__(self, db: Session):
        self.db = db

    async def analyze_wound(
            self,
            requests: WoundAnalysisRequest,
            images: List[UploadFile],
            ) -> WoundAnalysisResponse:

        # Validate patient info
        try:
            patient = PatientInfo(
                age=requests.age,
                sex=requests.sex,
                symptoms=requests.symptoms,
                duration=requests.duration,
                medical_history=requests.medical_history,
            )
        except ValidationError as exc:
            raise InvalidPatientDataError(exc.errors()) from exc

        # Create patient record
        try:
            assessment_row = WoundAssessment(
                patient_age=requests.age,
                patient_sex=requests.sex,
                symptoms=requests.symptoms,  # already parsed list
                duration=requests.duration,
                medical_history=requests.medical_history,
            )
            self.db.add(assessment_row)
            self.db.flush()  # obtain assessment_row.id for FK references
    
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
                result_dict = self.process_wound_image(
                    image_bytes=image_bytes,
                    assessment_id=assessment_id,
                    image_path=image_path,
                    original_filename=image.filename,
                    content_type=image.content_type,
                    duration=requests.duration,
                )
    
                # Validate and deserialize the engine output
                image_results.append(WoundAnalysisResult.model_validate(result_dict))
    
            return WoundAnalysisResponse(
                assessment_id=str(assessment_id),
                patient=patient,
                results=image_results,
            )
        
        except ImageQualityError as exc:
            raise InvalidImageError(exc.reason)
        
        except Exception:
            logger.exception(
                "Unexpected error during wound analysis "
                "(images=%d age=%s sex=%s)",
                len(images),
                requests.age,
                requests.sex,
            )
            raise InternalServerError from exc


    def process_wound_image(
        self,
        image_bytes: bytes,
        assessment_id: uuid.UUID,
        image_path: str,
        original_filename: str | None = None,
        content_type: str | None = None,
        duration: str | None = None,
    ) -> dict:
        """
        Run the full wound-analysis pipeline on raw image bytes and persist
        the results to the database.

        Parameters
        ----------
        db:
            Active SQLAlchemy session (caller manages the transaction).
        image_bytes:
            Raw bytes of the uploaded wound image.
        assessment_id:
            UUID of the parent ``WoundAssessment`` row.
        image_path:
            File path or URL where the image is stored on disk.
        original_filename:
            Original filename as uploaded by the client.
        content_type:
            MIME type of the uploaded file (e.g. ``'image/jpeg'``).
        duration:
            Optional patient-reported wound duration (e.g. ``"1-3 Days"``).

        Returns
        -------
        dict
            Combined result containing both the AI classification and the
            rule-engine assessment output, ready for API serialisation.

        Raises
        ------
        ValueError
            If the image quality is below the minimum acceptable threshold.
        engine.validation.InputValidationError
            If the AI model output does not conform to the expected schema.
        """
        logger.info("Starting analyzing wound image")

        # Step 1: Decode the raw bytes into a NumPy BGR image array.
        img = process_image(image_bytes)

        # Step 2: Compute quality metrics and enforce minimum thresholds.
        quality = assess_image_quality(img)

        # ── Persist the image record ──────────────────────────────────────────
        wound_image = WoundImage(
            assessment_id=assessment_id,
            image_path=image_path,
            original_filename=original_filename,
            content_type=content_type,
        )
        self.db.add(wound_image)
        self.db.flush()  # obtain wound_image.id for FK references

        # ── Persist quality metrics ───────────────────────────────────────────
        quality_record = ImageQualityResult(
            image_id=wound_image.id,
            is_valid=quality["is_valid"],
            blur=quality["metrics"]["blur"],
            brightness=quality["metrics"]["brightness"],
            contrast=quality["metrics"]["contrast"],
        )
        self.db.add(quality_record)

        if not quality["is_valid"]:
            raise ImageQualityError("Image quality too low")

        # Step 3: Run AI inference on the validated image.
        model_output = analyze_wound(img)
        logger.info("AI model inference complete.")

        # Step 4: Apply the deterministic rule engine to the model output.
        patient_context = {"duration": duration} if duration else None
        assessment = _engine.assess(model_output, patient_context=patient_context)
        logger.info(
            "Rule engine assessment complete — level=%s, emergency=%s.",
            assessment.risk_level,
            assessment.emergency,
        )

        # ── Extract classification from model output ─────────────────────────
        classification = model_output.get("classification", {})
        wound_type = classification.get("wound_type", "unknown")
        severity = classification.get("severity", "unknown")
        healing_stage = classification.get("healing_stage", "unknown")
        confidence = model_output.get("confidence", 0.0)

        # ── Persist analysis result ───────────────────────────────────────────
        assessment_dict = assessment.model_dump()
        analysis_record = WoundAnalysisDBResult(
            image_id=wound_image.id,
            wound_type=wound_type,
            severity=severity,
            healing_stage=healing_stage,
            confidence=confidence,
            risk_score=assessment_dict["risk_score"],
            risk_level=assessment_dict["risk_level"],
            recommendations=assessment_dict["recommendations"],
            referral_required=assessment_dict["referral_required"],
            emergency=assessment_dict["emergency"],
            follow_up=assessment_dict["follow_up"],
            triggered_rules=assessment_dict["triggered_rules"],
            disclaimer=assessment_dict["disclaimer"],
        )
        self.db.add(analysis_record)

        # ── Build combined response ───────────────────────────────────────────
        result = {
            "wound_type": wound_type,
            "severity": severity,
            "healing_stage": healing_stage,
            "confidence": confidence,
            **assessment_dict,
        }

        return result

    def get_assessments(
            self,
            limit: int,
            offset: int,
        ) -> AssessmentListResponse:

        total = self.db.query(func.count(WoundAssessment.id)).scalar() or 0

        rows = (
            self.db.query(WoundAssessment)
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
        