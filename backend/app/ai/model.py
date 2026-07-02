"""
ai/model.py
===========
AI model interface for wound-risk prediction.

This module abstracts the wound-analysis model behind a single callable,
``analyze_wound``.
"""

import random
import logging

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

    return {
        "classification": {
            "wound_type": random.choice([
                "abrasion",
                "laceration",
                "burn",
                "pressure_ulcer",
                "diabetic_ulcer",
            ]),
            "severity": random.choice([
                "mild",
                "moderate",
                "severe",
            ]),
            "healing_stage": random.choice([
                "hemostasis",
                "inflammatory",
                "proliferative",
                "maturation",
            ]),
        },
        "observations": {
            "redness": random.choice([True, False]),
            "bleeding": random.choice([
                "none",
                "minimal",
                "moderate",
                "heavy",
            ]),
            "exudate": {
                "present": random.choice([True, False]),
                "type": random.choice([
                    "none",
                    "serous",
                    "sanguineous",
                    "serosanguineous",
                ]),
                "amount": random.choice([
                    "none",
                    "low",
                    "moderate",
                    "high",
                ]),
            },
        },
        "confidence": round(random.uniform(0.80, 0.99), 2),
    }