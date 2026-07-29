"""
models/image_quality_result.py
==============================
SQLAlchemy ORM model for the ``image_quality_results`` table.

Stores the pixel-based quality metrics computed for each wound image
before it is forwarded to the AI model.  One-to-one with ``WoundImage``.
"""

import uuid

from sqlalchemy import Boolean, Column, Float, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.database import Base


class ImageQualityResult(Base):
    """Quality-gate metrics for a single wound image."""

    __tablename__ = "image_quality_results"

    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        doc="Auto-generated UUID primary key.",
    )
    image_id = Column(
        UUID(as_uuid=True),
        ForeignKey("wound_images.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        doc="One-to-one FK to the wound image.",
    )

    # ── Quality metrics ───────────────────────────────────────────────────
    is_valid = Column(
        Boolean,
        nullable=False,
        doc="True if the image passed all quality thresholds.",
    )
    blur = Column(
        Float,
        nullable=False,
        doc="Laplacian variance — values below 100 are too blurry.",
    )
    brightness = Column(
        Float,
        nullable=False,
        doc="Mean pixel intensity (0-255). <40 too dark, >220 overexposed.",
    )
    contrast = Column(
        Float,
        nullable=False,
        doc="Pixel intensity std-dev. Below 15 is insufficient contrast.",
    )

    # ── Relationships ─────────────────────────────────────────────────────
    image = relationship(
        "WoundImage",
        back_populates="quality_result",
    )

    def __repr__(self) -> str:
        return (
            f"<ImageQualityResult id={self.id!s:.8} "
            f"is_valid={self.is_valid} blur={self.blur:.1f}>"
        )
