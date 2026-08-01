"""
tests/engine/test_models.py
===========================
Unit tests for ``engine/models.py``.

Covers schema validation, enum constraints, and the exudate
consistency cross-validator.
"""

import pytest
from pydantic import ValidationError

from app.engine.models import (
    AssessmentResult,
    ExudateAmount,
    ExudateInfo,
    ExudateType,
    RiskLevel,
    TriggeredRule,
    WoundAssessmentInput,
    WoundType,
)

# ---------------------------------------------------------------------------
# ExudateInfo
# ---------------------------------------------------------------------------

class TestExudateInfo:
    def test_valid_present_with_type_and_amount(self):
        e = ExudateInfo(present=True, type=ExudateType.SEROUS, amount=ExudateAmount.LOW)
        assert e.present is True
        assert e.type == ExudateType.SEROUS
        assert e.amount == ExudateAmount.LOW

    def test_valid_absent_none_type_and_amount(self):
        e = ExudateInfo(present=False, type=ExudateType.NONE, amount=ExudateAmount.NONE)
        assert e.present is False

    def test_absent_with_non_none_type_raises(self):
        with pytest.raises(ValidationError):
            ExudateInfo(present=False, type=ExudateType.SEROUS, amount=ExudateAmount.NONE)

    def test_absent_with_non_none_amount_raises(self):
        with pytest.raises(ValidationError):
            ExudateInfo(present=False, type=ExudateType.NONE, amount=ExudateAmount.LOW)

    def test_invalid_type_string_raises(self):
        with pytest.raises(ValidationError):
            ExudateInfo(present=True, type="unknown_type", amount=ExudateAmount.LOW)

    def test_invalid_amount_string_raises(self):
        with pytest.raises(ValidationError):
            ExudateInfo(present=True, type=ExudateType.SEROUS, amount="a_lot")


# ---------------------------------------------------------------------------
# WoundAssessmentInput
# ---------------------------------------------------------------------------

class TestWoundAssessmentInput:
    def _make_input(self, **overrides) -> dict:
        base = {
            "classification": {
                "wound_type": "abrasion",
                "severity": "moderate",
                "healing_stage": "inflammatory",
            },
            "observations": {
                "redness": True,
                "bleeding": "minimal",
                "exudate": {
                    "present": True,
                    "type": "serous",
                    "amount": "low",
                },
            },
            "confidence": 0.94,
        }
        base.update(overrides)
        return base

    def test_valid_full_input(self):
        data = self._make_input()
        obj = WoundAssessmentInput.model_validate(data)
        assert obj.classification.wound_type == WoundType.ABRASION
        assert obj.confidence == 0.94

    def test_confidence_below_zero_raises(self):
        with pytest.raises(ValidationError):
            WoundAssessmentInput.model_validate(self._make_input(confidence=-0.1))

    def test_confidence_above_one_raises(self):
        with pytest.raises(ValidationError):
            WoundAssessmentInput.model_validate(self._make_input(confidence=1.01))

    def test_invalid_severity_raises(self):
        data = self._make_input()
        data["classification"]["severity"] = "catastrophic"
        with pytest.raises(ValidationError):
            WoundAssessmentInput.model_validate(data)

    def test_invalid_wound_type_raises(self):
        data = self._make_input()
        data["classification"]["wound_type"] = "gunshot"
        with pytest.raises(ValidationError):
            WoundAssessmentInput.model_validate(data)

    def test_invalid_bleeding_level_raises(self):
        data = self._make_input()
        data["observations"]["bleeding"] = "torrential"
        with pytest.raises(ValidationError):
            WoundAssessmentInput.model_validate(data)

    def test_missing_classification_raises(self):
        data = self._make_input()
        del data["classification"]
        with pytest.raises(ValidationError):
            WoundAssessmentInput.model_validate(data)


# ---------------------------------------------------------------------------
# AssessmentResult
# ---------------------------------------------------------------------------

class TestAssessmentResult:
    def test_default_disclaimer_present(self):
        result = AssessmentResult(
            risk_score=3,
            risk_level=RiskLevel.LOW,
            recommendations=["Keep clean."],
            referral_required=False,
            emergency=False,
            follow_up="72 hours",
            triggered_rules=[],
        )
        assert "clinical" in result.disclaimer.lower()

    def test_triggered_rule_fields(self):
        rule = TriggeredRule(
            id="TEST_RULE",
            name="Test",
            reason="For testing.",
            score_contribution=2,
        )
        assert rule.id == "TEST_RULE"
        assert rule.score_contribution == 2
