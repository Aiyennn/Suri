"""
core/database.py
================
SQLAlchemy engine, session factory, and declarative base.

Usage
-----
Import ``Base`` when defining ORM models::

    from core.database import Base

Import ``SessionLocal`` (or use the ``get_db`` dependency) to obtain a
database session in request handlers::

    from core.database import SessionLocal
"""

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

from core.config import settings

# ── Engine ────────────────────────────────────────────────────────────────
engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,
    echo=settings.DEBUG,
)

# ── Session factory ───────────────────────────────────────────────────────
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)

# ── Declarative base ─────────────────────────────────────────────────────
Base = declarative_base()
