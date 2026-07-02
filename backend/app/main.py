"""
main.py
=======
Entry point for the Suri FastAPI application.
"""

import logging

from fastapi import FastAPI

from api.wound import router as wound_router


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

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
)

# ---------------------------------------------------------------------------
# Router registration
# ---------------------------------------------------------------------------

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
