import '../entities/assessment.dart';
import '../entities/patient.dart';

/// Abstract repository interface for assessments.
abstract class AssessmentRepository {
  /// Runs the AI assessment and returns the result.
  Future<Assessment> runAssessment({
    required Patient patient,
    required List<String> imagePaths,
  });
}
