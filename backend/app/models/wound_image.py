"""
models/wound_image.py
=====================
SQLAlchemy ORM model for the ``wound_images`` table.

Each row represents a single uploaded wound photograph within an
assessment session.  The actual image bytes are stored externally
(local disk or cloud storage); this table keeps only the path/URL.
"""

import uuid
from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from core.database import Base


class WoundImage(Base):
    """One uploaded wound image belonging to an assessment."""

    __tablename__ = "wound_images"

    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        doc="Auto-generated UUID primary key.",
    )
    assessment_id = Column(
        UUID(as_uuid=True),
        ForeignKey("wound_assessments.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
        doc="FK to the parent assessment session.",
    )
    image_path = Column(
        String(500),
        nullable=False,
        doc="File path or URL pointing to the stored image.",
    )
    original_filename = Column(
        String(255),
        nullable=True,
        doc="Original filename as uploaded by the client.",
    )
    content_type = Column(
        String(50),
        nullable=True,
        doc="MIME type of the uploaded file (e.g. 'image/jpeg').",
    )
    created_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
        doc="Timestamp when the image was uploaded.",
    )

    # ── Relationships ─────────────────────────────────────────────────────
    assessment = relationship(
        "WoundAssessment",
        back_populates="images",
    )
    quality_result = relationship(
        "ImageQualityResult",
        back_populates="image",
        uselist=False,
        cascade="all, delete-orphan",
    )
    analysis_result = relationship(
        "WoundAnalysisDBResult",
        back_populates="image",
        uselist=False,
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return (
            f"<WoundImage id={self.id!s:.8} "
            f"assessment_id={self.assessment_id!s:.8}>"
        )
