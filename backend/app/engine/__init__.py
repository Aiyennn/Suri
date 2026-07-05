"""
engine/__init__.py
==================
Public API for the Suri wound-assessment rule engine.

Import ``WoundAssessmentEngine`` and call ``assess()`` to run a full
deterministic evaluation against structured AI-model output.

Example
-------
>>> from engine import WoundAssessmentEngine
>>> engine = WoundAssessmentEngine()
>>> result = engine.assess(raw_model_output)
"""

from .engine import WoundAssessmentEngine

__all__ = ["WoundAssessmentEngine"]
