"""
schemas/__init__.py
===================
Exposes all Pydantic schemas used by the Suri backend.

Import from this package to access request and response models:

    from schemas import WoundAnalysisResponse, PatientInfo
"""

from schemas.wound import (
    PatientInfo,
    ImageQualityMetrics,
    ImageQualityAssessment,
    TriggeredRule,
    WoundAnalysisResult,
    ImageAnalysisResult,
    WoundAnalysisResponse,
)

__all__ = [
    "PatientInfo",
    "ImageQualityMetrics",
    "ImageQualityAssessment",
    "TriggeredRule",
    "WoundAnalysisResult",
    "ImageAnalysisResult",
    "WoundAnalysisResponse",
]
