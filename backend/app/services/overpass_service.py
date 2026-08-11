"""
services/overpass_service.py
=============================
Thin async HTTP client that talks to the public Overpass API.

This module is responsible for one thing only: issuing Overpass QL queries
and returning the raw JSON response.  All normalisation, validation, and
business logic lives in ``medical_facility_service.py``.

The Overpass API endpoint is configurable via ``settings.OVERPASS_URL`` so
it can be pointed at a self-hosted instance in production without code changes.
"""

from __future__ import annotations

import logging

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Overpass QL template
# ---------------------------------------------------------------------------

_OVERPASS_QUERY_TEMPLATE = """
[out:json][timeout:{timeout}];
(
  node[amenity=hospital](around:{radius},{lat},{lng});
  node[amenity=clinic](around:{radius},{lat},{lng});
  node[amenity=doctors](around:{radius},{lat},{lng});
  node[amenity=pharmacy](around:{radius},{lat},{lng});
  node[healthcare](around:{radius},{lat},{lng});
  way[amenity=hospital](around:{radius},{lat},{lng});
  way[amenity=clinic](around:{radius},{lat},{lng});
  way[amenity=doctors](around:{radius},{lat},{lng});
  way[healthcare](around:{radius},{lat},{lng});
);
out center;
"""


class OverpassService:
    """
    Async client for the Overpass API.

    All HTTP errors are surfaced as plain ``httpx`` exceptions and allowed
    to propagate; the calling service layer handles retries / error mapping.
    """

    def __init__(self) -> None:
        self._url = settings.OVERPASS_URL
        self._timeout = settings.OVERPASS_TIMEOUT_SECONDS

    async def query_nearby(
        self,
        lat: float,
        lng: float,
        radius: int,
    ) -> dict:
        """
        Query the Overpass API for healthcare facilities near the given point.

        Parameters
        ----------
        lat:
            WGS84 latitude of the search centre.
        lng:
            WGS84 longitude of the search centre.
        radius:
            Search radius in metres.

        Returns
        -------
        dict
            Raw Overpass JSON response body (deserialized).

        Raises
        ------
        httpx.HTTPStatusError
            If the Overpass API returns a non-2xx status code.
        httpx.TimeoutException
            If the request exceeds ``OVERPASS_TIMEOUT_SECONDS``.
        httpx.RequestError
            On any other network-level failure.
        """
        query = _OVERPASS_QUERY_TEMPLATE.format(
            timeout=self._timeout - 5,  # Overpass internal timeout slightly shorter
            radius=radius,
            lat=lat,
            lng=lng,
        )

        logger.debug(
            "Querying Overpass API [radius=%dm, url=%s]",
            radius,
            self._url,
        )

        async with httpx.AsyncClient(timeout=self._timeout) as client:
            response = await client.post(
                self._url,
                data={"data": query},
                headers={
                    "Accept": "application/json",
                    # Overpass API requires a descriptive User-Agent per usage policy.
                    "User-Agent": "SuriMedicalApp/1.0",
                },
            )
            response.raise_for_status()
            result: dict = response.json()

        logger.debug(
            "Overpass returned %d elements",
            len(result.get("elements", [])),
        )
        return result
