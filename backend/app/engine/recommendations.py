"""
engine/recommendations.py
=========================
Recommendation consolidation.

Collects recommendation strings from all triggered rules, deduplicates them
while preserving priority order (the first occurrence of each unique string
wins), and appends a universal safety footer.
"""

from __future__ import annotations

from engine.evaluator import EvaluationResult


# ---------------------------------------------------------------------------
# Universal safety footer
# ---------------------------------------------------------------------------

_SAFETY_FOOTER: str = (
    "If you are ever unsure about a wound's severity or progression, "
    "please consult a licensed healthcare professional. "
    "This engine provides decision support only — it does not replace clinical judgment."
)


class RecommendationEngine:
    """
    Produces a deduplicated, ordered list of recommendation strings.

    Recommendations are extracted from triggered rules in priority order
    (rules with lower ``priority`` values appear first).  Duplicate strings
    are removed, and a universal safety footer is appended at the end.
    """

    def build(self, evaluation_result: EvaluationResult) -> list[str]:
        """
        Compile the final recommendation list for a given evaluation result.

        Parameters
        ----------
        evaluation_result:
            The :class:`EvaluationResult` produced by the evaluator.

        Returns
        -------
        list[str]
            Ordered, deduplicated recommendations with the safety footer last.
        """
        seen: set[str] = set()
        recommendations: list[str] = []

        for match in evaluation_result.matches:
            text = match.rule.recommendation.strip()
            if text and text not in seen:
                seen.add(text)
                recommendations.append(text)

        # Always append the safety footer (deduplicated against itself).
        if _SAFETY_FOOTER not in seen:
            recommendations.append(_SAFETY_FOOTER)

        return recommendations
