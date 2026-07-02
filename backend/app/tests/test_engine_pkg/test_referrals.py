"""
tests/engine/test_referrals.py
==============================
Unit tests for ``engine/referrals.py``.
"""

import pytest
from dataclasses import dataclass, field
from typing import Optional

from engine.evaluator import EvaluationResult, RuleMatch
from engine.models import RiskLevel
from engine.referrals import ReferralEngine


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_result(
    forces_referral: bool = False,
    forces_emergency: bool = False,
    total_score: int = 0,
    minimum_follow_up_hours: Optional[int] = None,
) -> EvaluationResult:
    return EvaluationResult(
        matches=[],
        total_score=total_score,
        forces_referral=forces_referral,
        forces_emergency=forces_emergency,
        minimum_follow_up_hours=minimum_follow_up_hours,
    )


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

class TestReferralEngine:
    def setup_method(self):
        self.engine = ReferralEngine()

    def test_forced_referral_returns_true_regardless_of_level(self):
        result = _make_result(forces_referral=True)
        assert self.engine.requires_referral(result, RiskLevel.LOW) is True

    def test_low_risk_no_force_returns_false(self):
        result = _make_result(forces_referral=False)
        assert self.engine.requires_referral(result, RiskLevel.LOW) is False

    def test_moderate_risk_triggers_referral(self):
        result = _make_result(forces_referral=False)
        assert self.engine.requires_referral(result, RiskLevel.MODERATE) is True

    def test_high_risk_triggers_referral(self):
        result = _make_result(forces_referral=False)
        assert self.engine.requires_referral(result, RiskLevel.HIGH) is True

    def test_critical_risk_triggers_referral(self):
        result = _make_result(forces_referral=False)
        assert self.engine.requires_referral(result, RiskLevel.CRITICAL) is True
