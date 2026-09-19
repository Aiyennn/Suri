import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.api.auth import router as auth_router
from app.api.chatbot import router as chatbot_router
from app.api.health import router as health_router
from app.api.medical_facilities import router as medical_facilities_router
from app.api.wound import router as wound_router
from app.core.config import settings
from app.core.exception_handlers import register_exception_handlers
from app.core.logging import configure_logging
from app.core.redis import create_redis_client
from app.db.database import create_database_engine, create_session_factory
from app.services.assessment_explanation_service import AssessmentExplanationService

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize and release infrastructure owned by this app instance."""
    configure_logging()
    logger.info("Application starting...")
    logger.info("Environment : %s", settings.ENVIRONMENT)
    engine = None
    redis_client = None
    try:

        # Long lived infrastructure
        engine = create_database_engine(settings)
        session_factory = create_session_factory(engine)
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
        redis_client = create_redis_client(settings)
        logger.info("Database    : %s", settings.db_url_safe)
        logger.info("Redis       : %s", settings.REDIS_URL)

        # Long lived application services
        explanation_service = AssessmentExplanationService()

        app.state.database_engine = engine
        app.state.session_factory = session_factory
        app.state.redis_client = redis_client
        app.state.explanation_service = explanation_service
        yield
    finally:
        logger.info("Application shutting down...")
        if redis_client is not None:
            redis_client.close()
        if engine is not None:
            engine.dispose()


def create_app() -> FastAPI:
    """Create a configured Suri API without starting infrastructure at import time."""
    if settings.CORS_ALLOW_CREDENTIALS and "*" in settings.CORS_ORIGINS:
        raise ValueError(
            "CORS_ORIGINS cannot contain '*' when CORS_ALLOW_CREDENTIALS is enabled."
        )

    app = FastAPI(
        title="Suri",
        description=(
            "AI-powered wound-risk assessment API.  "
            "Upload one or more wound images along with patient context "
            "to receive a risk classification and confidence score."
        ),
        version="0.1.0",
        lifespan=lifespan,
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=settings.CORS_ALLOW_CREDENTIALS,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    register_exception_handlers(app)
    app.include_router(health_router)
    app.include_router(auth_router, prefix="/auth", tags=["auth"])
    app.include_router(wound_router, prefix="/wound", tags=["wound"])
    app.include_router(chatbot_router, prefix="/chatbot", tags=["chatbot"])
    app.include_router(
        medical_facilities_router,
        prefix="/medical-facilities",
        tags=["medical-facilities"],
    )
    return app


app = create_app()
