import logging

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from app.exceptions import (
    ImageQualityError,
    InternalServerError,
    InvalidImageError,
    InvalidPatientDataError,
)

logger = logging.getLogger(__name__)

async def invalid_image_handler(request: Request, exc: InvalidImageError) -> JSONResponse:

    logger.warning("InvalidImageError: %s", exc.message)
    return JSONResponse(
        status_code=422,
        content={"detail": exc.message},
    )


async def image_quality_handler(request: Request, exc: ImageQualityError) -> JSONResponse:

    logger.warning("ImageQualityError: %s", exc.reason)
    return JSONResponse(
        status_code=422,
        content={"detail": f"Image quality insufficient: {exc.reason}"},
    )


async def invalid_patient_data_handler(
    request: Request, exc: InvalidPatientDataError
) -> JSONResponse:

    logger.warning("InvalidPatientDataError: %s", exc.detail)
    return JSONResponse(
        status_code=422,
        content={"detail": exc.detail},
    )


async def internal_server_error_handler(
    request: Request, exc: InternalServerError
) -> JSONResponse:

    logger.error("InternalServerError: %s", exc)
    return JSONResponse(
        status_code=500,
        content={"detail": "An unexpected error occurred. Please try again later."},
    )

def register_exception_handlers(app: FastAPI) -> None:

    app.add_exception_handler(InvalidImageError, invalid_image_handler)
    app.add_exception_handler(ImageQualityError, image_quality_handler)
    app.add_exception_handler(InvalidPatientDataError, invalid_patient_data_handler)
    app.add_exception_handler(InternalServerError, internal_server_error_handler)
