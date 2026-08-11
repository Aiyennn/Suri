import '../../domain/entities/medical_facility.dart';

/// Abstract repository interface for the medical-facilities feature.
///
/// The domain layer depends only on this interface, keeping it decoupled
/// from HTTP or any other transport concerns.
abstract interface class MedicalFacilityRepository {
  /// Fetch nearby medical facilities from the backend.
  ///
  /// [lat] and [lng] are the user's current WGS84 coordinates.
  /// [radiusMetres] is the search radius (100–50 000 m).
  /// [token] is the JWT Bearer token for the authenticated user.
  ///
  /// Throws an [Exception] on network errors or non-2xx responses.
  Future<List<MedicalFacility>> getNearbyFacilities({
    required double lat,
    required double lng,
    required int radiusMetres,
    required String token,
  });
}
