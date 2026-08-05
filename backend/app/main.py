"""
main.py
=======
Entry point for the Suri FastAPI application.

Exception handler registration
--------------------------------
Custom domain exceptions (``InvalidImageError``, ``ImageQualityError``,
``InvalidPatientDataError``, ``InternalServerError``) are translated to HTTP
responses here, at the application boundary.  This keeps the service and
repository layers free of FastAPI imports — they raise domain exceptions,
and this module maps them to the appropriate status codes and response bodies.
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from app.api.auth import router as auth_router
from app.api.wound import router as wound_router
from app.exceptions import (
    ImageQualityError,
    InternalServerError,
    InvalidImageError,
    InvalidPatientDataError,
)

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
# Exception handlers
# ---------------------------------------------------------------------------

@app.exception_handler(InvalidImageError)
async def invalid_image_handler(request: Request, exc: InvalidImageError) -> JSONResponse:
    """
    Map ``InvalidImageError`` → HTTP 422 Unprocessable Entity.

    Fires when an uploaded file cannot be decoded as a valid image.
    """
    logger.warning("InvalidImageError: %s", exc.message)
    return JSONResponse(
        status_code=422,
        content={"detail": exc.message},
    )


@app.exception_handler(ImageQualityError)
async def image_quality_handler(request: Request, exc: ImageQualityError) -> JSONResponse:
    """
    Map ``ImageQualityError`` → HTTP 422 Unprocessable Entity.

    Fires when a decoded image fails the pixel-level quality gate
    (blur, brightness, or contrast threshold not met).
    """
    logger.warning("ImageQualityError: %s", exc.reason)
    return JSONResponse(
        status_code=422,
        content={"detail": f"Image quality insufficient: {exc.reason}"},
    )


@app.exception_handler(InvalidPatientDataError)
async def invalid_patient_data_handler(
    request: Request, exc: InvalidPatientDataError
) -> JSONResponse:
    """
    Map ``InvalidPatientDataError`` → HTTP 422 Unprocessable Entity.

    Fires when patient-supplied fields fail domain validation after
    the request schema has already been accepted by FastAPI.
    """
    logger.warning("InvalidPatientDataError: %s", exc.detail)
    return JSONResponse(
        status_code=422,
        content={"detail": exc.detail},
    )


@app.exception_handler(InternalServerError)
async def internal_server_error_handler(
    request: Request, exc: InternalServerError
) -> JSONResponse:
    """
    Map ``InternalServerError`` → HTTP 500 Internal Server Error.

    Fires on unexpected errors not attributable to invalid client input.
    The response body intentionally omits internal details.
    """
    logger.error("InternalServerError: %s", exc)
    return JSONResponse(
        status_code=500,
        content={"detail": "An unexpected error occurred. Please try again later."},
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
def health_check():
    """
    Infrastructure health check.

    Returns a simple JSON payload confirming the service is running.
    Used by load balancers, container orchestrators, and monitoring tools.

    Returns:
        dict: ``{"status": "ok"}``
    """
    return {"status": "ok"}
