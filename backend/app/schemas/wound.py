"""
schemas/wound.py
================
Pydantic data-transfer objects (DTOs) for the Suri wound-analysis API.

These schemas define:
  - The shape of validated request data (after FastAPI form-parsing)
  - The structure of every response body returned by the /wound/* endpoints

Using explicit schemas keeps the API contract predictable and enables
automatic OpenAPI documentation via FastAPI.
"""

from __future__ import annotations

from typing import List, Literal
from pydantic import BaseModel, Field


# ---------------------------------------------------------------------------
# Request schemas
# ---------------------------------------------------------------------------

class PatientInfo(BaseModel):
    """Demographic and clinical information supplied by the clinician."""

    age: str = Field(
        ...,
        description="Patient age, e.g. '34' or '34 years'.",
        examples=["34"],
    )
    sex: str = Field(
        ...,
        description="Patient biological sex: 'male', 'female', or 'other'.",
        examples=["female"],
    )
    symptoms: List[str] = Field(
        ...,
        description="Free-text list of observed symptoms reported by the patient.",
        examples=[["redness", "swelling", "discharge"]],
    )
    duration: str = Field(
        ...,
        description="How long the wound has been present, e.g. '3 days'.",
        examples=["3 days"],
    )
    medical_history: str = Field(
        ...,
        description="Relevant past medical conditions, allergies, or medications.",
        examples=["Type 2 diabetes, penicillin allergy"],
    )


# ---------------------------------------------------------------------------
# Nested response schemas
# ---------------------------------------------------------------------------

class ImageQualityMetrics(BaseModel):
    """
    Low-level pixel-based quality metrics computed for a single image.

    These values are derived by the image-quality service before the image
    is forwarded to the AI model.  They are included in the response so the
    caller can surface actionable feedback (e.g. 'image too blurry') to the
    end user.
    """

    blur: float = Field(
        ...,
        description=(
            "Laplacian variance of the grayscale image.  "
            "Values below 100 are considered too blurry for reliable analysis."
        ),
        examples=[142.7],
    )
    brightness: float = Field(
        ...,
        description=(
            "Mean pixel intensity of the grayscale image (0-255).  "
            "Values below 40 indicate an image that is too dark; "
            "values above 220 indicate overexposure."
        ),
        examples=[128.3],
    )
    contrast: float = Field(
        ...,
        description=(
            "Standard deviation of pixel intensities in the grayscale image.  "
            "Values below 15 indicate insufficient contrast for analysis."
        ),
        examples=[45.1],
    )


class ImageQualityAssessment(BaseModel):
    """
    Overall quality verdict and raw metrics for one uploaded image.

    ``is_valid`` is ``True`` only when the image passes all three quality
    checks (blur, brightness, contrast).  The API rejects the entire request
    if any image fails this check.
    """

    is_valid: bool = Field(
        ...,
        description=(
            "True if the image meets the minimum quality thresholds "
            "required for AI analysis."
        ),
    )
    metrics: ImageQualityMetrics = Field(
        ...,
        description="Raw quality metrics used to compute is_valid.",
    )


class WoundAnalysisResult(BaseModel):
    """
    AI model output for a single wound image.

    The model currently returns a categorical risk level and an associated
    confidence score.  Additional fields (e.g. wound classification, size
    estimate) will be added here as the model matures.
    """

    risk: Literal["low", "medium", "high"] = Field(
        ...,
        description=(
            "Predicted risk level of the wound.  "
            "'high' should prompt immediate clinical escalation."
        ),
        examples=["medium"],
    )
    confidence: float = Field(
        ...,
        ge=0.0,
        le=1.0,
        description=(
            "Model confidence in the risk prediction, expressed as a "
            "probability between 0.0 and 1.0."
        ),
        examples=[0.87],
    )


class ImageAnalysisResult(BaseModel):
    """
    Combined result for one uploaded image: quality assessment + AI analysis.

    The API processes images individually, so a multi-image upload will
    produce a list of these objects, one per image, in submission order.
    """

    quality: ImageQualityAssessment = Field(
        ...,
        description="Image quality assessment for this image.",
    )
    analysis: WoundAnalysisResult = Field(
        ...,
        description="AI model prediction for this image.",
    )


# ---------------------------------------------------------------------------
# Top-level response schema
# ---------------------------------------------------------------------------

class WoundAnalysisResponse(BaseModel):
    """
    Complete response body for POST /wound/analyze.

    Contains the echoed patient information and one analysis result per
    uploaded image.
    """

    patient: PatientInfo = Field(
        ...,
        description="Patient demographics and clinical context as submitted.",
    )
    results: List[WoundAnalysisResult] = Field(
        ...,
        description=(
            "List of AI analysis results, one per uploaded image, "
            "in the same order as the submitted files."
        ),
    )
