"""
engine/scoring.py
=================
Risk scoring and level classification.

This module translates a raw integer risk score produced by the evaluator
into a human-interpretable ``RiskLevel`` category.

Score thresholds
----------------
| Score range | Risk level |
|-------------|------------|
| 0 – 3       | Low        |
| 4 – 7       | Moderate   |
| 8 – 12      | High       |
| 13+         | Critical   |

These bands are defined as module-level constants so they can be adjusted
or overridden in tests without instantiating a custom class.
"""

from __future__ import annotations

from engine.models import RiskLevel

# ---------------------------------------------------------------------------
# Threshold constants (inclusive lower bounds, ascending order)
# ---------------------------------------------------------------------------

SCORE_THRESHOLDS: list[tuple[int, RiskLevel]] = [
    (13, RiskLevel.CRITICAL),
    (8,  RiskLevel.HIGH),
    (4,  RiskLevel.MODERATE),
    (0,  RiskLevel.LOW),
]


class RiskScorer:
    """
    Converts a raw cumulative score into a ``RiskLevel``.

    The thresholds used are the module-level ``SCORE_THRESHOLDS`` list.
    Inject a custom list to override in tests.

    Parameters
    ----------
    thresholds:
        Optional override list of ``(minimum_score, RiskLevel)`` tuples,
        in **descending** order of minimum_score.  Defaults to
        ``SCORE_THRESHOLDS``.
    """

    def __init__(
        self,
        thresholds: list[tuple[int, RiskLevel]] | None = None,
    ) -> None:
        self._thresholds = thresholds if thresholds is not None else SCORE_THRESHOLDS

    def score_to_level(self, score: int) -> RiskLevel:
        """
        Map a cumulative integer score to a ``RiskLevel``.

        Parameters
        ----------
        score:
            Non-negative integer cumulative risk score.

        Returns
        -------
        RiskLevel
            The highest band whose minimum threshold is ≤ ``score``.
        """
        for minimum, level in self._thresholds:
            if score >= minimum:
                return level
        # Fallback — should never be reached with a correctly ordered list.
        return RiskLevel.LOW
