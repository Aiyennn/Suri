"""
engine/monitoring.py
====================
"What to Monitor" consolidation.

Collects monitoring-guidance strings from all triggered rules, deduplicates
them while preserving priority order (the first occurrence of each unique
string wins), and returns the final list.

Unlike recommendations, no universal footer is appended — the monitoring list
is a concise watch-list for the patient or clinician, not a safety disclaimer.
"""

from __future__ import annotations

from app.engine.evaluator import EvaluationResult


class MonitoringBuilder:
    """
    Produces a deduplicated, ordered list of "what to monitor" strings.

    Signs are extracted from triggered rules in priority order (rules with
    lower ``priority`` values appear first).  Empty ``monitoring`` strings
    (rules that carry no specific watch-guidance) are silently skipped.
    """

    def build(self, evaluation_result: EvaluationResult) -> list[str]:
        """
        Compile the final monitoring-signs list for a given evaluation result.

        Parameters
        ----------
        evaluation_result:
            The :class:`EvaluationResult` produced by the evaluator.

        Returns
        -------
        list[str]
            Ordered, deduplicated monitoring signs.  Empty when no triggered
            rule carries monitoring guidance.
        """
        seen: set[str] = set()
        signs: list[str] = []

        for match in evaluation_result.matches:
            text = match.rule.monitoring.strip()
            if text and text not in seen:
                seen.add(text)
                signs.append(text)

        return signs
