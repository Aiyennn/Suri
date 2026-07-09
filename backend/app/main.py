"""
main.py
=======
Entry point for the Suri FastAPI application.
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI

from api.auth import router as auth_router
from api.wound import router as wound_router
from core.database import engine, Base

# Import all models so they register with Base.metadata before create_all()
import models  # noqa: F401


logging.basicConfig(
    level=logging.DEBUG,
    format=(
        "%(asctime)s | %(levelname)-8s | "
        "%(name)s | %(funcName)s:%(lineno)d | %(message)s"
    ),
)
logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Lifespan — create tables on startup
# ---------------------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan handler.

    On startup: creates all database tables that don't already exist.
    Uses ``checkfirst=True`` (the default) so existing tables are not
    dropped or modified — only missing tables are created.
    """
    logger.info("Creating database tables (if they don't exist)…")
    Base.metadata.create_all(bind=engine)
    logger.info("Database tables ready.")
    yield


# ---------------------------------------------------------------------------
# Application
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Router registration
# ---------------------------------------------------------------------------

app.include_router(auth_router, prefix="/auth", tags=["auth"])
app.include_router(wound_router, prefix="/wound", tags=["wound"])



# ---------------------------------------------------------------------------
# Health check
# ---------------------------------------------------------------------------
@app.get("/", tags=["health"])
def health():
    """
    Infrastructure health check.

    Returns a simple JSON payload confirming the service is running.
    Used by load balancers, container orchestrators, and monitoring tools.

    Returns:
        dict: ``{"status": "ok"}``
    """
    return {"status": "ok"}
