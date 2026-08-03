"""
models/__init__.py
==================
Re-exports all SQLAlchemy ORM models for convenient imports::

    from models import User, WoundAssessment, WoundImage

Importing this package also ensures every model class is registered
with the ``Base`` metadata, which is required for Alembic migrations
and ``Base.metadata.create_all()`` calls.
"""

from app.db.database import Base
from app.models.analysis_result import WoundAnalysisRecord
from app.models.image_quality_result import ImageQualityResult
from app.models.user import User
from app.models.wound_assessment import WoundAssessment
from app.models.wound_image import WoundImage

__all__ = [
    "ImageQualityResult",
    "User",
    "WoundAnalysisRecord",
    "WoundAssessment",
    "WoundImage",
]
