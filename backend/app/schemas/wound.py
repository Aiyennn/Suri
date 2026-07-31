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

import json
from typing import List, Literal
from pydantic import BaseModel, Field, field_validator
from fastapi import Form


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
    sex: Literal["male", "female", "other"] = Field(
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

    @field_validator("symptoms", mode="before")
    @classmethod
    def parse_symptoms(cls, v: object) -> object:
        """Accept a JSON-encoded string (from multipart form) or a plain list."""
        if isinstance(v, str):
            try:
                return json.loads(v)
            except json.JSONDecodeError:
                raise ValueError("symptoms must be a valid JSON list, e.g. '[\"redness\"]'")
        return v

class WoundAnalysisRequest(BaseModel):
    age: str
    sex: str
    symptoms: list[str]
    duration: str
    medical_history: str

    @classmethod
    def from_form(
        cls,
        age: str = Form(...),
        sex: str = Form(...),
        symptoms: str = Form(...),
        duration: str = Form(...),
        medical_history: str = Form(...),
    ):
        return cls(
            age=age,
            sex=sex,
            symptoms=json.loads(symptoms),
            duration=duration,
            medical_history=medical_history,
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


class TriggeredRule(BaseModel):
    """Compact record of one rule that fired during evaluation."""

    id: str = Field(description="Unique rule identifier.")
    name: str = Field(description="Human-readable rule name.")
    reason: str = Field(description="Plain-language explanation of why the rule fired.")
    score_contribution: int = Field(description="Points this rule added to the risk score.")


class WoundAnalysisResult(BaseModel):
    """
    Full deterministic output produced by the rule engine for a single image.

    Mirrors ``engine.models.AssessmentResult`` so that the API response
    accurately reflects what the engine computed.  Also includes the AI
    classification fields that were used as input to the rule engine.
    """

    # ── AI classification ─────────────────────────────────────────────────
    wound_type: str = Field(
        description="Wound morphology category from classification.",
        examples=["laceration"],
    )
    severity: str = Field(
        description="Clinician-interpretable severity tier.",
        examples=["moderate"],
    )
    healing_stage: str = Field(
        description="Current wound-healing phase.",
        examples=["inflammatory"],
    )
    confidence: float = Field(
        description="AI model confidence score in [0.0, 1.0].",
        examples=[0.87],
    )

    # ── Rule-engine output ────────────────────────────────────────────────
    risk_score: int = Field(description="Cumulative integer risk score.")
    risk_level: str = Field(
        description="Categorical risk tier: 'Low', 'Moderate', 'High', or 'Critical'.",
        examples=["Moderate"],
    )
    recommendations: List[str] = Field(
        description="Ordered, deduplicated action items for the clinician."
    )
    referral_required: bool = Field(
        description="Whether healthcare-provider referral is advised."
    )
    emergency: bool = Field(
        description="Whether an emergency response may be warranted."
    )
    follow_up: str = Field(
        description="Recommended follow-up timeframe.",
        examples=["Review in 48 hours"],
    )
    triggered_rules: List[TriggeredRule] = Field(
        description="All rules that matched and contributed to this assessment."
    )
    disclaimer: str = Field(
        description="Mandatory clinical-safety disclaimer."
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
        description="Rule-engine assessment for this image.",
    )


# ---------------------------------------------------------------------------
# Top-level response schema
# ---------------------------------------------------------------------------

class WoundAnalysisResponse(BaseModel):
    """
    Complete response body for POST /wound/analyze.

    Contains the assessment ID for future reference, the echoed patient
    information, and one analysis result per uploaded image.
    """

    assessment_id: str = Field(
        ...,
        description="UUID of the persisted assessment session.",
    )
    patient: PatientInfo = Field(
        ...,
        description="Patient demographics and clinical context as submitted.",
    )
    results: List[WoundAnalysisResult] = Field(
        ...,
        description=(
            "List of rule-engine assessment results, one per uploaded image, "
            "in the same order as the submitted files."
        ),
    )

# ---------------------------------------------------------------------------
# Assessment history schemas
# ---------------------------------------------------------------------------

class AssessmentSummary(BaseModel):
    """
    Lightweight summary of one past assessment session, used for list views.
    """

    id: str = Field(description="UUID of the assessment session.")
    created_at: str = Field(description="ISO-8601 timestamp when the assessment was created.")
    patient_age: str = Field(description="Patient age as stored.")
    patient_sex: str = Field(description="Patient biological sex.")
    symptoms: List[str] = Field(description="List of reported symptoms.")
    duration: str = Field(description="Wound duration string.")

    # Summary of the first image's analysis result (if any)
    risk_level: str | None = Field(None, description="Risk level from the first image's analysis.")
    risk_score: int | None = Field(None, description="Risk score from the first image's analysis.")
    wound_type: str | None = Field(None, description="Wound type from the first image's analysis.")
    emergency: bool | None = Field(None, description="Emergency flag from the first image's analysis.")
    image_count: int = Field(0, description="Number of images uploaded in this session.")


class AssessmentListResponse(BaseModel):
    """Paginated list of past assessment summaries."""

    total: int = Field(description="Total number of assessments on record.")
    assessments: List[AssessmentSummary] = Field(description="Ordered list of assessment summaries (newest first).")
