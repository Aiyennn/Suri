"""
models/wound_assessment.py
==========================
SQLAlchemy ORM model for the ``wound_assessments`` table.

Represents a single analysis session: a user uploads patient context
and one or more wound images.  The patient demographic fields mirror
the ``PatientInfo`` Pydantic schema in ``schemas/wound.py``.
"""

import uuid
from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import JSON, UUID
from sqlalchemy.orm import relationship

from app.db.database import Base


class WoundAssessment(Base):
    """One assessment session containing patient context and wound images."""

    __tablename__ = "wound_assessments"

    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        doc="Auto-generated UUID primary key.",
    )
    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
        doc="FK to the submitting user (nullable until auth is wired).",
    )

    # ── Patient context (from PatientInfo schema) ─────────────────────────
    patient_age = Column(
        String(20),
        nullable=False,
        doc="Patient age, e.g. '34' or '34 years'.",
    )
    patient_sex = Column(
        String(10),
        nullable=False,
        doc="Biological sex: 'male', 'female', or 'other'.",
    )
    symptoms = Column(
        JSON,
        nullable=False,
        doc="JSON list of symptom strings, e.g. ['redness', 'swelling'].",
    )
    duration = Column(
        String(50),
        nullable=False,
        doc="How long the wound has been present, e.g. '3 days'.",
    )
    medical_history = Column(
        JSON,
        nullable=False,
        default=list,
        doc="List of relevant past medical conditions, allergies, or medications.",
    )
    created_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
        doc="Timestamp when the assessment was submitted.",
    )

    # ── Relationships ─────────────────────────────────────────────────────
    user = relationship(
        "User",
        back_populates="assessments",
    )
    images = relationship(
        "WoundImage",
        back_populates="assessment",
        lazy="selectin",
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return (
            f"<WoundAssessment id={self.id!s:.8} "
            f"user_id={self.user_id!s:.8} created_at={self.created_at}>"
        )
