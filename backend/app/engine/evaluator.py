"""
engine/evaluator.py
===================
Rule evaluator — applies every registered rule to a ``WoundAssessmentInput``
and collects results.

The evaluator is intentionally decoupled from both the rule definitions
(``rules.py``) and the registry (``registry.py``).  It receives a registry
object at construction time, making it fully testable in isolation with a
custom registry containing only the rules under test.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass

from app.engine.schemas import WoundAssessmentInput
from app.engine.registry import RuleRegistry
from app.engine.rules import Rule

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Evaluation result
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class RuleMatch:
    """
    Records that a single rule fired against a given input.

    Attributes
    ----------
    rule:
        The :class:`Rule` instance that matched.
    explanation:
        The rule's ``explanation`` string (captured at evaluation time so
        the result is self-contained even if the registry is mutated later).
    """

    rule: Rule
    explanation: str


@dataclass(frozen=True)
class EvaluationResult:
    """
    Aggregate outcome of running all rules against a single input.

    Attributes
    ----------
    matches:
        All rules that returned ``True`` for the given input, in priority order.
    total_score:
        Sum of ``rule.score`` across all matches.
    forces_referral:
        ``True`` if any matched rule set ``forces_referral=True``.
    forces_emergency:
        ``True`` if any matched rule set ``forces_emergency=True``.
    minimum_follow_up_hours:
        The smallest ``follow_up_hours`` value across matched rules that
        specified one, or ``None`` if no rule constrained follow-up.
    """

    matches: list[RuleMatch]
    total_score: int
    forces_referral: bool
    forces_emergency: bool
    minimum_follow_up_hours: int | None


# ---------------------------------------------------------------------------
# Evaluator
# ---------------------------------------------------------------------------

class RuleEvaluator:
    """
    Evaluates all rules in a ``RuleRegistry`` against a ``WoundAssessmentInput``.

    Parameters
    ----------
    registry:
        The :class:`RuleRegistry` whose rules will be evaluated.
    """

    def __init__(self, registry: RuleRegistry) -> None:
        self._registry = registry

    def evaluate(self, assessment_input: WoundAssessmentInput) -> EvaluationResult:
        """
        Run all registered rules and return a consolidated result.

        Rules are evaluated in priority order (ascending).  Every rule whose
        ``condition`` returns ``True`` contributes its ``score``,
        ``forces_referral``, ``forces_emergency``, and ``follow_up_hours``
        to the aggregate output.

        Parameters
        ----------
        assessment_input:
            Validated :class:`WoundAssessmentInput` to evaluate.

        Returns
        -------
        EvaluationResult
            Aggregate result including all matched rules and derived flags.
        """
        matches: list[RuleMatch] = []
        total_score: int = 0
        forces_referral: bool = False
        forces_emergency: bool = False
        follow_up_hours_candidates: list[int] = []

        for rule in self._registry.get_all():
            try:
                triggered = rule.condition(assessment_input)
            except Exception:
                logger.exception(
                    "Rule '%s' raised an exception during evaluation — skipping.",
                    rule.id,
                )
                continue

            if triggered:
                logger.debug("Rule triggered: %s (%s)", rule.id, rule.name)
                matches.append(RuleMatch(rule=rule, explanation=rule.explanation))
                total_score += rule.score

                if rule.forces_referral:
                    forces_referral = True
                if rule.forces_emergency:
                    forces_emergency = True
                if rule.follow_up_hours is not None:
                    follow_up_hours_candidates.append(rule.follow_up_hours)

        minimum_follow_up = (
            min(follow_up_hours_candidates) if follow_up_hours_candidates else None
        )

        logger.info(
            "Evaluation complete — %d rules triggered, score=%d, "
            "referral=%s, emergency=%s.",
            len(matches),
            total_score,
            forces_referral,
            forces_emergency,
        )

        return EvaluationResult(
            matches=matches,
            total_score=total_score,
            forces_referral=forces_referral,
            forces_emergency=forces_emergency,
            minimum_follow_up_hours=minimum_follow_up,
        )
