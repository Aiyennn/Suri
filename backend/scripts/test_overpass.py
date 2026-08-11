"""
End-to-end test of MedicalFacilityService with the real Overpass API.
Run from the backend directory:
    .venv\Scripts\python scripts\test_facility_service.py
"""
import asyncio
import sys
sys.path.insert(0, ".")

from app.services.medical_facility_service import MedicalFacilityService
from app.services.overpass_service import OverpassService


async def main():
    service = MedicalFacilityService(OverpassService())

    print("Querying nearby facilities for lat=15.2045, lng=120.6629, radius=5000m...")
    result = await service.get_nearby_facilities(
        lat=15.204502,
        lng=120.662876,
        radius=5000,
    )
    print(f"Found {len(result.facilities)} facilities")
    for f in result.facilities[:5]:
        print(f"  [{f.type}] {f.displayName if hasattr(f, 'displayName') else f.name or '(unnamed)'} — {f.distance_km} km")

asyncio.run(main())
