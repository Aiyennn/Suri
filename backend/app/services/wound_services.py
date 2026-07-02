
from services.image_quality import assess_image_quality
from services.image_processing import process_image
from ai.model import analyze_wound

import logging

logger = logging.getLogger(__name__)


def analyze_wound_image(image_bytes: bytes):
    logger.info("analyze_wound_image called")
    img = process_image(image_bytes)

    quality = assess_image_quality(img)
    if not quality["is_valid"]:
        raise ValueError("Image quality too low")
    
    # Fix data shape
    return analyze_wound(img)