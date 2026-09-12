"""
dependencies.py
===============
Shared FastAPI dependency functions used across all routers.
"""

from collections.abc import Generator

from fastapi import HTTPException, Request, status
from sqlalchemy.orm import Session, sessionmaker


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
