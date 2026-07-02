"""
api/wound.py
============
FastAPI router for wound-analysis endpoints.

All routes in this module are mounted under the ``/wound`` prefix by
``main.py``, so the full paths are:

    POST /wound/analyze   – Submit patient info + wound images for analysis.

Request format:
    multipart/form-data with the following fields:
        age            (str)  – Patient age.
        sex            (str)  – Patient biological sex.
        symptoms       (str)  – JSON-encoded list of symptom strings.
        duration       (str)  – How long the wound has been present.
        medical_history(str)  – Relevant medical background.
        images         (file[])– One or more wound images (JPEG/PNG).

Response shape (see schemas/wound.py for the full Pydantic models):
    {
        "patient": { age, sex, symptoms, duration, medical_history },
        "results": [{ "risk": "low|medium|high", "confidence": 0.0–1.0 }, ...]
    }
"""

from typing import List

from fastapi import APIRouter, UploadFile, File, Form, HTTPException
import json
import logging

from services.wound_services import analyze_wound_image

logger = logging.getLogger(__name__)

# All routes defined here are registered on this router object.
# ``main.py`` mounts it at the /wound prefix.
router = APIRouter()


@router.post(
    "/analyze",
    summary="Analyse wound images",
    description=(
        "Submit patient demographics and one or more wound photographs. "
        "Each image is validated for quality (blur, brightness, contrast) "
        "and then passed through the wound-risk AI model. "
        "Returns the patient context and a risk result per image."
    ),
)
async def analyze_wound(
    age: str = Form(..., description="Patient age, e.g. '34'."),
    sex: str = Form(..., description="Patient biological sex: 'male', 'female', or 'other'."),
    symptoms: str = Form(..., description="JSON-encoded list of symptom strings, e.g. '[\"redness\",\"swelling\"]'."),
    duration: str = Form(..., description="Duration the wound has been present, e.g. '3 days'."),
    medical_history: str = Form(..., description="Relevant past medical conditions or medications."),
    images: List[UploadFile] = File(..., description="One or more wound images (JPEG or PNG)."),
):
    """
    Analyse one or more wound images alongside patient context.

    Processing pipeline per image:
        1. Read raw bytes from the uploaded file.
        2. Decode the image and compute quality metrics (blur, brightness, contrast).
        3. Reject the request with HTTP 400 if any image fails the quality gate.
        4. Pass the decoded image to the AI model for risk prediction.

    Args:
        age:             Patient age string.
        sex:             Patient biological sex.
        symptoms:        JSON-encoded list of symptom strings.
        duration:        How long the wound has been present.
        medical_history: Relevant medical background.
        images:          Uploaded image files.

    Returns:
        dict: ``{"patient": {...}, "results": [{risk, confidence}, ...]}``

    Raises:
        HTTPException 400: If ``symptoms`` is not valid JSON, or if any image
                           fails the quality check (too blurry / over-/under-exposed).
        HTTPException 500: For any unexpected server-side error.
    """
    try:
        # ``symptoms`` arrives as a raw JSON string from the form payload.
        # Parse it here so the rest of the pipeline works with a plain list.
        symptoms_list = json.loads(symptoms)

        # Process each uploaded image independently so the caller receives
        # a per-image result (useful when multiple angles are submitted).
        image_results = []
        for image in images:
            # Read the entire file into memory as raw bytes.
            image_bytes = await image.read()

            # Decode, quality-check, and run AI inference.
            # Raises ValueError if the image does not meet quality thresholds.
            result = analyze_wound_image(image_bytes)
            image_results.append(result)

        # Return the echoed patient context alongside the per-image results.
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
        # Raised by json.loads (malformed symptoms) or by the quality checker
        # (image quality too low).  Surfaces a clear 400 to the caller.
        raise HTTPException(status_code=400, detail=str(e))

    except Exception:
        # Catch-all for unexpected errors (e.g. corrupt image, model crash).
        # Log internally but return a generic 500 to avoid leaking internals.
        logger.exception("Unexpected error in analyze_wound endpoint")
        raise HTTPException(status_code=500, detail="Internal server error")