"""
engine/followup.py
==================
Follow-up timing scheduler.

Follow-up timing is determined by taking the minimum ``follow_up_hours``
across all triggered rules that specified one, then falling back to a
risk-level default if no rule set a constraint.

Default timing bands
--------------------
| Risk level | Default follow-up |
|------------|-------------------|
| Low        | 72 hours          |
| Moderate   | 48 hours          |
| High       | 24 hours          |
| Critical   | Immediate         |
"""

from __future__ import annotations

from .evaluator import EvaluationResult
from .models import RiskLevel

# ---------------------------------------------------------------------------
# Risk-level defaults (hours; 0 means "Immediate")
# ---------------------------------------------------------------------------

_RISK_LEVEL_DEFAULTS: dict[RiskLevel, int | None] = {
    RiskLevel.LOW:      72,
    RiskLevel.MODERATE: 48,
    RiskLevel.HIGH:     24,
    RiskLevel.CRITICAL: 0,   # Immediate
}


def _hours_to_label(hours: int) -> str:
    """Convert an integer hour value to a human-readable follow-up string."""
    if hours == 0:
        return "Immediate"
    if hours < 24:
        return f"{hours} hours"
    days = hours // 24
    return f"{days} day{'s' if days != 1 else ''}"


class FollowUpScheduler:
    """
    Resolves the recommended follow-up timing for an assessment.

    Resolution order
    ----------------
    1. Minimum ``follow_up_hours`` from triggered rules (most urgent wins).
    2. Risk-level default from ``_RISK_LEVEL_DEFAULTS``.
    3. ``"72 hours"`` as a safe catch-all if neither applies.
    """

    def schedule(
        self,
        evaluation_result: EvaluationResult,
        risk_level: RiskLevel,
    ) -> str:
        """
        Return a human-readable follow-up recommendation.

        Parameters
        ----------
        evaluation_result:
            Aggregate result containing ``minimum_follow_up_hours``.
        risk_level:
            Computed :class:`RiskLevel` for this assessment.

        Returns
        -------
        str
            A plain-language follow-up timeframe, e.g. ``"24 hours"`` or
            ``"Immediate"``.
        """
        # Rule-driven minimum takes precedence.
        if evaluation_result.minimum_follow_up_hours is not None:
            return _hours_to_label(evaluation_result.minimum_follow_up_hours)

        # Fall back to risk-level default.
        default_hours = _RISK_LEVEL_DEFAULTS.get(risk_level)
        if default_hours is not None:
            return _hours_to_label(default_hours)

        # Catch-all — should never be reached.
        return "72 hours"
