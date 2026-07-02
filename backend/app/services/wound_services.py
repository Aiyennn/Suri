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
"""

from services.image_quality import assess_image_quality
from services.image_processing import process_image
from ai.model import analyze_wound
from engine import WoundAssessmentEngine

import logging

logger = logging.getLogger(__name__)

# Module-level engine instance — initialised once, reused across requests.
_engine = WoundAssessmentEngine()


def analyze_wound_image(image_bytes: bytes) -> dict:
    """
    Run the full wound-analysis pipeline on raw image bytes.

    Parameters
    ----------
    image_bytes:
        Raw bytes of the uploaded wound image.

    Returns
    -------
    dict
        Serialised :class:`engine.models.AssessmentResult` containing:
        risk score, risk level, recommendations, referral flag, emergency
        flag, follow-up timing, and all triggered rule explanations.

    Raises
    ------
    ValueError
        If the image quality is below the minimum acceptable threshold.
    engine.validation.InputValidationError
        If the AI model output does not conform to the expected schema.
    """
    logger.info("analyze_wound_image called")

    # Step 1: Decode the raw bytes into a NumPy BGR image array.
    img = process_image(image_bytes)

    # Step 2: Compute quality metrics and enforce minimum thresholds.
    # Returns a dict with keys ``is_valid`` (bool) and ``metrics`` (dict).
    quality = assess_image_quality(img)
    if not quality["is_valid"]:
        raise ValueError("Image quality too low")

    # Step 3: Run AI inference on the validated image.
    # The model returns structured observations and classifications only —
    # it never produces treatment recommendations.
    model_output = analyze_wound(img)
    logger.info("AI model inference complete.")

    # Step 4: Apply the deterministic rule engine to the model output.
    # All risk assessments, recommendations, referrals, and follow-up
    # decisions originate here — never from the AI model.
    assessment = _engine.assess(model_output)
    logger.info(
        "Rule engine assessment complete — level=%s, emergency=%s.",
        assessment.risk_level,
        assessment.emergency,
    )

    return assessment.model_dump()
