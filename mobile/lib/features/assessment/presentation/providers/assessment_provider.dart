import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/assessment_repository_impl.dart';
import '../../domain/entities/assessment.dart';
import '../../domain/entities/patient.dart';
import '../../domain/repositories/assessment_repository.dart';
import '../../domain/usecases/run_assessment.dart';

/// The current step in the analysis process (0-5).
enum AnalysisStep {
  patientInfo,
  symptomAnalysis,
  medicalImage,
  riskScoring,
  knowledgeBase,
  llmExplanation,
}

/// Status of each analysis step.
enum StepStatus { pending, running, completed }

/// Full state of the assessment flow.
class AssessmentState {
  final Patient patient;
  final List<String> uploadedImagePaths;
  final Map<String, int> categoryImageCounts;
  final int currentAnalysisStep;
  final Map<AnalysisStep, StepStatus> stepStatuses;
  final double analysisProgress;
  final Assessment? result;
  final bool isAnalyzing;
  final String? error;

  const AssessmentState({
    this.patient = const Patient(),
    this.uploadedImagePaths = const [],
    this.categoryImageCounts = const {},
    this.currentAnalysisStep = 0,
    this.stepStatuses = const {},
    this.analysisProgress = 0.0,
    this.result,
    this.isAnalyzing = false,
    this.error,
  });

  AssessmentState copyWith({
    Patient? patient,
    List<String>? uploadedImagePaths,
    Map<String, int>? categoryImageCounts,
    int? currentAnalysisStep,
    Map<AnalysisStep, StepStatus>? stepStatuses,
    double? analysisProgress,
    Assessment? result,
    bool? isAnalyzing,
    String? error,
  }) {
    return AssessmentState(
      patient: patient ?? this.patient,
      uploadedImagePaths: uploadedImagePaths ?? this.uploadedImagePaths,
      categoryImageCounts: categoryImageCounts ?? this.categoryImageCounts,
      currentAnalysisStep: currentAnalysisStep ?? this.currentAnalysisStep,
      stepStatuses: stepStatuses ?? this.stepStatuses,
      analysisProgress: analysisProgress ?? this.analysisProgress,
      result: result ?? this.result,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      error: error,
    );
  }
}

/// Repository provider.
final assessmentRepositoryProvider = Provider<AssessmentRepository>((ref) {
  return AssessmentRepositoryImpl();
});

/// Use case provider.
final runAssessmentUseCaseProvider = Provider<RunAssessment>((ref) {
  return RunAssessment(ref.read(assessmentRepositoryProvider));
});

/// Main assessment state provider.
final assessmentProvider =
    StateNotifierProvider<AssessmentNotifier, AssessmentState>((ref) {
  return AssessmentNotifier(ref.read(runAssessmentUseCaseProvider));
});

class AssessmentNotifier extends StateNotifier<AssessmentState> {
  final RunAssessment _runAssessment;

  AssessmentNotifier(this._runAssessment) : super(const AssessmentState());

  // ─── Patient Details ───

  void updateAge(int age) {
    state = state.copyWith(patient: state.patient.copyWith(age: age));
  }

  void updateSex(String sex) {
    state = state.copyWith(patient: state.patient.copyWith(sex: sex));
  }

  void addSymptom(String symptom) {
    if (!state.patient.symptoms.contains(symptom)) {
      final updated = [...state.patient.symptoms, symptom];
      state = state.copyWith(patient: state.patient.copyWith(symptoms: updated));
    }
  }

  void removeSymptom(String symptom) {
    final updated = state.patient.symptoms.where((s) => s != symptom).toList();
    state = state.copyWith(patient: state.patient.copyWith(symptoms: updated));
  }

  void updateDuration(String duration) {
    state = state.copyWith(patient: state.patient.copyWith(duration: duration));
  }

  void updateMedicalHistory(String history) {
    state = state.copyWith(
      patient: state.patient.copyWith(medicalHistory: history),
    );
  }

  // ─── Image Upload ───

  void addImage(String path, String category) {
    final updatedPaths = [...state.uploadedImagePaths, path];
    final updatedCounts = Map<String, int>.from(state.categoryImageCounts);
    updatedCounts[category] = (updatedCounts[category] ?? 0) + 1;
    state = state.copyWith(
      uploadedImagePaths: updatedPaths,
      categoryImageCounts: updatedCounts,
    );
  }

  void removeImage(int index) {
    final updatedPaths = List<String>.from(state.uploadedImagePaths);
    if (index >= 0 && index < updatedPaths.length) {
      updatedPaths.removeAt(index);
      state = state.copyWith(uploadedImagePaths: updatedPaths);
    }
  }

  void clearAllImages() {
    state = state.copyWith(
      uploadedImagePaths: [],
      categoryImageCounts: {},
    );
  }

  // ─── Analysis ───

  /// Simulate the analysis pipeline step by step.
  Future<void> startAnalysis() async {
    state = state.copyWith(
      isAnalyzing: true,
      analysisProgress: 0.0,
      stepStatuses: {
        for (final step in AnalysisStep.values) step: StepStatus.pending,
      },
    );

    // Simulate each step
    for (int i = 0; i < AnalysisStep.values.length; i++) {
      final step = AnalysisStep.values[i];

      // Mark current step as running
      final statuses = Map<AnalysisStep, StepStatus>.from(state.stepStatuses);
      statuses[step] = StepStatus.running;
      state = state.copyWith(
        stepStatuses: statuses,
        currentAnalysisStep: i,
        analysisProgress: (i / AnalysisStep.values.length),
      );

      // Simulate processing time
      await Future.delayed(Duration(milliseconds: 800 + (i * 200)));

      // Mark step as completed
      final updatedStatuses =
          Map<AnalysisStep, StepStatus>.from(state.stepStatuses);
      updatedStatuses[step] = StepStatus.completed;
      state = state.copyWith(stepStatuses: updatedStatuses);
    }

    // Final progress
    state = state.copyWith(analysisProgress: 1.0);

    // Run the actual assessment
    try {
      final result = await _runAssessment(
        patient: state.patient,
        imagePaths: state.uploadedImagePaths,
      );
      state = state.copyWith(result: result, isAnalyzing: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isAnalyzing: false);
    }
  }

  /// Reset all state for a new assessment.
  void reset() {
    state = const AssessmentState();
  }
}
