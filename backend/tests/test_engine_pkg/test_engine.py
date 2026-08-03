"""
tests/engine/test_engine.py
===========================
Integration tests for ``engine/engine.py`` — the full assessment pipeline.

These tests exercise the complete pipeline end-to-end using the production
rule registry. They verify:

* Correct output shape and types
* Determinism (identical inputs → identical outputs)
* Known scenario outcomes (e.g. heavy bleeding → emergency=True)
* Schema validation is enforced at entry
* Triggered rules appear in output
"""

import copy
import json

import pytest

from app.engine.engine import WoundAssessmentEngine
from app.engine.schemas import RiskLevel
from app.engine.validation import InputValidationError

# ---------------------------------------------------------------------------
# Fixture: engine instance
# ---------------------------------------------------------------------------

@pytest.fixture(scope="module")
def engine() -> WoundAssessmentEngine:
    return WoundAssessmentEngine()


# ---------------------------------------------------------------------------
# Example inputs
# ---------------------------------------------------------------------------

MODERATE_ABRASION = {
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

EMERGENCY_SCENARIO = {
    "classification": {
        "wound_type": "laceration",
        "severity": "critical",
        "healing_stage": "hemostasis",
    },
    "observations": {
        "redness": True,
        "bleeding": "heavy",
        "exudate": {
            "present": True,
            "type": "sanguineous",
            "amount": "high",
        },
    },
    "confidence": 0.91,
}

LOW_RISK_SCENARIO = {
    "classification": {
        "wound_type": "abrasion",
        "severity": "mild",
        "healing_stage": "proliferative",
    },
    "observations": {
        "redness": False,
        "bleeding": "none",
        "exudate": {
            "present": False,
            "type": "none",
            "amount": "none",
        },
    },
    "confidence": 0.92,
}

DIABETIC_ULCER_SCENARIO = {
    "classification": {
        "wound_type": "diabetic_ulcer",
        "severity": "moderate",
        "healing_stage": "inflammatory",
    },
    "observations": {
        "redness": True,
        "bleeding": "none",
        "exudate": {
            "present": True,
            "type": "purulent",
            "amount": "moderate",
        },
    },
    "confidence": 0.88,
}


# ---------------------------------------------------------------------------
# Output shape tests
# ---------------------------------------------------------------------------

class TestOutputShape:
    def test_result_has_all_required_fields(self, engine):
        result = engine.assess(MODERATE_ABRASION)
        assert hasattr(result, "risk_score")
        assert hasattr(result, "risk_level")
        assert hasattr(result, "recommendations")
        assert hasattr(result, "referral_required")
        assert hasattr(result, "emergency")
        assert hasattr(result, "follow_up")
        assert hasattr(result, "triggered_rules")
        assert hasattr(result, "disclaimer")

    def test_recommendations_is_list_of_strings(self, engine):
        result = engine.assess(MODERATE_ABRASION)
        assert isinstance(result.recommendations, list)
        assert all(isinstance(r, str) for r in result.recommendations)

    def test_triggered_rules_have_id_name_reason_score(self, engine):
        result = engine.assess(MODERATE_ABRASION)
        for rule in result.triggered_rules:
            assert rule.id
            assert rule.name
            assert rule.reason
            assert isinstance(rule.score_contribution, int)

    def test_risk_score_is_non_negative(self, engine):
        result = engine.assess(MODERATE_ABRASION)
        assert result.risk_score >= 0

    def test_risk_level_is_valid_enum_value(self, engine):
        result = engine.assess(MODERATE_ABRASION)
        assert result.risk_level in list(RiskLevel)

    def test_disclaimer_is_present_and_non_empty(self, engine):
        result = engine.assess(MODERATE_ABRASION)
        assert result.disclaimer
        assert len(result.disclaimer) > 20


# ---------------------------------------------------------------------------
# Determinism tests
# ---------------------------------------------------------------------------

class TestDeterminism:
    def test_identical_inputs_produce_identical_outputs(self, engine):
        r1 = engine.assess(copy.deepcopy(MODERATE_ABRASION))
        r2 = engine.assess(copy.deepcopy(MODERATE_ABRASION))
        assert r1.model_dump() == r2.model_dump()

    def test_output_serialises_to_json_deterministically(self, engine):
        r1 = json.dumps(engine.assess(MODERATE_ABRASION).model_dump(), sort_keys=True)
        r2 = json.dumps(engine.assess(MODERATE_ABRASION).model_dump(), sort_keys=True)
        assert r1 == r2


# ---------------------------------------------------------------------------
# Scenario-specific outcome tests
# ---------------------------------------------------------------------------

class TestScenarioOutcomes:
    def test_emergency_scenario_sets_emergency_true(self, engine):
        result = engine.assess(EMERGENCY_SCENARIO)
        assert result.emergency is True

    def test_emergency_scenario_sets_referral_true(self, engine):
        result = engine.assess(EMERGENCY_SCENARIO)
        assert result.referral_required is True

    def test_emergency_scenario_sets_immediate_follow_up(self, engine):
        result = engine.assess(EMERGENCY_SCENARIO)
        assert result.follow_up == "Immediate"

    def test_emergency_scenario_risk_level_is_critical_or_high(self, engine):
        result = engine.assess(EMERGENCY_SCENARIO)
        assert result.risk_level in (RiskLevel.CRITICAL, RiskLevel.HIGH)

    def test_low_risk_scenario_emergency_is_false(self, engine):
        result = engine.assess(LOW_RISK_SCENARIO)
        assert result.emergency is False

    def test_low_risk_scenario_risk_level_is_low(self, engine):
        result = engine.assess(LOW_RISK_SCENARIO)
        assert result.risk_level == RiskLevel.LOW

    def test_low_risk_scenario_follow_up_is_3_days(self, engine):
        result = engine.assess(LOW_RISK_SCENARIO)
        assert result.follow_up == "3 days"

    def test_diabetic_ulcer_requires_referral(self, engine):
        result = engine.assess(DIABETIC_ULCER_SCENARIO)
        assert result.referral_required is True

    def test_diabetic_ulcer_purulent_triggers_infection_rule(self, engine):
        result = engine.assess(DIABETIC_ULCER_SCENARIO)
        triggered_ids = {r.id for r in result.triggered_rules}
        assert "EXU_PURULENT" in triggered_ids

    def test_diabetic_ulcer_triggers_type_rule(self, engine):
        result = engine.assess(DIABETIC_ULCER_SCENARIO)
        triggered_ids = {r.id for r in result.triggered_rules}
        assert "TYPE_DIABETIC_ULCER" in triggered_ids


# ---------------------------------------------------------------------------
# Validation tests
# ---------------------------------------------------------------------------

class TestValidation:
    def test_invalid_severity_raises_input_validation_error(self, engine):
        bad = copy.deepcopy(MODERATE_ABRASION)
        bad["classification"]["severity"] = "catastrophic"
        with pytest.raises(InputValidationError):
            engine.assess(bad)

    def test_missing_confidence_raises_input_validation_error(self, engine):
        bad = copy.deepcopy(MODERATE_ABRASION)
        del bad["confidence"]
        with pytest.raises(InputValidationError):
            engine.assess(bad)

    def test_empty_dict_raises_input_validation_error(self, engine):
        with pytest.raises(InputValidationError):
            engine.assess({})

    def test_validation_error_contains_field_details(self, engine):
        bad = copy.deepcopy(MODERATE_ABRASION)
        bad["confidence"] = 2.5
        with pytest.raises(InputValidationError) as exc_info:
            engine.assess(bad)
        assert exc_info.value.errors


# ---------------------------------------------------------------------------
# Recommendations
# ---------------------------------------------------------------------------

class TestRecommendations:
    def test_recommendations_are_deduplicated(self, engine):
        result = engine.assess(MODERATE_ABRASION)
        # No recommendation text should appear more than once.
        assert len(result.recommendations) == len(set(result.recommendations))

    def test_safety_footer_always_present(self, engine):
        result = engine.assess(LOW_RISK_SCENARIO)
        footer_keywords = ["clinical", "judgment", "healthcare"]
        combined = " ".join(result.recommendations).lower()
        assert any(kw in combined for kw in footer_keywords)
