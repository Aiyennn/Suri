import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../../domain/entities/assessment.dart';
import '../../domain/entities/patient.dart';
import '../../domain/repositories/assessment_repository.dart';

/// Real implementation that sends patient data + wound image to the backend
/// wound-analysis API and deserializes the returned JSON into an [Assessment].
class AssessmentRepositoryImpl implements AssessmentRepository {
  // ─── Configuration ───────────────────────────────────────────────────────

  /// Base URL for the Suri backend.
  static const String _baseUrl = 'http://localhost:8000';

  /// Wound analysis endpoint.
  static const String _woundEndpoint = '/wound/analyze';

  final http.Client _client;

  AssessmentRepositoryImpl({http.Client? client})
      : _client = client ?? http.Client();

  // ─── Public API ──────────────────────────────────────────────────────────

  @override
  Future<Assessment> runAssessment({
    required Patient patient,
    required List<String> imagePaths,
  }) async {
    final uri = Uri.parse('$_baseUrl$_woundEndpoint');

    // 1. Build a multipart POST request.
    final request = http.MultipartRequest('POST', uri);

    // 2. Attach structured text fields from the Patient entity.
    //    symptoms is sent as a JSON-encoded array of strings.
    request.fields.addAll({
      'age': patient.age?.toString() ?? '',
      'sex': patient.sex ?? '',
      'symptoms': jsonEncode(patient.symptoms), // ["pain", "redness", ...]
      'duration': patient.duration ?? '',
      'medical_history': patient.medicalHistory ?? '',
    });

    // 3. Attach each uploaded image file as a binary stream.
    //    The backend expects the field key to be "images".
    for (final path in imagePaths) {
      final imageFile = await http.MultipartFile.fromPath(
        'images', // field key – matches what the backend parser reads
        path,
      );
      request.files.add(imageFile);
    }

    // ─── DEBUG LOGGING ─────────────────────────────────────────────────────

    print('========== WOUND ANALYSIS REQUEST ==========');
    print('URL: ${request.url}');
    print('Method: ${request.method}');

    print('Fields:');
    request.fields.forEach((key, value) {
      print('  $key: $value');
    });

    print('Files:');
    for (final file in request.files) {
      print(
        '  field=${file.field}, '
        'filename=${file.filename}, '
        'length=${file.length}',
      );
    }

    final debugRequest = {
      'url': request.url.toString(),
      'method': request.method,
      'fields': request.fields,
      'files': request.files
          .map(
            (file) => {
              'field': file.field,
              'filename': file.filename,
              'length': file.length,
            },
          )
          .toList(),
    };

    print(
      const JsonEncoder.withIndent('  ').convert(debugRequest),
    );

    print('============================================');

    // 4. Send the request and await the complete response.
    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    // 5. Handle non-2xx status codes as exceptions.
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Wound analysis API error ${response.statusCode}: ${response.body}',
      );
    }

    // 6. Decode the JSON response and map it to the Assessment domain entity.
    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;

    return Assessment.fromJson(json);
  }
}
