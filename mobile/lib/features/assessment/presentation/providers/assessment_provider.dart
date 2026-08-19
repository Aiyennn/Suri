import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/assessment_repository_impl.dart';
import '../../domain/entities/assessment.dart';
import '../../domain/entities/assessment_history.dart';
import '../../domain/entities/patient.dart';
import '../../domain/repositories/assessment_repository.dart';
import '../../domain/usecases/run_assessment.dart';
import 'assessments_history_provider.dart';

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

  // ── Upload progress fields ─────────────────────────────────────────────
  /// Whether images are currently being uploaded to the server.
  final bool isUploading;

  /// Upload progress as a fraction in [0.0, 1.0].
  final double uploadProgress;

  /// Number of bytes sent so far during the current upload.
  final int uploadedBytes;

  /// Total number of bytes to send during the current upload.
  final int totalBytes;

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
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.uploadedBytes = 0,
    this.totalBytes = 0,
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
    bool? isUploading,
    double? uploadProgress,
    int? uploadedBytes,
    int? totalBytes,
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
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      uploadedBytes: uploadedBytes ?? this.uploadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
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
  return AssessmentNotifier(ref.read(runAssessmentUseCaseProvider), ref);
});

class AssessmentNotifier extends StateNotifier<AssessmentState> {
  final RunAssessment _runAssessment;

  /// Retained so the notifier can read [currentTokenProvider] at call-time.
  final Ref _ref;

  AssessmentNotifier(this._runAssessment, this._ref)
      : super(const AssessmentState());

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

  /// Load a historic assessment result into state to view its details.
  void setHistoryResult(AssessmentHistoryItem item) {
    final riskLevel = item.riskLevel ?? 'Moderate';
    final isEmergency = item.emergency ?? false;
    final isReferral =
        riskLevel.toLowerCase() == 'high' || riskLevel.toLowerCase() == 'critical' || isEmergency;

    final followUp = isEmergency
        ? 'Immediate Emergency Evaluation'
        : (riskLevel.toLowerCase() == 'high' || riskLevel.toLowerCase() == 'critical')
            ? 'Consult clinician within 24 hours'
            : 'Review in 3–5 days';

    final conditionName = item.woundType != null && item.woundType!.isNotEmpty
        ? item.woundType!
            .replaceAll('_', ' ')
            .split(' ')
            .map((s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1))
            .join(' ')
        : 'Clinical Assessment';

    final recommendations = <String>[
      if (isEmergency)
        'Seek immediate emergency medical attention.'
      else if (riskLevel.toLowerCase() == 'high' || riskLevel.toLowerCase() == 'critical')
        'Schedule an urgent consultation with a qualified medical specialist.'
      else
        'Maintain clean dressing and monitor for any signs of worsening infection or inflammation.',
      if (item.symptoms.isNotEmpty)
        'Monitored symptoms: ${item.symptoms.join(', ')}.',
      'Seek formal medical review if symptoms persist beyond ${item.duration}.',
    ];

    final assessment = Assessment(
      riskScore: item.riskScore ?? 0,
      riskLevel: riskLevel,
      recommendations: recommendations,
      referralRequired: isReferral,
      emergency: isEmergency,
      followUp: followUp,
      triggeredRules: [
        TriggeredRule(
          id: item.id,
          name: conditionName,
          reason:
              'Recorded duration: ${item.duration}. Symptoms: ${item.symptoms.join(', ')}.',
          scoreContribution: item.riskScore ?? 0,
        ),
      ],
      disclaimer:
          'All health assessments and recommendations are for preliminary informational purposes only.',
    );

    state = state.copyWith(
      result: assessment,
      patient: state.patient.copyWith(
        age: int.tryParse(item.patientAge),
        sex: item.patientSex,
        symptoms: item.symptoms,
        duration: item.duration,
      ),
      isAnalyzing: false,
      isUploading: false,
      error: null,
    );
  }

  // ─── Analysis ───

  /// Run the full analysis pipeline:
  ///   Phase 1 — Upload images to the server (real progress tracking).
  ///   Phase 2 — Animate analysis steps while the API processes.
  Future<void> startAnalysis() async {
    state = state.copyWith(
      isAnalyzing: true,
      isUploading: true,
      uploadProgress: 0.0,
      uploadedBytes: 0,
      totalBytes: 0,
      analysisProgress: 0.0,
      error: null,
      stepStatuses: {
        for (final step in AnalysisStep.values) step: StepStatus.pending,
      },
    );

    try {
      // Phase 1: Upload + API analysis — real progress via callback.
      //
      // The onUploadProgress callback fires as bytes are streamed to the
      // server.  Once the upload completes, the server runs the analysis
      // pipeline and returns the result.  The analysis steps are animated
      // in parallel to give the user visual feedback during processing.
      final token = _ref.read(currentTokenProvider) ?? '';
      final analysisFuture = _runAssessment(
        patient: state.patient,
        imagePaths: state.uploadedImagePaths,
        token: token,
        onUploadProgress: (sent, total) {
          if (!mounted) return;
          final progress = total > 0 ? (sent / total).clamp(0.0, 1.0) : 0.0;
          state = state.copyWith(
            uploadProgress: progress,
            uploadedBytes: sent,
            totalBytes: total,
            // While uploading, mark upload as ongoing
            isUploading: progress < 1.0,
          );
        },
      );

      // Phase 2: Animate analysis steps while waiting for the result.
      // Start the step animation after a small delay to let upload progress
      // begin showing first.
      await Future.delayed(const Duration(milliseconds: 300));

      // Animate each step
      for (int i = 0; i < AnalysisStep.values.length; i++) {
        if (!mounted) return;
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

        if (!mounted) return;

        // Mark step as completed
        final updatedStatuses =
            Map<AnalysisStep, StepStatus>.from(state.stepStatuses);
        updatedStatuses[step] = StepStatus.completed;
        state = state.copyWith(stepStatuses: updatedStatuses);
      }

      // Final progress
      state = state.copyWith(analysisProgress: 1.0);

      // Wait for the actual API result
      final result = await analysisFuture;

      if (!mounted) return;
      state = state.copyWith(
        result: result,
        isAnalyzing: false,
        isUploading: false,
        uploadProgress: 1.0,
      );

      // Trigger a quiet revalidation of the history list
      _ref.read(assessmentsHistoryProvider.notifier).load();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        error: e.toString(),
        isAnalyzing: false,
        isUploading: false,
      );
    }
  }

  /// Reset all state for a new assessment.
  void reset() {
    state = const AssessmentState();
  }
}
