"""
services/image_quality.py
=========================
Image quality assessment service for the wound-analysis pipeline.

Before an image is forwarded to the AI model it must pass three pixel-level
quality checks:

    - **Blur**       – Laplacian variance must be >= 100.
                       Values below this indicate the image is too blurry for
                       reliable wound-boundary detection.
    - **Brightness** – Mean grayscale intensity must be in [40, 220].
                       Too-dark images miss wound colour cues; overexposed
                       images wash out tissue detail.
    - **Contrast**   – Grayscale standard deviation must be >= 15.
                       Low contrast flattens wound-vs-healthy-tissue differences.

These thresholds were chosen empirically and may be adjusted as the model
evolves.  See ``utils/image_processing.py`` for the underlying metric
implementations.
"""

from utils.image_processing import (
    blur_score,
    brightness_score,
    contrast_score,
)
import logging

logger = logging.getLogger(__name__)


def compute_image_quality(image) -> dict:
    """
    Compute all pixel-level quality metrics for a decoded image.

    Args:
        image (numpy.ndarray): BGR image array as returned by OpenCV.

    Returns:
        dict: A mapping of metric name to its float value:
            - ``"blur"``       (float): Laplacian variance (higher = sharper).
            - ``"brightness"`` (float): Mean grayscale intensity (0–255).
            - ``"contrast"``   (float): Std-dev of grayscale intensities (0–255).
    """
    return {
        "blur": blur_score(image),
        "brightness": brightness_score(image),
        "contrast": contrast_score(image),
    }


def assess_image_quality(image) -> dict:
    """
    Assess whether an image meets the minimum quality requirements for AI analysis.

    Computes quality metrics via :func:`compute_image_quality` and applies
    threshold checks to determine overall validity.

    Thresholds:
        - Blur score  < 100  → image is too blurry.
        - Brightness  < 40   → image is too dark.
        - Brightness  > 220  → image is overexposed.
        - Contrast    < 15   → image has insufficient contrast.

    Args:
        image (numpy.ndarray): BGR image array as returned by OpenCV.

    Returns:
        dict:
            - ``"is_valid"`` (bool): ``True`` if all thresholds are satisfied.
            - ``"metrics"``  (dict): Raw metric values (blur, brightness, contrast).
    """
    logger.info("Assessing image quality")
    metrics = compute_image_quality(image)
    print(metrics)  # TODO: replace with structured logger when log aggregation is set up

    # Individual quality checks — each maps to a specific failure mode.
    is_blurry     = metrics["blur"]       < 100   # Laplacian variance too low → blurry
    too_dark      = metrics["brightness"] < 40    # Mean intensity too low → underexposed
    too_bright    = metrics["brightness"] > 220   # Mean intensity too high → overexposed
    low_contrast  = metrics["contrast"]   < 15    # Std-dev too low → flat image

    return {
        "is_valid": not (is_blurry or too_dark or too_bright or low_contrast),
        "metrics": metrics,
    }
