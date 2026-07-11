import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';

import '../../domain/entities/assessment.dart';
import '../../domain/entities/patient.dart';
import '../../domain/repositories/assessment_repository.dart';

/// Real implementation that sends patient data + wound images to the backend
/// wound-analysis API and deserializes the returned JSON into an [Assessment].
///
/// Uses [HttpClient] from `dart:io` to stream the request body and track
/// real upload progress byte-by-byte.
class AssessmentRepositoryImpl implements AssessmentRepository {
  // ─── Configuration ───────────────────────────────────────────────────────

  /// Wound analysis endpoint.
  static const String _woundEndpoint = ApiConstants.woundAnalyze;

  // ─── Public API ──────────────────────────────────────────────────────────

  @override
  Future<Assessment> runAssessment({
    required Patient patient,
    required List<String> imagePaths,
    UploadProgressCallback? onUploadProgress,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$_woundEndpoint');

    // 1. Build a multipart request to compute headers and body bytes.
    final multipart = http.MultipartRequest('POST', uri);

    // 2. Attach structured text fields from the Patient entity.
    multipart.fields.addAll({
      'age': patient.age?.toString() ?? '',
      'sex': (patient.sex ?? '').toLowerCase(),
      'symptoms': jsonEncode(patient.symptoms),
      'duration': patient.duration ?? '',
      'medical_history': patient.medicalHistory ?? '',
    });

    // 3. Attach each uploaded image file.
    for (final path in imagePaths) {
      multipart.files.add(
        await http.MultipartFile.fromPath('images', path),
      );
    }

    // ─── DEBUG LOGGING ─────────────────────────────────────────────────────

    print('========== WOUND ANALYSIS REQUEST ==========');
    print('URL: ${multipart.url}');
    print('Method: ${multipart.method}');

    print('Fields:');
    multipart.fields.forEach((key, value) {
      print('  $key: $value');
    });

    print('Files:');
    for (final file in multipart.files) {
      print(
        '  field=${file.field}, '
        'filename=${file.filename}, '
        'length=${file.length}',
      );
    }
    print('============================================');

    // 4. Finalize the multipart body to obtain the raw byte stream.
    final bodyStream = multipart.finalize();
    final totalBytes = multipart.contentLength;

    // 5. Open a raw HttpClient connection for byte-level progress tracking.
    final httpClient = HttpClient();
    try {
      final request = await httpClient.openUrl('POST', uri);

      // Copy headers from the multipart request.
      request.headers.set(
        'content-type',
        multipart.headers['content-type'] ?? 'multipart/form-data',
      );
      request.contentLength = totalBytes;

      // 6. Stream the body through, counting bytes for progress.
      int bytesSent = 0;

      // Report initial progress
      onUploadProgress?.call(0, totalBytes);

      await request.addStream(
        bodyStream.transform(
          _ProgressTransformer(
            onProgress: (chunkSize) {
              bytesSent += chunkSize;
              onUploadProgress?.call(bytesSent, totalBytes);
            },
          ),
        ),
      );

      // 7. Close the request and read the response.
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      // 8. Handle non-2xx status codes.
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Wound analysis API error ${response.statusCode}: $responseBody',
        );
      }

      // 9. Decode the JSON response and map it to the Assessment entity.
      final Map<String, dynamic> json =
          jsonDecode(responseBody) as Map<String, dynamic>;

      return Assessment.fromJson(json);
    } finally {
      httpClient.close();
    }
  }


}

/// A [StreamTransformer] that passes data through unchanged but reports
/// the size of each chunk via [onProgress].
class _ProgressTransformer extends StreamTransformerBase<List<int>, List<int>> {
  final void Function(int chunkSize) onProgress;

  const _ProgressTransformer({required this.onProgress});

  @override
  Stream<List<int>> bind(Stream<List<int>> stream) {
    return stream.map((chunk) {
      onProgress(chunk.length);
      return chunk;
    });
  }
}
