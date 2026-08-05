"""
Wound Assessment Engine — public orchestrator.

Pipeline
--------
    raw dict
        → validate (validation.py)
        → evaluate (evaluator.py + registry.py)
        → score    (scoring.py)
        → recommend (recommendations.py)
        → referral  (referrals.py)
        → follow-up (followup.py)
        → AssessmentResult (models.py)
"""

from __future__ import annotations

import logging

from app.engine.evaluator import RuleEvaluator
from app.engine.followup import FollowUpScheduler
from app.engine.schemas import AssessmentResult, TriggeredRule
from app.engine.recommendations import RecommendationBuilder
from app.engine.referrals import ReferralChecker
from app.engine.registry import rule_registry
from app.engine.scoring import RiskScorer
from app.engine.validation import validate_input

logger = logging.getLogger(__name__)


class WoundAssessmentEngine:

    def __init__(
        self,
        evaluator: RuleEvaluator | None = None,
        scorer: RiskScorer | None = None,
        recommendation_engine: RecommendationBuilder | None = None,
        referral_engine: ReferralChecker | None = None,
        follow_up_scheduler: FollowUpScheduler | None = None,
    ) -> None:
        self._evaluator = evaluator or RuleEvaluator(rule_registry)
        self._scorer = scorer or RiskScorer()
        self._recommender = recommendation_engine or RecommendationBuilder()
        self._referral = referral_engine or ReferralChecker()
        self._follow_up = follow_up_scheduler or FollowUpScheduler()

    def assess(self, raw_model_output: dict, patient_context: dict | None = None) -> AssessmentResult:

        # Run assessment pipeline

        logger.info("WoundAssessmentEngine.assess() — starting pipeline.")

        # 1. Validate — merge patient context before validation
        logger.info("Raw model output:\n%s", raw_model_output)

        engine_input = dict(raw_model_output)
        if patient_context:
            if "duration" in patient_context:
                engine_input["duration"] = patient_context["duration"]

        assessment_input = validate_input(engine_input)
        
        logger.debug("Input validated: %s", assessment_input)

        # 2. Evaluate rules
        evaluation_result = self._evaluator.evaluate(assessment_input)
        logger.debug(
            "Evaluation: %d rules triggered, raw score=%d.",
            len(evaluation_result.matches),
            evaluation_result.total_score,
        )

        # 3. Score → Risk level
        risk_score = evaluation_result.total_score
        risk_level = self._scorer.classify_risk_level(risk_score)
        logger.debug("Risk: score=%d, level=%s.", risk_score, risk_level)

        # 4. Recommendations
        recommendations = self._recommender.build(evaluation_result)

        # 5. Referral
        referral_required = self._referral.requires_referral(
            evaluation_result, risk_level
        )

        # 6. Emergency flag
        emergency = evaluation_result.forces_emergency

        # 7. Follow-up
        follow_up = self._follow_up.schedule(evaluation_result, risk_level)

        # 8. Build triggered-rule records for transparency
        triggered_rules = [
            TriggeredRule(
                id=match.rule.id,
                name=match.rule.name,
                reason=match.explanation,
                score_contribution=match.rule.score,
            )
            for match in evaluation_result.matches
        ]

        logger.info(
            "Assessment complete — level=%s, referral=%s, emergency=%s, follow_up=%s.",
            risk_level,
            referral_required,
            emergency,
            follow_up,
        )

        return AssessmentResult(
            risk_score=risk_score,
            risk_level=risk_level,
            recommendations=recommendations,
            referral_required=referral_required,
            emergency=emergency,
            follow_up=follow_up,
            triggered_rules=triggered_rules,
        )
