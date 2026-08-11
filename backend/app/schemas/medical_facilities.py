"""
schemas/medical_facilities.py
==============================
Pydantic data-transfer objects for the /medical-facilities endpoints.

- ``NearbyFacilitiesResponse`` wraps a list of ``MedicalFacility`` records.
- ``MedicalFacility`` is a normalized, flat representation of an OSM node/way.
  All fields that may be absent in OSM data are marked Optional.
"""

from __future__ import annotations

from typing import Optional

from pydantic import BaseModel, Field


class MedicalFacility(BaseModel):
    """
    A normalized medical facility record derived from an OpenStreetMap element.

    OSM data is highly variable; many facilities lack names or addresses.
    All such fields are Optional and clients must handle None gracefully.
    """

    id: str = Field(
        description="Unique identifier constructed from the OSM element type and id."
    )
    name: Optional[str] = Field(
        None,
        description="Facility name from the OSM 'name' tag. May be absent.",
    )
    type: str = Field(
        description=(
            "Facility category derived from the OSM amenity/healthcare tag "
            "(e.g. 'hospital', 'clinic', 'doctors', 'pharmacy')."
        ),
    )
    latitude: float = Field(description="Latitude of the facility centre point.")
    longitude: float = Field(description="Longitude of the facility centre point.")
    address: Optional[str] = Field(
        None,
        description=(
            "Best-effort address assembled from OSM addr:* tags. "
            "May be absent if no address tags are present."
        ),
    )
    distance_km: Optional[float] = Field(
        None,
        description=(
            "Great-circle distance in kilometres from the queried coordinates "
            "to this facility, calculated using the Haversine formula. "
            "Displayed as approximate straight-line distance — not driving distance."
        ),
    )


class NearbyFacilitiesResponse(BaseModel):
    """
    Response body for GET /medical-facilities/nearby.

    Facilities are ordered by distance_km ascending (nearest first).
    The list may be empty if no facilities are found within the radius.

    Important: distance is a straight-line approximation only.
    Proximity alone does not indicate medical suitability.
    """

    facilities: list[MedicalFacility] = Field(
        description=(
            "Nearby medical facilities sorted by distance (nearest first). "
            "Empty list if none are found within the requested radius."
        ),
    )
