from utils.image_processing import (
    blur_score,
    brightness_score,
    contrast_score,
)
import logging

logger = logging.getLogger(__name__)

def compute_image_quality(image):
    return {
        "blur": blur_score(image),
        "brightness": brightness_score(image),
        "contrast": contrast_score(image),
    }

def assess_image_quality(image):
    logger.info("Assessing image quality")
    metrics = compute_image_quality(image)
    print(metrics)

    is_blurry = metrics["blur"] < 100
    too_dark = metrics["brightness"] < 40
    too_bright = metrics["brightness"] > 220
    low_contrast = metrics["contrast"] < 15

    return {
        "is_valid": not (is_blurry or too_dark or too_bright or low_contrast),
        "metrics": metrics,
    }

