"""
dependencies.py
===============
Shared FastAPI dependency functions used across all routers.
"""

from collections.abc import Generator

from sqlalchemy.orm import Session

from app.db.database import SessionLocal


def get_db() -> Generator[Session, None, None]:
    """Yield a SQLAlchemy session and close it after the request."""
    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()