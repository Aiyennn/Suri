"""
ai/model.py
===========
AI model interface for wound-risk prediction.

This module abstracts the wound-analysis model behind a single callable,
``analyze_wound``.
"""

import logging
import random

logger = logging.getLogger(__name__)


def analyze_wound(image) -> dict:
    """
    Run wound classification inference on a decoded image.

    **Current behaviour (stub):**
    Returns randomly generated predictions that match the expected
    production response schema. This allows the API and downstream
    recommendation engine to be developed before the ML model is ready. 

    **Expected production behaviour:**
    Accept a NumPy BGR image, run it through the wound classification model,
    and return structured observations extracted from the image.

    Args:
        image (numpy.ndarray):
            Decoded BGR image of shape (H, W, 3).
            Must have already passed quality validation.

    Returns:
        dict: Structured wound classification containing:
            - classification
            - observations
            - confidence

    TODO:
        Replace mock values with actual model inference.
    """
    logging.info("Model analyzing wound")

    wound_type = random.choice([
        "abrasion",
        "laceration",
        "burn",
        "pressure_ulcer",
        "diabetic_ulcer",
    ])

    severity = random.choice([
        "mild",
        "moderate",
        "severe",
    ])

    healing_stage = random.choice([
        "hemostasis",
        "inflammatory",
        "proliferative",
        "maturation",
    ])

    bleeding = random.choice([
        "none",
        "minimal",
        "moderate",
        "heavy",
    ])

    redness = random.choice([True, False])

    # Generate exudate consistently
    exudate_present = random.choice([True, False])

    if exudate_present:
        exudate = {
            "present": True,
            "type": random.choice([
                "serous",
                "sanguineous",
                "serosanguineous",
            ]),
            "amount": random.choice([
                "low",
                "moderate",
                "high",
            ]),
        }
    else:
        exudate = {
            "present": False,
            "type": "none",
            "amount": "none",
        }

    return {
        "classification": {
            "wound_type": wound_type,
            "severity": severity,
            "healing_stage": healing_stage,
        },
        "observations": {
            "redness": redness,
            "bleeding": bleeding,
            "exudate": exudate,
        },
        "confidence": round(random.uniform(0.80, 0.99), 2),
    }