from fastapi import APIRouter, UploadFile, File
import logging

from app.services.wound_services import process_image
from app.ai.model import predict_wound

logger = logging.getLogger(__name__)

router = APIRouter()

@router.post("/analyze")
async def analyze_wound(image: UploadFile = File(...)):

    logger.info(f"analyze_wound called")
    try:
        image_bytes = await image.read()
        img = process_image(image_bytes)
        result = predict_wound(img)

        return {
            "urgency": result["risk"],
            "confidence": result["confidence"],
            "findings": [
                "wound_detected"
            ]
        }
    
    except Exception as e:
        logger.error(f"Error processing image: {str(e)}")
        raise