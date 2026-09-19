"""
dependencies.py
===============
Shared FastAPI dependency functions used across all routers.
"""

from collections.abc import Generator

from fastapi import Depends, HTTPException, Request, status
from sqlalchemy.orm import Session, sessionmaker

from app.repository.wound_repository import WoundAssessmentRepository
from app.services.assessment_explanation_service import AssessmentExplanationService
from app.services.wound_service import WoundService


def get_db(request: Request) -> Generator[Session, None, None]:
    """Yield a SQLAlchemy session and close it after the request."""
    session_factory: sessionmaker[Session] | None = getattr(
        request.app.state, "session_factory", None
    )
    if session_factory is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database is not available.",
        )

    db = session_factory()

    try:
        yield db
    finally:
        db.close()


def get_redis(request: Request):
    """Return the Redis client initialized for this application instance."""
    redis_client = getattr(request.app.state, "redis_client", None)
    if redis_client is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Redis is not available.",
        )
    return redis_client


def get_assessment_explanation_service(
    request: Request,
) -> AssessmentExplanationService:
    """Return AssessmentExplanationService initialized for this app instance."""
    explanation_service = getattr(request.app.state, "explanation_service", None)
    if explanation_service is None:
        explanation_service = AssessmentExplanationService()
    return explanation_service


def get_wound_repository(db: Session = Depends(get_db)) -> WoundAssessmentRepository:
    """Return a WoundAssessmentRepository bound to the current database session."""
    return WoundAssessmentRepository(db)


def get_wound_service(
    repository: WoundAssessmentRepository = Depends(get_wound_repository),
    explanation_service: AssessmentExplanationService = Depends(
        get_assessment_explanation_service
    ),
) -> WoundService:
    """Return a WoundService instance wired with repository and explanation service."""
    return WoundService(
        repository=repository,
        explanation_service=explanation_service,
    )
