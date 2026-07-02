"""
engine/referrals.py
===================
Referral determination logic.

A referral to a healthcare provider is recommended when:

1. **Forced flag** — at least one triggered rule sets ``forces_referral=True``, OR
2. **Risk threshold** — the computed risk level is ``Moderate``, ``High``,
   or ``Critical``.

This module encapsulates that logic so it can be tested and extended
independently of the evaluator and scoring components.
"""

from __future__ import annotations

from engine.evaluator import EvaluationResult
from engine.models import RiskLevel


class ReferralEngine:
    """
    Determines whether a referral to a healthcare provider is required.

    A referral is always conservative: it fires on ``forces_referral``
    *or* risk level ≥ Moderate.  It is never suppressed by a single rule.
    """

    #: Risk levels at or above which a referral is automatically recommended.
    REFERRAL_THRESHOLD: frozenset[RiskLevel] = frozenset({
        RiskLevel.MODERATE,
        RiskLevel.HIGH,
        RiskLevel.CRITICAL,
    })

    def requires_referral(
        self,
        evaluation_result: EvaluationResult,
        risk_level: RiskLevel,
    ) -> bool:
        """
        Return ``True`` if a referral is warranted.

        Parameters
        ----------
        evaluation_result:
            Aggregate evaluation output including ``forces_referral``.
        risk_level:
            Computed :class:`RiskLevel` for this assessment.

        Returns
        -------
        bool
        """
        if evaluation_result.forces_referral:
            return True
        return risk_level in self.REFERRAL_THRESHOLD
