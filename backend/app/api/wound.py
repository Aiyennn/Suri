from typing import List
from fastapi import APIRouter, UploadFile, File, Form, HTTPException
import json
import logging

from services.wound_services import analyze_wound_image

logger = logging.getLogger(__name__)

router = APIRouter()

@router.post("/analyze")
async def analyze_wound(
    age: str = Form(...),
    sex: str = Form(...),
    symptoms: str = Form(...),
    duration: str = Form(...),
    medical_history: str = Form(...),
    images: List[UploadFile] = File(...),
):
    try:
        symptoms_list = json.loads(symptoms)

        image_results = []
        for image in images:
            image_bytes = await image.read()
            result = analyze_wound_image(image_bytes)
            image_results.append(result)

        return {
            "patient": {
                "age": age,
                "sex": sex,
                "symptoms": symptoms_list,
                "duration": duration,
                "medical_history": medical_history,
            },
            "results": image_results,
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    except Exception:
        raise HTTPException(status_code=500, detail="Internal server error")