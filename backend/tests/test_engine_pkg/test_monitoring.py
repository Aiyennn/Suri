"""
tests/test_engine_pkg/test_monitoring.py
========================================
Unit tests for ``engine/monitoring.py`` — the MonitoringBuilder.

Tests cover:
* Empty result when no rules are triggered
* Empty monitoring strings are excluded
* Deduplication of identical monitoring strings
* Priority order is preserved (first occurrence wins)
* Integration: emergency scenario produces non-empty signs
"""

from __future__ import annotations

from dataclasses import dataclass, field

import pytest

from app.engine.evaluator import EvaluationResult, RuleMatch
from app.engine.monitoring import MonitoringBuilder
from app.engine.rules import Rule
from app.engine.schemas import (
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


# ---------------------------------------------------------------------------
# Helpers — build minimal Rule and RuleMatch objects
# ---------------------------------------------------------------------------

def _make_rule(
    rule_id: str,
    priority: int = 50,
    monitoring: str = "",
) -> Rule:
    """Build a minimal Rule with the given monitoring string."""
    return Rule(
        id=rule_id,
        name=f"Rule {rule_id}",
        description="Test rule.",
        condition=lambda i: True,
        priority=priority,
        score=1,
        recommendation="Do something.",
        explanation="Because.",
        monitoring=monitoring,
    )


def _make_match(rule: Rule) -> RuleMatch:
    return RuleMatch(rule=rule, explanation=rule.explanation)


def _make_result(matches: list[RuleMatch]) -> EvaluationResult:
    return EvaluationResult(
        matches=matches,
        total_score=sum(m.rule.score for m in matches),
        forces_referral=any(m.rule.forces_referral for m in matches),
        forces_emergency=any(m.rule.forces_emergency for m in matches),
        minimum_follow_up_hours=None,
    )


# ---------------------------------------------------------------------------
# Fixture
# ---------------------------------------------------------------------------

@pytest.fixture
def builder() -> MonitoringBuilder:
    return MonitoringBuilder()


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

class TestMonitoringBuilderEmpty:
    def test_no_matches_returns_empty_list(self, builder: MonitoringBuilder):
        result = _make_result([])
        assert builder.build(result) == []

    def test_all_empty_monitoring_strings_returns_empty_list(self, builder: MonitoringBuilder):
        rules = [
            _make_rule("R1", monitoring=""),
            _make_rule("R2", monitoring="   "),  # whitespace only
            _make_rule("R3", monitoring=""),
        ]
        result = _make_result([_make_match(r) for r in rules])
        assert builder.build(result) == []


class TestMonitoringBuilderDeduplication:
    def test_duplicate_signs_appear_once(self, builder: MonitoringBuilder):
        sign = "Spreading redness beyond the wound margin."
        rules = [
            _make_rule("R1", priority=10, monitoring=sign),
            _make_rule("R2", priority=20, monitoring=sign),
        ]
        result = _make_result([_make_match(r) for r in rules])
        signs = builder.build(result)
        assert signs.count(sign) == 1

    def test_distinct_signs_all_included(self, builder: MonitoringBuilder):
        rules = [
            _make_rule("R1", priority=10, monitoring="Watch for fever."),
            _make_rule("R2", priority=20, monitoring="Watch for pus."),
            _make_rule("R3", priority=30, monitoring="Watch for swelling."),
        ]
        result = _make_result([_make_match(r) for r in rules])
        signs = builder.build(result)
        assert len(signs) == 3


class TestMonitoringBuilderOrdering:
    def test_priority_order_preserved(self, builder: MonitoringBuilder):
        """Lower priority number = appears first in the output."""
        rules = [
            _make_rule("R_HIGH", priority=5, monitoring="Sign A — high priority."),
            _make_rule("R_MED",  priority=50, monitoring="Sign B — medium priority."),
            _make_rule("R_LOW",  priority=90, monitoring="Sign C — low priority."),
        ]
        # Matches are assumed to arrive in priority order (as the evaluator produces them).
        result = _make_result([_make_match(r) for r in rules])
        signs = builder.build(result)
        assert signs[0] == "Sign A — high priority."
        assert signs[1] == "Sign B — medium priority."
        assert signs[2] == "Sign C — low priority."

    def test_first_occurrence_wins_on_duplicate(self, builder: MonitoringBuilder):
        """When the same sign appears at two priorities, the higher-priority match wins."""
        sign = "Shared monitoring sign."
        rules = [
            _make_rule("R_FIRST", priority=10, monitoring=sign),
            _make_rule("R_SECOND", priority=80, monitoring=sign),
        ]
        result = _make_result([_make_match(r) for r in rules])
        signs = builder.build(result)
        assert signs == [sign]


class TestMonitoringBuilderIntegration:
    """Use the real engine to verify monitoring_signs are produced end-to-end."""

    def test_emergency_scenario_produces_monitoring_signs(self):
        from app.engine.engine import WoundAssessmentEngine
        engine = WoundAssessmentEngine()
        raw = {
            "classification": {
                "wound_type": "laceration",
                "severity": "critical",
                "healing_stage": "hemostasis",
            },
            "observations": {
                "redness": True,
                "bleeding": "heavy",
                "exudate": {"present": True, "type": "sanguineous", "amount": "high"},
            },
            "confidence": 0.91,
        }
        result = engine.assess(raw)
        assert isinstance(result.monitoring_signs, list)
        assert len(result.monitoring_signs) > 0

    def test_monitoring_signs_are_deduplicated(self):
        from app.engine.engine import WoundAssessmentEngine
        engine = WoundAssessmentEngine()
        raw = {
            "classification": {
                "wound_type": "abrasion",
                "severity": "moderate",
                "healing_stage": "inflammatory",
            },
            "observations": {
                "redness": True,
                "bleeding": "minimal",
                "exudate": {"present": True, "type": "serous", "amount": "low"},
            },
            "confidence": 0.94,
        }
        result = engine.assess(raw)
        # No sign should appear more than once.
        assert len(result.monitoring_signs) == len(set(result.monitoring_signs))

    def test_low_risk_scenario_monitoring_signs_is_list(self):
        from app.engine.engine import WoundAssessmentEngine
        engine = WoundAssessmentEngine()
        raw = {
            "classification": {
                "wound_type": "abrasion",
                "severity": "mild",
                "healing_stage": "proliferative",
            },
            "observations": {
                "redness": False,
                "bleeding": "none",
                "exudate": {"present": False, "type": "none", "amount": "none"},
            },
            "confidence": 0.92,
        }
        result = engine.assess(raw)
        assert isinstance(result.monitoring_signs, list)

    def test_monitoring_signs_are_strings(self):
        from app.engine.engine import WoundAssessmentEngine
        engine = WoundAssessmentEngine()
        raw = {
            "classification": {
                "wound_type": "burn",
                "severity": "severe",
                "healing_stage": "inflammatory",
            },
            "observations": {
                "redness": True,
                "bleeding": "none",
                "exudate": {"present": True, "type": "serous", "amount": "moderate"},
            },
            "confidence": 0.88,
        }
        result = engine.assess(raw)
        assert all(isinstance(s, str) for s in result.monitoring_signs)
