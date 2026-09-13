"""Database factories and the application's declarative base."""

from sqlalchemy import Engine, create_engine
from sqlalchemy.orm import Session, declarative_base, sessionmaker

from app.core.config import Settings


def create_database_engine(settings: Settings) -> Engine:
    """Build the SQLAlchemy engine used for one application instance."""
    """Build the SQLAlchemy engine used for one application instance.

    Engine settings are tuned per environment:

    * **development** – smaller pool, SQL echo on, no SSL (local Docker).
    * **production**  – larger pool, SQL echo off, SSL required (Supabase).
    * **testing**     – smallest pool, echo off (speed over visibility).
    """
    common: dict = dict(pool_pre_ping=True)
    print("Database Credentials:")
    print(settings.DATABASE_URL)

    if settings.is_development:
        return create_engine(
            settings.DATABASE_URL,
            echo=True,           # print SQL to console
            pool_size=5,
            max_overflow=5,
            **common,
        )

    if settings.is_production:
        return create_engine(
            settings.DATABASE_URL,
            echo=False,
            pool_size=10,
            max_overflow=20,
            connect_args={"sslmode": "require"},
            **common,
        )

    # testing (or any other future env)
    return create_engine(
        settings.DATABASE_URL,
        pool_pre_ping=True,
        echo=False,
        pool_size=2,
        max_overflow=2,
        **common,
    )


def create_session_factory(engine: Engine) -> sessionmaker[Session]:
    """Build sessions with the project's existing transaction defaults."""
    return sessionmaker(autocommit=False, autoflush=False, bind=engine)


# Imported by models and Alembic; metadata itself has no infrastructure side effect.
Base = declarative_base()
