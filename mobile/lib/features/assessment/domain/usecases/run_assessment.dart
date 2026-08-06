import '../entities/assessment.dart';
import '../entities/patient.dart';
import '../repositories/assessment_repository.dart';

/// Use case for running an AI health assessment.
class RunAssessment {
  final AssessmentRepository _repository;

  const RunAssessment(this._repository);

  Future<Assessment> call({
    required Patient patient,
    required List<String> imagePaths,
    required String token,
    UploadProgressCallback? onUploadProgress,
  }) {
    return _repository.runAssessment(
      patient: patient,
      imagePaths: imagePaths,
      token: token,
      onUploadProgress: onUploadProgress,
    );
  }
}
