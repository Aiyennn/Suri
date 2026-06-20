from fastapi import APIRouter, UploadFile, File, HTTPException
import logging

from app.services.wound_services import analyze_wound_image

logger = logging.getLogger(__name__)

router = APIRouter()

@router.post("/analyze")
async def analyze_wound(image: UploadFile = File(...)):
    try:
        return analyze_wound_image(await image.read())
    
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error")