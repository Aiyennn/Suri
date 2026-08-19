import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/assessment.dart';
import '../../domain/entities/patient.dart';
import '../../domain/repositories/assessment_repository.dart';

/// Implementation that sends patient data + wound images to the backend
/// wound-analysis API and deserializes the returned JSON into an [Assessment].
///
/// Uses [XFile.readAsBytes] and [http.MultipartFile.fromBytes] for universal
/// cross-platform compatibility across Web, Android, iOS, and Desktop.
class AssessmentRepositoryImpl implements AssessmentRepository {
  // ─── Configuration ───────────────────────────────────────────────────────

  /// Wound analysis endpoint.
  static const String _woundEndpoint = ApiConstants.woundAnalyze;

  // ─── Public API ──────────────────────────────────────────────────────────

  @override
  Future<Assessment> runAssessment({
    required Patient patient,
    required List<String> imagePaths,
    required String token,
    UploadProgressCallback? onUploadProgress,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$_woundEndpoint');

    // 1. Build a multipart request.
    final multipart = http.MultipartRequest('POST', uri);

    // 2. Attach structured text fields from the Patient entity.
    multipart.fields.addAll({
      'age': patient.age?.toString() ?? '',
      'sex': (patient.sex ?? '').toLowerCase(),
      'symptoms': jsonEncode(patient.symptoms),
      'duration': patient.duration ?? '',
      'medical_history': patient.medicalHistory ?? '',
    });

    // 3. Attach each uploaded image file using raw bytes for cross-platform support.
    int totalEstimatedBytes = 0;
    for (final path in imagePaths) {
      final xFile = XFile(path);
      final bytes = await xFile.readAsBytes();
      totalEstimatedBytes += bytes.length;

      final fileName = xFile.name.isNotEmpty
          ? xFile.name
          : (path.split(RegExp(r'[/\\]')).last.isNotEmpty
              ? path.split(RegExp(r'[/\\]')).last
              : 'wound_image.jpg');

      multipart.files.add(
        http.MultipartFile.fromBytes(
          'images',
          bytes,
          filename: fileName,
        ),
      );
    }

    if (token.isNotEmpty) {
      multipart.headers['Authorization'] = 'Bearer $token';
    }

    // Report initial progress
    onUploadProgress?.call(0, totalEstimatedBytes);

    // 4. Send request
    final streamedResponse = await multipart.send();
    onUploadProgress?.call(totalEstimatedBytes, totalEstimatedBytes);

    final response = await http.Response.fromStream(streamedResponse);

    // 5. Handle non-2xx status codes.
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Wound analysis API error ${response.statusCode}: ${response.body}',
      );
    }

    // 6. Decode the JSON response and map it to the Assessment entity.
    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;

    return Assessment.fromJson(json);
  }
}
