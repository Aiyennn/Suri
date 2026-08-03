"""
tests/engine/test_referrals.py
==============================
Unit tests for ``engine/referrals.py``.
"""



from app.engine.evaluator import EvaluationResult
from app.engine.schemas import RiskLevel
from app.engine.referrals import ReferralChecker

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_result(
    forces_referral: bool = False,
    forces_emergency: bool = False,
    total_score: int = 0,
    minimum_follow_up_hours: int | None = None,
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

class TestReferralChecker:
    def setup_method(self):
        self.engine = ReferralChecker()

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
