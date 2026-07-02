"""
services/wound_services.py
==========================
Orchestration layer for the wound-analysis pipeline.

This module sits between the API layer (``api/wound.py``) and the lower-level
image-processing and AI sub-systems.  It coordinates the three-step pipeline:

    1. Decode raw image bytes into a NumPy array (via ``image_processing``).
    2. Assess image quality and gate on minimum thresholds (via ``image_quality``).
    3. Run AI inference on the validated image (via ``ai.model``).

Keeping this logic in a service module (rather than directly in the router)
makes it easy to unit-test without spinning up an HTTP server, and allows the
same pipeline to be reused from CLI scripts or batch jobs.
"""

from services.image_quality import assess_image_quality
from services.image_processing import process_image
from ai.model import analyze_wound

import logging

logger = logging.getLogger(__name__)


def analyze_wound_image(image_bytes: bytes) -> dict:
    """
    Run the full wound-analysis pipeline on a single raw image.

    Steps:
        1. **Decode** – Convert raw bytes to a BGR NumPy array using OpenCV.
        2. **Quality gate** – Compute blur, brightness, and contrast metrics.
           Raise ``ValueError`` if the image does not meet minimum thresholds.
        3. **AI inference** – Pass the decoded image to the wound-risk model
           and return its prediction.

    Args:
        image_bytes (bytes): Raw binary content of the uploaded image file.

    Returns:
        dict: AI model output containing at minimum:
            - ``"risk"`` (str): ``"low"``, ``"medium"``, or ``"high"``.
            - ``"confidence"`` (float): Model confidence in [0.0, 1.0].

    Raises:
        ValueError: If the image quality assessment fails (too blurry,
                    too dark, overexposed, or low contrast).
        cv2.error: If the image bytes cannot be decoded as a valid image.
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
    return analyze_wound(img)