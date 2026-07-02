"""
ai/model.py
===========
AI model interface for wound-risk prediction.

This module abstracts the wound-analysis model behind a single callable,
``analyze_wound``.  The current implementation is a **stub** that returns
random predictions — it exists so the full API pipeline can be exercised
end-to-end before the real model is integrated.

Real model integration checklist (TODO):
    - Load the serialised model weights at module import time (singleton
      pattern) to avoid per-request latency.
    - Replace the ``analyze_wound`` body with actual inference code.
    - Add input pre-processing (normalisation, resizing) as required by the
      model's training pipeline.
    - Expand the return dict to include wound classification and size estimate
      once the model supports those outputs.
    - Wire up GPU/CPU device selection via the ``config`` package.
"""

import random
import logging

logger = logging.getLogger(__name__)


def analyze_wound(image) -> dict:
    """
    Run wound-risk inference on a decoded image.

    **Current behaviour (stub):** Returns a randomly sampled risk level and
    confidence score.  This allows the full request pipeline to be tested
    without a trained model.

    **Expected production behaviour:** Accept a NumPy BGR array, run it
    through the wound-risk classification model, and return structured
    predictions.

    Args:
        image (numpy.ndarray): Decoded BGR image of shape (H, W, 3).
                               Must have already passed quality validation.

    Returns:
        dict: Prediction output with keys:
            - ``"risk"``       (str):   ``"low"``, ``"medium"``, or ``"high"``.
            - ``"confidence"`` (float): Model confidence in [0.0, 1.0].

    TODO:
        Replace random sampling with real model inference.
    """
    logging.info("Model analyzing wound")

    # STUB: randomly sample a risk level and confidence score.
    # Replace this block with actual model inference before production.
    return {
        "risk": random.choice(["low", "medium", "high"]),
        "confidence": round(random.uniform(0.6, 0.95), 2),
    }