"""
tests/engine/test_followup.py
=============================
Unit tests for ``engine/followup.py``.
"""



from app.engine.evaluator import EvaluationResult
from app.engine.followup import FollowUpScheduler, _hours_to_label
from app.engine.schemas import RiskLevel

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_result(minimum_follow_up_hours: int | None = None) -> EvaluationResult:
    return EvaluationResult(
        matches=[],
        total_score=0,
        forces_referral=False,
        forces_emergency=False,
        minimum_follow_up_hours=minimum_follow_up_hours,
    )


# ---------------------------------------------------------------------------
# _hours_to_label
# ---------------------------------------------------------------------------

class TestHoursToLabel:
    def test_zero_is_immediate(self):
        assert _hours_to_label(0) == "Immediate"

    def test_sub_24_shows_hours(self):
        assert _hours_to_label(12) == "12 hours"

    def test_exactly_24_shows_1_day(self):
        assert _hours_to_label(24) == "1 day"

    def test_48_shows_2_days(self):
        assert _hours_to_label(48) == "2 days"

    def test_72_shows_3_days(self):
        assert _hours_to_label(72) == "3 days"


# ---------------------------------------------------------------------------
# FollowUpScheduler
# ---------------------------------------------------------------------------

class TestFollowUpScheduler:
    def setup_method(self):
        self.scheduler = FollowUpScheduler()

    def test_rule_minimum_takes_precedence_over_risk_level(self):
        result = _make_result(minimum_follow_up_hours=24)
        # Even if risk level is LOW (default 72h), rule override wins.
        assert self.scheduler.schedule(result, RiskLevel.LOW) == "1 day"

    def test_zero_hours_returns_immediate(self):
        result = _make_result(minimum_follow_up_hours=0)
        assert self.scheduler.schedule(result, RiskLevel.LOW) == "Immediate"

    def test_low_risk_default_is_72_hours(self):
        result = _make_result(minimum_follow_up_hours=None)
        assert self.scheduler.schedule(result, RiskLevel.LOW) == "3 days"

    def test_moderate_risk_default_is_48_hours(self):
        result = _make_result(minimum_follow_up_hours=None)
        assert self.scheduler.schedule(result, RiskLevel.MODERATE) == "2 days"

    def test_high_risk_default_is_24_hours(self):
        result = _make_result(minimum_follow_up_hours=None)
        assert self.scheduler.schedule(result, RiskLevel.HIGH) == "1 day"

    def test_critical_risk_default_is_immediate(self):
        result = _make_result(minimum_follow_up_hours=None)
        assert self.scheduler.schedule(result, RiskLevel.CRITICAL) == "Immediate"
