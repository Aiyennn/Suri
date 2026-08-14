import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.api.auth import router as auth_router
from app.api.chatbot import router as chatbot_router
from app.api.health import router as health_router
from app.api.medical_facilities import router as medical_facilities_router
from app.api.wound import router as wound_router
from app.core.exception_handlers import register_exception_handlers
from app.core.logging import configure_logging

from fastapi.middleware.cors import CORSMiddleware

configure_logging()
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Application starting...")
    yield
    logger.info("Application shutting down...")


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
    allow_origins=["*"],
    allow_credentials=True,
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
