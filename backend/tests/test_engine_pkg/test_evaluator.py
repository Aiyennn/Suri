"""
tests/engine/test_evaluator.py
==============================
Unit tests for ``engine/evaluator.py``.

Uses isolated registries with hand-crafted rules to test the evaluator's
aggregation logic without depending on the full built-in rule set.
"""


from app.engine.evaluator import RuleEvaluator
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
from app.engine.registry import RuleRegistry
from app.engine.rules import Rule

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _simple_input() -> WoundAssessmentInput:
    return WoundAssessmentInput(
        classification=Classification(
            wound_type=WoundType.ABRASION,
            severity=Severity.MILD,
            healing_stage=HealingStage.PROLIFERATIVE,
        ),
        observations=Observations(
            redness=False,
            bleeding=BleedingLevel.NONE,
            exudate=ExudateInfo(present=False, type=ExudateType.NONE, amount=ExudateAmount.NONE),
        ),
        confidence=0.95,
    )


def _always_true_rule(rule_id: str, score: int, **kwargs) -> Rule:
    return Rule(
        id=rule_id,
        name=f"Always True {rule_id}",
        description="Test rule — always triggers.",
        condition=lambda _: True,
        priority=10,
        score=score,
        recommendation="Test recommendation.",
        explanation="Test explanation.",
        **kwargs,
    )


def _always_false_rule(rule_id: str) -> Rule:
    return Rule(
        id=rule_id,
        name=f"Always False {rule_id}",
        description="Test rule — never triggers.",
        condition=lambda _: False,
        priority=20,
        score=5,
        recommendation="Should never appear.",
        explanation="Should never appear.",
    )


def _make_registry(*rules: Rule) -> RuleRegistry:
    reg = RuleRegistry.__new__(RuleRegistry)
    reg._rules = {}
    for rule in rules:
        reg.register(rule)
    return reg


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

class TestRuleEvaluator:
    def test_no_rules_returns_zero_score(self):
        reg = _make_registry()
        evaluator = RuleEvaluator(reg)
        result = evaluator.evaluate(_simple_input())
        assert result.total_score == 0
        assert result.matches == []
        assert result.forces_referral is False
        assert result.forces_emergency is False
        assert result.minimum_follow_up_hours is None

    def test_single_matching_rule_scores_correctly(self):
        reg = _make_registry(_always_true_rule("T1", score=3))
        result = RuleEvaluator(reg).evaluate(_simple_input())
        assert result.total_score == 3
        assert len(result.matches) == 1
        assert result.matches[0].rule.id == "T1"

    def test_non_matching_rule_not_included(self):
        reg = _make_registry(_always_false_rule("F1"))
        result = RuleEvaluator(reg).evaluate(_simple_input())
        assert result.total_score == 0
        assert result.matches == []

    def test_scores_accumulate_across_rules(self):
        reg = _make_registry(
            _always_true_rule("T1", score=3),
            _always_true_rule("T2", score=4),
            _always_true_rule("T3", score=2),
        )
        result = RuleEvaluator(reg).evaluate(_simple_input())
        assert result.total_score == 9
        assert len(result.matches) == 3

    def test_forces_referral_is_false_by_default(self):
        reg = _make_registry(_always_true_rule("T1", score=1))
        result = RuleEvaluator(reg).evaluate(_simple_input())
        assert result.forces_referral is False

    def test_forces_referral_propagates(self):
        reg = _make_registry(
            _always_true_rule("T1", score=1, forces_referral=True)
        )
        result = RuleEvaluator(reg).evaluate(_simple_input())
        assert result.forces_referral is True

    def test_forces_emergency_propagates(self):
        reg = _make_registry(
            _always_true_rule("T1", score=1, forces_emergency=True)
        )
        result = RuleEvaluator(reg).evaluate(_simple_input())
        assert result.forces_emergency is True

    def test_forces_referral_is_or_reduced(self):
        """Referral flag from one rule should not be suppressed by others."""
        reg = _make_registry(
            _always_true_rule("T1", score=1, forces_referral=False),
            _always_true_rule("T2", score=1, forces_referral=True),
        )
        result = RuleEvaluator(reg).evaluate(_simple_input())
        assert result.forces_referral is True

    def test_minimum_follow_up_hours_is_min(self):
        reg = _make_registry(
            _always_true_rule("T1", score=1, follow_up_hours=48),
            _always_true_rule("T2", score=1, follow_up_hours=24),
            _always_true_rule("T3", score=1, follow_up_hours=72),
        )
        result = RuleEvaluator(reg).evaluate(_simple_input())
        assert result.minimum_follow_up_hours == 24

    def test_minimum_follow_up_none_when_no_rule_sets_it(self):
        reg = _make_registry(_always_true_rule("T1", score=1))
        result = RuleEvaluator(reg).evaluate(_simple_input())
        assert result.minimum_follow_up_hours is None

    def test_erroring_rule_is_skipped_gracefully(self):
        def boom(_):
            raise RuntimeError("Rule exploded")

        bad_rule = Rule(
            id="BAD",
            name="Bad Rule",
            description="Always raises.",
            condition=boom,
            priority=10,
            score=10,
            recommendation="N/A",
            explanation="N/A",
        )
        good_rule = _always_true_rule("GOOD", score=2)
        reg = _make_registry(bad_rule, good_rule)
        result = RuleEvaluator(reg).evaluate(_simple_input())
        # BAD rule should be skipped, GOOD rule should still fire.
        assert result.total_score == 2
        assert len(result.matches) == 1
        assert result.matches[0].rule.id == "GOOD"

    def test_rules_evaluated_in_priority_order(self):
        """Matches should be in ascending priority order."""
        reg = _make_registry(
            _always_true_rule("HIGH_PRIO", score=1),
            Rule(
                id="LOW_PRIO",
                name="Low Priority",
                description="Low priority rule.",
                condition=lambda _: True,
                priority=5,
                score=1,
                recommendation="Low.",
                explanation="Low.",
            ),
        )
        # Patch priorities directly
        reg._rules["HIGH_PRIO"] = Rule(
            id="HIGH_PRIO",
            name="High Priority",
            description="High priority rule.",
            condition=lambda _: True,
            priority=1,
            score=1,
            recommendation="High.",
            explanation="High.",
        )
        result = RuleEvaluator(reg).evaluate(_simple_input())
        ids = [m.rule.id for m in result.matches]
        assert ids.index("HIGH_PRIO") < ids.index("LOW_PRIO")
