"""
tests/engine/test_scoring.py
============================
Unit tests for ``engine/scoring.py``.

Verifies that score-to-level mapping respects all threshold boundaries,
including edge cases at exact boundary values.
"""

import pytest

from engine.models import RiskLevel
from engine.scoring import RiskScorer, SCORE_THRESHOLDS


class TestRiskScorer:
    def setup_method(self):
        self.scorer = RiskScorer()

    # ------------------------------------------------------------------
    # Low risk band  (0–3)
    # ------------------------------------------------------------------

    def test_score_0_is_low(self):
        assert self.scorer.score_to_level(0) == RiskLevel.LOW

    def test_score_3_is_low(self):
        assert self.scorer.score_to_level(3) == RiskLevel.LOW

    # ------------------------------------------------------------------
    # Moderate risk band  (4–7)
    # ------------------------------------------------------------------

    def test_score_4_is_moderate(self):
        assert self.scorer.score_to_level(4) == RiskLevel.MODERATE

    def test_score_7_is_moderate(self):
        assert self.scorer.score_to_level(7) == RiskLevel.MODERATE

    # ------------------------------------------------------------------
    # High risk band  (8–12)
    # ------------------------------------------------------------------

    def test_score_8_is_high(self):
        assert self.scorer.score_to_level(8) == RiskLevel.HIGH

    def test_score_12_is_high(self):
        assert self.scorer.score_to_level(12) == RiskLevel.HIGH

    # ------------------------------------------------------------------
    # Critical risk band  (13+)
    # ------------------------------------------------------------------

    def test_score_13_is_critical(self):
        assert self.scorer.score_to_level(13) == RiskLevel.CRITICAL

    def test_score_100_is_critical(self):
        assert self.scorer.score_to_level(100) == RiskLevel.CRITICAL

    # ------------------------------------------------------------------
    # Custom thresholds
    # ------------------------------------------------------------------

    def test_custom_thresholds_respected(self):
        custom_scorer = RiskScorer(
            thresholds=[
                (10, RiskLevel.CRITICAL),
                (5,  RiskLevel.HIGH),
                (0,  RiskLevel.LOW),
            ]
        )
        assert custom_scorer.score_to_level(4) == RiskLevel.LOW
        assert custom_scorer.score_to_level(5) == RiskLevel.HIGH
        assert custom_scorer.score_to_level(9) == RiskLevel.HIGH
        assert custom_scorer.score_to_level(10) == RiskLevel.CRITICAL


class TestScoreThresholdsConstant:
    """Validate that the module-level constant is ordered correctly."""

    def test_thresholds_are_descending(self):
        scores = [t[0] for t in SCORE_THRESHOLDS]
        assert scores == sorted(scores, reverse=True), (
            "SCORE_THRESHOLDS must be in descending order of minimum score."
        )

    def test_thresholds_cover_zero(self):
        """At least one threshold must have minimum 0 to catch all scores."""
        minimums = {t[0] for t in SCORE_THRESHOLDS}
        assert 0 in minimums
