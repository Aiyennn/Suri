import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/assessment_history.dart';

/// Fetches past assessment sessions from the backend.
class AssessmentsHistoryRepository {
  final http.Client _client;

  AssessmentsHistoryRepository({http.Client? client})
      : _client = client ?? http.Client();

  Future<AssessmentHistoryResponse> fetchAssessments({
    required String token,
    int limit = 50,
    int offset = 0,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.woundAssessments}'
      '?limit=$limit&offset=$offset',
    );

    final response = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch assessments (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return AssessmentHistoryResponse.fromJson(json);
  }
}
