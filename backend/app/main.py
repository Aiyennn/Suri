"""
main.py
=======
Entry point for the Suri FastAPI application.

Responsibilities:
  - Configure application-wide logging.
  - Instantiate the FastAPI app.
  - Register API routers under their respective URL prefixes.
  - Expose a health-check endpoint for infrastructure probes.

Usage (development):
    uvicorn app.main:app --reload --app-dir backend

Usage (production):
    uvicorn app.main:app --host 0.0.0.0 --port 8000
"""

import logging

from fastapi import FastAPI

from api.wound import router as wound_router

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
# Configure root logger once at startup.  Individual modules obtain a
# child logger via ``logging.getLogger(__name__)`` so log records carry the
# originating module name.
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
# All wound-analysis endpoints live under the /wound prefix.
# Example: POST /wound/analyze
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