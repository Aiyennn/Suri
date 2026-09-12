"""Database factories and the application's declarative base."""

from sqlalchemy import Engine, create_engine
from sqlalchemy.orm import Session, declarative_base, sessionmaker

from app.core.config import Settings


def create_database_engine(settings: Settings) -> Engine:
    """Build the SQLAlchemy engine used for one application instance."""
    return create_engine(
        settings.DATABASE_URL,
        pool_pre_ping=True,
        echo=settings.DEBUG,
    )


def create_session_factory(engine: Engine) -> sessionmaker[Session]:
    """Build sessions with the project's existing transaction defaults."""
    return sessionmaker(autocommit=False, autoflush=False, bind=engine)


# Imported by models and Alembic; metadata itself has no infrastructure side effect.
Base = declarative_base()
