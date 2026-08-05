import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.api.auth import router as auth_router
from app.api.wound import router as wound_router
from app.core.exception_handlers import register_exception_handlers

logging.basicConfig(
    level=logging.DEBUG,
    format=(
        "%(asctime)s | %(levelname)-8s | "
        "%(name)s | %(funcName)s:%(lineno)d | %(message)s"
    ),
)
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

register_exception_handlers(app)

app.include_router(auth_router, prefix="/auth", tags=["auth"])
app.include_router(wound_router, prefix="/wound", tags=["wound"])


@app.get("/", tags=["health"])
def health_check():
    return {"status": "ok"}
