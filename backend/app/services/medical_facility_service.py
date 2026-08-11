"""
services/medical_facility_service.py
======================================
Orchestrates the nearby-facilities pipeline:

    1. Validates the caller-supplied coordinates and radius.
    2. Delegates to ``OverpassService`` to fetch raw OSM data.
    3. Normalises each element into a ``MedicalFacility`` record.
    4. Computes the Haversine distance from the query point to each facility.
    5. Sorts the results by distance (nearest first).
    6. Returns a ``NearbyFacilitiesResponse``.

Distance disclaimer
-------------------
All distances are great-circle approximations computed with the Haversine
formula.  They represent straight-line distance, not driving or walking
distance.  Proximity alone does not indicate medical suitability.

Privacy note
------------
Caller-supplied coordinates are used only to construct the Overpass query and
compute distances.  They are logged at DEBUG level only (not INFO) and are
never persisted to the database.
"""

from __future__ import annotations

import logging
import math
from typing import Optional

import httpx
from fastapi import HTTPException, status

from app.schemas.medical_facilities import MedicalFacility, NearbyFacilitiesResponse
from app.services.overpass_service import OverpassService

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Validation constants
# ---------------------------------------------------------------------------

_MIN_RADIUS_M = 100
_MAX_RADIUS_M = 50_000  # 50 km — beyond this Overpass may time out


# ---------------------------------------------------------------------------
# Haversine distance
# ---------------------------------------------------------------------------

def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Return the great-circle distance in kilometres between two WGS84 points.

    Uses the Haversine formula, which is accurate to within 0.5 % for
    distances up to a few thousand kilometres.
    """
    r = 6_371.0  # Earth's mean radius in km

    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    d_phi = math.radians(lat2 - lat1)
    d_lam = math.radians(lon2 - lon1)

    a = (
        math.sin(d_phi / 2) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(d_lam / 2) ** 2
    )
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


# ---------------------------------------------------------------------------
# OSM element normalisation helpers
# ---------------------------------------------------------------------------

def _extract_address(tags: dict) -> Optional[str]:
    """
    Assemble a best-effort address string from OSM addr:* tags.

    Returns None if no address tags are present.
    """
    parts: list[str] = []

    housenumber = tags.get("addr:housenumber", "")
    street = tags.get("addr:street", "")
    if street:
        parts.append(f"{housenumber} {street}".strip())

    city = tags.get("addr:city", "")
    if city:
        parts.append(city)

    postcode = tags.get("addr:postcode", "")
    if postcode:
        parts.append(postcode)

    return ", ".join(parts) if parts else None


def _extract_type(tags: dict) -> str:
    """Derive a facility category from the OSM amenity or healthcare tag."""
    amenity = tags.get("amenity", "")
    if amenity in {"hospital", "clinic", "doctors", "pharmacy"}:
        return amenity

    healthcare = tags.get("healthcare", "")
    if healthcare:
        return healthcare

    # Fallback — should be rare given the Overpass query filters
    return amenity or "medical_facility"


def _element_to_facility(
    element: dict,
    user_lat: float,
    user_lng: float,
) -> Optional[MedicalFacility]:
    """
    Convert one raw Overpass element to a ``MedicalFacility``.

    Returns None for elements that cannot be mapped (no usable coordinates).
    """
    tags = element.get("tags", {})
    elem_type = element.get("type", "node")
    elem_id = element.get("id", 0)

    # Resolve coordinates: nodes have lat/lon directly; ways have a centre.
    if elem_type == "node":
        lat = element.get("lat")
        lon = element.get("lon")
    else:
        # Way — Overpass "out center" adds a "center" dict.
        center = element.get("center", {})
        lat = center.get("lat")
        lon = center.get("lon")

    if lat is None or lon is None:
        logger.debug("Skipping element %s/%s — no usable coordinates", elem_type, elem_id)
        return None

    facility_type = _extract_type(tags)
    address = _extract_address(tags)
    distance_km = round(_haversine_km(user_lat, user_lng, lat, lon), 2)

    return MedicalFacility(
        id=f"{elem_type}/{elem_id}",
        name=tags.get("name") or None,
        type=facility_type,
        latitude=lat,
        longitude=lon,
        address=address,
        distance_km=distance_km,
    )


# ---------------------------------------------------------------------------
# Service class
# ---------------------------------------------------------------------------

class MedicalFacilityService:
    """
    Orchestration layer for the nearby-facilities feature.

    This class sits between the API router and ``OverpassService``.
    It owns input validation, normalisation, distance calculation, and sorting.
    """

    def __init__(self, overpass: OverpassService) -> None:
        self._overpass = overpass

    async def get_nearby_facilities(
        self,
        lat: float,
        lng: float,
        radius: int,
    ) -> NearbyFacilitiesResponse:
        """
        Return nearby medical facilities sorted by distance.

        Parameters
        ----------
        lat:
            Caller latitude. Must be in [-90, 90].
        lng:
            Caller longitude. Must be in [-180, 180].
        radius:
            Search radius in metres. Clamped to [100, 50 000].

        Returns
        -------
        NearbyFacilitiesResponse
            Sorted list of nearby facilities; may be empty.

        Raises
        ------
        HTTPException(422)
            If lat/lng are out of valid range.
        HTTPException(400)
            If the radius is out of the accepted range.
        HTTPException(503)
            If the Overpass API is unreachable or returns an error.
        """
        self._validate_coordinates(lat, lng)
        self._validate_radius(radius)

        # Coordinates are only logged at DEBUG — not INFO — to limit exposure.
        logger.debug("Nearby facilities query [radius=%dm]", radius)

        try:
            raw = await self._overpass.query_nearby(lat, lng, radius)
        except httpx.TimeoutException:
            logger.warning("Overpass API timed out [radius=%dm]", radius)
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=(
                    "The map data service did not respond in time. "
                    "Please try again or reduce the search radius."
                ),
            )
        except httpx.HTTPStatusError as exc:
            logger.warning("Overpass API returned %s", exc.response.status_code)
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="The map data service returned an error. Please try again later.",
            )
        except httpx.RequestError as exc:
            logger.warning("Overpass API network error: %s", exc)
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Could not reach the map data service. Check your network connection.",
            )
        except ValueError as exc:
            # httpx raises ValueError when .json() fails on a non-JSON body
            # (e.g. Overpass returns an HTML rate-limit page with 200 OK).
            logger.warning("Overpass API returned non-JSON response: %s", exc)
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="The map data service returned an unexpected response. Please try again later.",
            )
        except Exception as exc:
            logger.exception("Unexpected error querying Overpass API: %s", exc)
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="An unexpected error occurred while fetching nearby facilities.",
            )

        elements: list[dict] = raw.get("elements", [])

        facilities: list[MedicalFacility] = []
        for element in elements:
            facility = _element_to_facility(element, lat, lng)
            if facility is not None:
                facilities.append(facility)

        # Deduplicate by id (Overpass may occasionally return duplicates)
        seen: set[str] = set()
        unique: list[MedicalFacility] = []
        for f in facilities:
            if f.id not in seen:
                seen.add(f.id)
                unique.append(f)

        # Sort nearest first
        unique.sort(key=lambda f: f.distance_km or float("inf"))

        logger.info(
            "Nearby facilities query complete — %d results [radius=%dm]",
            len(unique),
            radius,
        )

        return NearbyFacilitiesResponse(facilities=unique)

    # ── Validation helpers ────────────────────────────────────────────────

    @staticmethod
    def _validate_coordinates(lat: float, lng: float) -> None:
        errors: list[str] = []
        if not (-90 <= lat <= 90):
            errors.append(f"lat must be in [-90, 90]; got {lat}")
        if not (-180 <= lng <= 180):
            errors.append(f"lng must be in [-180, 180]; got {lng}")
        if errors:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="; ".join(errors),
            )

    @staticmethod
    def _validate_radius(radius: int) -> None:
        if not (_MIN_RADIUS_M <= radius <= _MAX_RADIUS_M):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"radius must be between {_MIN_RADIUS_M} and {_MAX_RADIUS_M} metres; "
                    f"got {radius}"
                ),
            )
