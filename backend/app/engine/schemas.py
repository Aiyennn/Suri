"""
engine/schemas.py
=================
Pydantic v2 data models for the wound-assessment rule engine.

All categorical input fields are validated against strict ``Enum`` types so
that invalid values are rejected at the boundary before any rule evaluates
them.  Output models are kept separate to make the contract between the engine
and its callers explicit.
"""

from __future__ import annotations

from enum import Enum

from pydantic import BaseModel, Field, model_validator

# ---------------------------------------------------------------------------
# Enumerations
# ---------------------------------------------------------------------------

class WoundType(str, Enum):
    ABRASION = "abrasion"
    LACERATION = "laceration"
    BURN = "burn"
    PRESSURE_ULCER = "pressure_ulcer"
    DIABETIC_ULCER = "diabetic_ulcer"
    SURGICAL = "surgical"
    CONTUSION = "contusion"
    PUNCTURE = "puncture"


class Severity(str, Enum):
    MILD = "mild"
    MODERATE = "moderate"
    SEVERE = "severe"
    CRITICAL = "critical"


class HealingStage(str, Enum):
    HEMOSTASIS = "hemostasis"
    INFLAMMATORY = "inflammatory"
    PROLIFERATIVE = "proliferative"
    MATURATION = "maturation"
    NECROTIC = "necrotic"


class BleedingLevel(str, Enum):
    NONE = "none"
    MINIMAL = "minimal"
    MODERATE = "moderate"
    HEAVY = "heavy"


class ExudateType(str, Enum):
    NONE = "none"
    SEROUS = "serous"
    SANGUINEOUS = "sanguineous"
    SEROSANGUINEOUS = "serosanguineous"
    PURULENT = "purulent"


class ExudateAmount(str, Enum):
    NONE = "none"
    LOW = "low"
    MODERATE = "moderate"
    HIGH = "high"


class RiskLevel(str, Enum):
    LOW = "Low"
    MODERATE = "Moderate"
    HIGH = "High"
    CRITICAL = "Critical"


class WoundDuration(str, Enum):
    """How long the wound has been present (matches frontend options)."""

    LESS_THAN_24H = "< 24h"
    ONE_TO_THREE_DAYS = "1-3 Days"
    ONE_WEEK = "1 Week"
    MORE_THAN_ONE_WEEK = "> 1 Week"


# ---------------------------------------------------------------------------
# Input models
# ---------------------------------------------------------------------------

class ExudateInfo(BaseModel):
    """Structured description of wound exudate."""

    present: bool = Field(description="Whether exudate is present.")
    type: ExudateType = Field(default=ExudateType.NONE, description="Exudate composition.")
    amount: ExudateAmount = Field(default=ExudateAmount.NONE, description="Approximate exudate volume.")

    @model_validator(mode="after")
    def validate_consistency(self) -> ExudateInfo:
        """Ensure type/amount are NONE when exudate is absent."""
        if not self.present:
            if self.type != ExudateType.NONE:
                raise ValueError("Exudate type must be 'none' when present=False.")
            if self.amount != ExudateAmount.NONE:
                raise ValueError("Exudate amount must be 'none' when present=False.")
        return self


class Observations(BaseModel):
    """Directly observable wound characteristics."""

    redness: bool = Field(description="Perilesional erythema present.")
    bleeding: BleedingLevel = Field(
        default=BleedingLevel.NONE, description="Active bleeding intensity."
    )
    exudate: ExudateInfo = Field(description="Exudate characterisation.")


class Classification(BaseModel):
    """AI model wound classification output."""

    wound_type: WoundType = Field(description="Wound morphology category.")
    severity: Severity = Field(description="Clinician-interpretable severity tier.")
    healing_stage: HealingStage = Field(description="Current wound-healing phase.")


class WoundAssessmentInput(BaseModel):
    """
    Complete structured input for the rule engine.

    Combines the AI vision model's output (classification, observations,
    confidence) with optional patient-supplied context (duration).
    """

    classification: Classification
    observations: Observations
    confidence: float = Field(
        ge=0.0, le=1.0, description="Model confidence in [0, 1]."
    )
    duration: WoundDuration | None = Field(
        default=None,
        description="How long the wound has been present (patient-reported).",
    )


# ---------------------------------------------------------------------------
# Output models
# ---------------------------------------------------------------------------

class TriggeredRule(BaseModel):
    """Compact record of one rule that fired during evaluation."""

    id: str = Field(description="Unique rule identifier.")
    name: str = Field(description="Human-readable rule name.")
    reason: str = Field(description="Plain-language explanation of why the rule fired.")
    score_contribution: int = Field(description="Points this rule added to the risk score.")


class AssessmentResult(BaseModel):
    """
    Full deterministic output produced by the rule engine.

    Every field is derived solely from the rule definitions and the input;
    no randomness or external state is involved.
    """

    risk_score: int = Field(description="Cumulative integer risk score.")
    risk_level: RiskLevel = Field(description="Categorical risk tier.")
    recommendations: list[str] = Field(description="Ordered, deduplicated action items.")
    referral_required: bool = Field(description="Whether healthcare-provider referral is advised.")
    emergency: bool = Field(description="Whether an emergency response may be warranted.")
    follow_up: str = Field(description="Recommended follow-up timeframe.")
    triggered_rules: list[TriggeredRule] = Field(
        description="All rules that matched and contributed to this assessment."
    )
    disclaimer: str = Field(
        description="Mandatory clinical-safety disclaimer.",
        default=(
            "This assessment is generated by a deterministic rule engine to support "
            "clinical decision-making. It does not constitute a medical diagnosis or "
            "replace the judgment of a licensed healthcare professional."
        ),
    )
