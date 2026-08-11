"""
api/medical_facilities.py
==========================
FastAPI router for the nearby medical-facilities endpoint.

All routes in this module are mounted under the ``/medical-facilities`` prefix
by ``main.py``, so the full path is:

    GET /medical-facilities/nearby
        – Return nearby hospitals and clinics around the caller's coordinates.

Query parameters
----------------
lat    (float, required) – Caller latitude  in [-90, 90].
lng    (float, required) – Caller longitude in [-180, 180].
radius (int,   optional) – Search radius in metres. Default 5 000. Max 50 000.

Authentication
--------------
All routes require a valid JWT Bearer token (same as every other protected
route in the application).

Important
---------
This endpoint returns straight-line distances only.  The nearest facility is
not necessarily the most appropriate one for the caller's medical situation.
The existing assessment logic determines urgency; this feature only helps
users locate physical facilities.
"""

import logging

from fastapi import APIRouter, Depends, Query

from app.models.user import User
from app.schemas.medical_facilities import NearbyFacilitiesResponse
from app.services.auth_service import get_current_user
from app.services.medical_facility_service import MedicalFacilityService
from app.services.overpass_service import OverpassService

logger = logging.getLogger(__name__)

router = APIRouter()

# Module-level service instances — constructed once, reused across requests.
# OverpassService holds no mutable state (just config), so this is safe.
_overpass_service = OverpassService()
_facility_service = MedicalFacilityService(_overpass_service)


@router.get(
    "/nearby",
    response_model=NearbyFacilitiesResponse,
    summary="Find nearby medical facilities",
    description=(
        "Return hospitals, clinics, and other healthcare facilities within the "
        "requested radius of the supplied coordinates, sourced from "
        "OpenStreetMap via the public Overpass API. "
        "Results are sorted by straight-line distance (nearest first). "
        "Proximity alone does not indicate medical suitability — always follow "
        "the assessment's urgency guidance.\n\n"
        "**Data source**: OpenStreetMap contributors (ODbL). "
        "Facility data may be incomplete or out of date."
    ),
)
async def get_nearby_facilities(
    lat: float = Query(
        ...,
        ge=-90,
        le=90,
        description="Caller latitude in decimal degrees (WGS84).",
        examples=[14.5995],
    ),
    lng: float = Query(
        ...,
        ge=-180,
        le=180,
        description="Caller longitude in decimal degrees (WGS84).",
        examples=[120.9842],
    ),
    radius: int = Query(
        default=5_000,
        ge=100,
        le=50_000,
        description="Search radius in metres. Default 5 000 m. Maximum 50 000 m.",
        examples=[5000],
    ),
    current_user: User = Depends(get_current_user),
) -> NearbyFacilitiesResponse:
    """
    Return nearby medical facilities.

    Processing:
        1. FastAPI validates lat/lng/radius via Query constraints.
        2. MedicalFacilityService performs an additional business-level check.
        3. OverpassService queries the public Overpass API.
        4. Results are normalised, distances computed, and sorted.

    Raises:
        HTTPException(422): lat or lng out of valid range.
        HTTPException(400): radius out of accepted range.
        HTTPException(503): Overpass API unavailable or timed out.
        HTTPException(401): Missing or invalid JWT token.
    """
    logger.debug(
        "Nearby facilities requested by user_id=%s [radius=%dm]",
        current_user.id,
        radius,
    )

    return await _facility_service.get_nearby_facilities(lat=lat, lng=lng, radius=radius)
