
from app.services.image_quality import assess_image_quality
from app.services.image_processing import process_image
from app.ai.model import analyze_wound


def analyze_wound_image(image_bytes: bytes):
    img = process_image(image_bytes)

    quality = assess_image_quality(img)
    if not quality["is_valid"]:
        raise ValueError("Image quality too low")
    
    # Fix data shape
    return analyze_wound(img)