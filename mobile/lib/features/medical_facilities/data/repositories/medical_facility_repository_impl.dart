import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/medical_facility.dart';
import '../../domain/repositories/medical_facility_repository.dart';

/// HTTP implementation of [MedicalFacilityRepository].
///
/// Calls GET /medical-facilities/nearby on the Suri FastAPI backend,
/// which in turn queries the public Overpass API.
///
/// Follows the same pattern as [AssessmentRepositoryImpl]:
///  - uses [ApiConstants.baseUrl]
///  - sends a JWT Bearer token
///  - throws plain [Exception] on failure (let the provider catch it)
class MedicalFacilityRepositoryImpl implements MedicalFacilityRepository {
  @override
  Future<List<MedicalFacility>> getNearbyFacilities({
    required double lat,
    required double lng,
    required int radiusMetres,
    required String token,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.nearbyFacilities}')
        .replace(queryParameters: {
      'lat': lat.toString(),
      'lng': lng.toString(),
      'radius': radiusMetres.toString(),
    });

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      String detail;
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        detail = body['detail']?.toString() ?? response.body;
      } catch (_) {
        detail = response.body;
      }
      throw Exception(
        'Failed to fetch nearby facilities (${response.statusCode}): $detail',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['facilities'] as List<dynamic>? ?? [];
    return list
        .map((e) => MedicalFacility.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
