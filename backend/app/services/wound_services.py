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

import uuid
import logging

from sqlalchemy.orm import Session

from services.image_quality import assess_image_quality
from services.image_processing import process_image
from ai.model import analyze_wound
from engine import WoundAssessmentEngine

from models.wound_image import WoundImage
from models.image_quality_result import ImageQualityResult
from models.analysis_result import WoundAnalysisDBResult

logger = logging.getLogger(__name__)

# Module-level engine instance — initialised once, reused across requests.
_engine = WoundAssessmentEngine()


def analyze_wound_image(
    db: Session,
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
    db.add(wound_image)
    db.flush()  # obtain wound_image.id for FK references

    # ── Persist quality metrics ───────────────────────────────────────────
    quality_record = ImageQualityResult(
        image_id=wound_image.id,
        is_valid=quality["is_valid"],
        blur=quality["metrics"]["blur"],
        brightness=quality["metrics"]["brightness"],
        contrast=quality["metrics"]["contrast"],
    )
    db.add(quality_record)

    if not quality["is_valid"]:
        raise ValueError("Image quality too low")

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
    db.add(analysis_record)

    # ── Build combined response ───────────────────────────────────────────
    result = {
        "wound_type": wound_type,
        "severity": severity,
        "healing_stage": healing_stage,
        "confidence": confidence,
        **assessment_dict,
    }

    return result
