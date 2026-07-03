import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/assessment.dart';
import '../../domain/entities/patient.dart';
import '../../domain/repositories/assessment_repository.dart';

/// Real implementation that sends patient data + images to the backend API
/// and deserializes the returned JSON into an [Assessment] entity.
class AssessmentRepositoryImpl implements AssessmentRepository {
  // ─── Configuration ───────────────────────────────────────────────────────

  /// Base URL for the Suri backend. Override this per environment.
  static const String _baseUrl = 'https://api.suri-health.com';

  /// Endpoint that accepts the multipart assessment submission.
  static const String _assessmentEndpoint = '/v1/assessments';

  /// Optional: bearer token for authenticated requests.
  /// Replace with a real token retrieval mechanism (e.g., secure storage).
  static const String? _bearerToken = null;

  final http.Client _client;

  AssessmentRepositoryImpl({http.Client? client})
      : _client = client ?? http.Client();

  // ─── Public API ──────────────────────────────────────────────────────────

  @override
  Future<Assessment> runAssessment({
    required Patient patient,
    required List<String> imagePaths,
  }) async {
    final uri = Uri.parse('$_baseUrl$_assessmentEndpoint');

    // 1. Build a multipart POST request.
    final request = http.MultipartRequest('POST', uri);

    // 2. Attach authorization header (if configured).
    if (_bearerToken != null) {
      request.headers['Authorization'] = 'Bearer $_bearerToken';
    }

    // 3. Attach structured text fields from the Patient entity.
    //    All values are converted to strings since form fields are plain text.
    request.fields.addAll({
      'age': patient.age?.toString() ?? '',
      'sex': patient.sex ?? '',
      'symptoms': jsonEncode(patient.symptoms), // e.g. ["Fever","Cough"]
      'duration': patient.duration ?? '',
      'medical_history': patient.medicalHistory ?? '',
    });

    // 4. Attach each uploaded image file as a binary stream.
    //    The backend expects the field key to be "images" (repeatable).
    for (final path in imagePaths) {
      final imageFile = await http.MultipartFile.fromPath(
        'images', // field key – matches what the backend parser reads
        path,
      );
      request.files.add(imageFile);
    }

    // 5. Send the request and await the complete response.
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    // 6. Handle non-2xx status codes as exceptions so the provider
    //    can display an appropriate error message in the UI.
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Assessment API error ${response.statusCode}: ${response.body}',
      );
    }

    // 7. Decode the JSON response and map it to the Assessment domain entity.
    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;

    return Assessment.fromJson(json);
  }
}
