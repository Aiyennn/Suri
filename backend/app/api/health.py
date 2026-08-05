import logging

from fastapi import APIRouter

router = APIRouter()
logger = logging.getLogger(__name__)


@router.get("/", tags=["health"])
def health_check():
    return {"status": "ok"}
