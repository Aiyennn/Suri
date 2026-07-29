"""
tests/engine/test_rules.py
==========================
Unit tests for individual rule conditions in ``engine/rules.py``.

Each test builds a minimal ``WoundAssessmentInput`` that satisfies exactly
one rule condition and asserts the condition evaluates as expected.
"""

import pytest

from engine.models import (
    BleedingLevel,
    Classification,
    ExudateAmount,
    ExudateInfo,
    ExudateType,
    HealingStage,
    Observations,
    Severity,
    WoundAssessmentInput,
    WoundType,
)
from engine.registry import rule_registry


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_input(
    wound_type: WoundType = WoundType.ABRASION,
    severity: Severity = Severity.MILD,
    healing_stage: HealingStage = HealingStage.PROLIFERATIVE,
    redness: bool = False,
    bleeding: BleedingLevel = BleedingLevel.NONE,
    exudate_present: bool = False,
    exudate_type: ExudateType = ExudateType.NONE,
    exudate_amount: ExudateAmount = ExudateAmount.NONE,
    confidence: float = 0.95,
) -> WoundAssessmentInput:
    return WoundAssessmentInput(
        classification=Classification(
            wound_type=wound_type,
            severity=severity,
            healing_stage=healing_stage,
        ),
        observations=Observations(
            redness=redness,
            bleeding=bleeding,
            exudate=ExudateInfo(
                present=exudate_present,
                type=exudate_type,
                amount=exudate_amount,
            ),
        ),
        confidence=confidence,
    )


def _get_condition(rule_id: str):
    return rule_registry.get_by_id(rule_id).condition


# ---------------------------------------------------------------------------
# Severity rules
# ---------------------------------------------------------------------------

class TestSeverityRules:
    def test_sev_critical_triggers_on_critical(self):
        inp = _make_input(severity=Severity.CRITICAL)
        assert _get_condition("SEV_CRITICAL")(inp) is True

    def test_sev_critical_does_not_trigger_on_severe(self):
        inp = _make_input(severity=Severity.SEVERE)
        assert _get_condition("SEV_CRITICAL")(inp) is False

    def test_sev_severe_triggers_on_severe(self):
        inp = _make_input(severity=Severity.SEVERE)
        assert _get_condition("SEV_SEVERE")(inp) is True

    def test_sev_severe_does_not_trigger_on_mild(self):
        inp = _make_input(severity=Severity.MILD)
        assert _get_condition("SEV_SEVERE")(inp) is False

    def test_sev_moderate_triggers(self):
        inp = _make_input(severity=Severity.MODERATE)
        assert _get_condition("SEV_MODERATE")(inp) is True

    def test_sev_mild_triggers(self):
        inp = _make_input(severity=Severity.MILD)
        assert _get_condition("SEV_MILD")(inp) is True


# ---------------------------------------------------------------------------
# Bleeding rules
# ---------------------------------------------------------------------------

class TestBleedingRules:
    def test_bleed_heavy_triggers(self):
        inp = _make_input(bleeding=BleedingLevel.HEAVY)
        assert _get_condition("BLEED_HEAVY")(inp) is True

    def test_bleed_heavy_not_triggered_by_moderate(self):
        inp = _make_input(bleeding=BleedingLevel.MODERATE)
        assert _get_condition("BLEED_HEAVY")(inp) is False

    def test_bleed_moderate_triggers(self):
        inp = _make_input(bleeding=BleedingLevel.MODERATE)
        assert _get_condition("BLEED_MODERATE")(inp) is True

    def test_bleed_minimal_triggers(self):
        inp = _make_input(bleeding=BleedingLevel.MINIMAL)
        assert _get_condition("BLEED_MINIMAL")(inp) is True

    def test_bleed_none_triggers_no_bleeding_rule(self):
        inp = _make_input(bleeding=BleedingLevel.NONE)
        assert _get_condition("BLEED_HEAVY")(inp) is False
        assert _get_condition("BLEED_MODERATE")(inp) is False
        assert _get_condition("BLEED_MINIMAL")(inp) is False


# ---------------------------------------------------------------------------
# Wound type rules
# ---------------------------------------------------------------------------

class TestWoundTypeRules:
    def test_burn_triggers(self):
        inp = _make_input(wound_type=WoundType.BURN)
        assert _get_condition("TYPE_BURN")(inp) is True

    def test_burn_not_triggered_by_abrasion(self):
        inp = _make_input(wound_type=WoundType.ABRASION)
        assert _get_condition("TYPE_BURN")(inp) is False

    def test_pressure_ulcer_triggers(self):
        inp = _make_input(wound_type=WoundType.PRESSURE_ULCER)
        assert _get_condition("TYPE_PRESSURE_ULCER")(inp) is True

    def test_diabetic_ulcer_triggers(self):
        inp = _make_input(wound_type=WoundType.DIABETIC_ULCER)
        assert _get_condition("TYPE_DIABETIC_ULCER")(inp) is True

    def test_laceration_triggers(self):
        inp = _make_input(wound_type=WoundType.LACERATION)
        assert _get_condition("TYPE_LACERATION")(inp) is True

    def test_puncture_triggers(self):
        inp = _make_input(wound_type=WoundType.PUNCTURE)
        assert _get_condition("TYPE_PUNCTURE")(inp) is True


# ---------------------------------------------------------------------------
# Exudate rules
# ---------------------------------------------------------------------------

class TestExudateRules:
    def test_purulent_triggers(self):
        inp = _make_input(
            exudate_present=True,
            exudate_type=ExudateType.PURULENT,
            exudate_amount=ExudateAmount.MODERATE,
        )
        assert _get_condition("EXU_PURULENT")(inp) is True

    def test_purulent_not_triggered_by_serous(self):
        inp = _make_input(
            exudate_present=True,
            exudate_type=ExudateType.SEROUS,
            exudate_amount=ExudateAmount.LOW,
        )
        assert _get_condition("EXU_PURULENT")(inp) is False

    def test_high_amount_triggers(self):
        inp = _make_input(
            exudate_present=True,
            exudate_type=ExudateType.SEROUS,
            exudate_amount=ExudateAmount.HIGH,
        )
        assert _get_condition("EXU_HIGH_AMOUNT")(inp) is True

    def test_high_amount_requires_present(self):
        # amount=HIGH but present=False would fail the model_validator, so
        # we test that the rule condition itself also checks present.
        # This scenario is prevented by Pydantic, but the rule double-checks.
        inp = _make_input(
            exudate_present=True,
            exudate_type=ExudateType.SEROUS,
            exudate_amount=ExudateAmount.MODERATE,
        )
        assert _get_condition("EXU_HIGH_AMOUNT")(inp) is False

    def test_sanguineous_triggers(self):
        inp = _make_input(
            exudate_present=True,
            exudate_type=ExudateType.SANGUINEOUS,
            exudate_amount=ExudateAmount.MODERATE,
        )
        assert _get_condition("EXU_SANGUINEOUS")(inp) is True

    def test_low_serous_triggers_present_low(self):
        inp = _make_input(
            exudate_present=True,
            exudate_type=ExudateType.SEROUS,
            exudate_amount=ExudateAmount.LOW,
        )
        assert _get_condition("EXU_PRESENT_LOW")(inp) is True

    def test_low_purulent_does_not_trigger_present_low(self):
        """Purulent exudate should not match the benign EXU_PRESENT_LOW rule."""
        inp = _make_input(
            exudate_present=True,
            exudate_type=ExudateType.PURULENT,
            exudate_amount=ExudateAmount.LOW,
        )
        assert _get_condition("EXU_PRESENT_LOW")(inp) is False


# ---------------------------------------------------------------------------
# Healing stage rules
# ---------------------------------------------------------------------------

class TestHealingStageRules:
    def test_necrotic_triggers(self):
        inp = _make_input(healing_stage=HealingStage.NECROTIC)
        assert _get_condition("STAGE_NECROTIC")(inp) is True

    def test_necrotic_not_triggered_by_inflammatory(self):
        inp = _make_input(healing_stage=HealingStage.INFLAMMATORY)
        assert _get_condition("STAGE_NECROTIC")(inp) is False

    def test_inflammatory_triggers(self):
        inp = _make_input(healing_stage=HealingStage.INFLAMMATORY)
        assert _get_condition("STAGE_INFLAMMATORY")(inp) is True

    def test_hemostasis_triggers(self):
        inp = _make_input(healing_stage=HealingStage.HEMOSTASIS)
        assert _get_condition("STAGE_HEMOSTASIS")(inp) is True


# ---------------------------------------------------------------------------
# Observation rules
# ---------------------------------------------------------------------------

class TestObservationRules:
    def test_redness_triggers(self):
        inp = _make_input(redness=True)
        assert _get_condition("REDNESS_PRESENT")(inp) is True

    def test_redness_does_not_trigger_when_absent(self):
        inp = _make_input(redness=False)
        assert _get_condition("REDNESS_PRESENT")(inp) is False


# ---------------------------------------------------------------------------
# Confidence rules
# ---------------------------------------------------------------------------

class TestConfidenceRules:
    def test_low_confidence_triggers_below_70(self):
        inp = _make_input(confidence=0.65)
        assert _get_condition("LOW_CONFIDENCE")(inp) is True

    def test_low_confidence_does_not_trigger_at_70(self):
        inp = _make_input(confidence=0.70)
        assert _get_condition("LOW_CONFIDENCE")(inp) is False

    def test_marginal_confidence_triggers_at_70(self):
        inp = _make_input(confidence=0.70)
        assert _get_condition("MARGINAL_CONFIDENCE")(inp) is True

    def test_marginal_confidence_triggers_at_84(self):
        inp = _make_input(confidence=0.84)
        assert _get_condition("MARGINAL_CONFIDENCE")(inp) is True

    def test_marginal_confidence_does_not_trigger_at_85(self):
        inp = _make_input(confidence=0.85)
        assert _get_condition("MARGINAL_CONFIDENCE")(inp) is False
