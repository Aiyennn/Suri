from app.models.wound_assessment import WoundAssessment
from app.models.wound_image import WoundImage
from app.models.image_quality_result import ImageQualityResult
from app.models.analysis_result import WoundAnalysisRecord
from app.schemas.wound import AssessmentListResponse, AssessmentSummary
from sqlalchemy import func
from sqlalchemy.orm import Session
import uuid

class WoundAssessmentRepository:

    def __init__(self, db: Session):
        self.db = db

    def create_assessment(
            self,
            user_id: uuid.UUID,
            age: str,
            sex: str,
            symptoms: list[str],
            duration: str,
            medical_history: str,
    ) -> WoundAssessment:
        assessment = WoundAssessment(
            user_id=user_id,
            patient_age=age,
            patient_sex=sex,
            symptoms=symptoms,
            duration=duration,
            medical_history=medical_history,
        )

        self.db.add(assessment)
        self.db.flush()

        return assessment

    def save_image_record(
            self,
            assessment_id: uuid.UUID,
            image_bytes: bytes,
            original_filename: str | None,
            content_type: str | None,
            
    ) -> WoundImage:
        wound_image = WoundImage(
            assessment_id=assessment_id,
            image_bytes=image_bytes,
            original_filename=original_filename,
            content_type=content_type
        )
        self.db.add(wound_image)
        self.db.flush()

        return wound_image

    def save_quality_metrics(
            self,
            image_id: uuid.UUID,
            is_valid: bool,
            blur: float,
            brightness: float,
            contrast: float,
    ) -> ImageQualityResult:
        quality_record = ImageQualityResult(
            image_id=image_id,
            is_valid=is_valid,
            blur=blur,
            brightness=brightness,
            contrast=contrast
        )

        self.db.add(quality_record)
        return quality_record

    def save_analysis_result(
        self,
        image_id: uuid.UUID,
        wound_type: str,
        severity: str,
        healing_stage: str,
        confidence: float,
        risk_score: int,
        risk_level: str,
        recommendations: list[str],
        referral_required: bool,
        emergency: bool,
        follow_up: str,
        triggered_rules: list[str],
        disclaimer: str,
    ) -> WoundAnalysisRecord:
        analysis_record = WoundAnalysisRecord(
            image_id=image_id,
            wound_type=wound_type,
            severity=severity,
            healing_stage=healing_stage,
            confidence=confidence,
            risk_score=risk_score,
            risk_level=risk_level,
            recommendations=recommendations,
            referral_required=referral_required,
            emergency=emergency,
            follow_up=follow_up,
            triggered_rules=triggered_rules,
            disclaimer=disclaimer,
        )

        self.db.add(analysis_record)
        return analysis_record

    def get_assessments_with_count(
    self,
    user_id: uuid.UUID,
    limit: int,
    offset: int,
    ) -> tuple[list[WoundAssessment], int]:
        query = self.db.query(WoundAssessment).filter(
            WoundAssessment.user_id == user_id
        )

        total = query.count()

        rows = (
            query.order_by(WoundAssessment.created_at.desc())
            .offset(offset)
            .limit(limit)
            .all()
        )

        return rows, total