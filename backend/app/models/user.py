"""
models/user.py
==============
SQLAlchemy ORM model for the ``users`` table.

Stores basic user account information for the Suri mobile app.
Each user can have many wound assessments linked via the
``user_id`` foreign key on ``WoundAssessment``.
"""

import uuid
from datetime import datetime, timezone

from sqlalchemy import Boolean, Column, Date, DateTime, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from core.database import Base


class User(Base):
    """User account for the Suri mobile application."""

    __tablename__ = "users"

    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        doc="Auto-generated UUID primary key.",
    )
    email = Column(
        String(255),
        unique=True,
        nullable=False,
        index=True,
        doc="Unique email address used for login.",
    )
    hashed_password = Column(
        String(255),
        nullable=False,
        doc="bcrypt-hashed password.",
    )
    full_name = Column(
        String(255),
        nullable=False,
        doc="User display name.",
    )
    date_of_birth = Column(
        Date,
        nullable=True,
        doc="Optional date of birth for demographic context.",
    )
    sex = Column(
        String(10),
        nullable=True,
        doc="Biological sex: 'male', 'female', or 'other'.",
    )
    medical_history = Column(
        Text,
        nullable=True,
        doc="Freeform medical background (conditions, allergies, medications).",
    )
    is_active = Column(
        Boolean,
        default=True,
        nullable=False,
        doc="Soft-delete flag; inactive users cannot log in.",
    )
    created_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
        doc="Timestamp when the account was created.",
    )
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
        doc="Timestamp of the last profile update.",
    )

    # ── Relationships ─────────────────────────────────────────────────────
    assessments = relationship(
        "WoundAssessment",
        back_populates="user",
        lazy="selectin",
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return f"<User id={self.id!s:.8} email={self.email!r}>"
