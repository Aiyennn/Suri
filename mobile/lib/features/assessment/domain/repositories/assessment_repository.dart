import '../entities/assessment.dart';
import '../entities/patient.dart';

/// Callback signature for upload progress updates.
///
/// [bytesSent] is the number of bytes sent so far.
/// [totalBytes] is the total number of bytes to send.
typedef UploadProgressCallback = void Function(int bytesSent, int totalBytes);

/// Abstract repository interface for assessments.
abstract class AssessmentRepository {
  /// Runs the AI assessment and returns the result.
  ///
  /// If [onUploadProgress] is provided, it will be called periodically
  /// with the number of bytes sent and total bytes as the request body
  /// streams to the server.
  Future<Assessment> runAssessment({
    required Patient patient,
    required List<String> imagePaths,
    UploadProgressCallback? onUploadProgress,
  });
}
