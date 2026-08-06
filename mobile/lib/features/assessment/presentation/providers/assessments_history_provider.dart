import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/assessments_history_repository.dart';
import '../../domain/entities/assessment_history.dart';

// ── Repository provider ───────────────────────────────────────────────────

final assessmentsHistoryRepositoryProvider =
    Provider<AssessmentsHistoryRepository>((ref) {
  return AssessmentsHistoryRepository();
});

// ── State ─────────────────────────────────────────────────────────────────

sealed class AssessmentsHistoryState {
  const AssessmentsHistoryState();
}

class AssessmentsHistoryInitial extends AssessmentsHistoryState {
  const AssessmentsHistoryInitial();
}

class AssessmentsHistoryLoading extends AssessmentsHistoryState {
  const AssessmentsHistoryLoading();
}

class AssessmentsHistoryLoaded extends AssessmentsHistoryState {
  final List<AssessmentHistoryItem> items;
  final int total;
  const AssessmentsHistoryLoaded({required this.items, required this.total});
}

class AssessmentsHistoryError extends AssessmentsHistoryState {
  final String message;
  const AssessmentsHistoryError(this.message);
}

// ── Notifier ─────────────────────────────────────────────────────────────

class AssessmentsHistoryNotifier
    extends StateNotifier<AssessmentsHistoryState> {
  final AssessmentsHistoryRepository _repo;

  /// [Ref] is retained so the notifier can read [currentTokenProvider]
  /// at call-time, picking up the latest token even after a token refresh.
  final Ref _ref;

  AssessmentsHistoryNotifier(this._repo, this._ref)
      : super(const AssessmentsHistoryInitial());

  Future<void> load() async {
    state = const AssessmentsHistoryLoading();
    try {
      final token = _ref.read(currentTokenProvider) ?? '';
      final result = await _repo.fetchAssessments(token: token);
      state = AssessmentsHistoryLoaded(
        items: result.assessments,
        total: result.total,
      );
    } catch (e) {
      state = AssessmentsHistoryError(e.toString());
    }
  }

  Future<void> refresh() => load();
}

// ── Provider ─────────────────────────────────────────────────────────────

final assessmentsHistoryProvider = StateNotifierProvider<
    AssessmentsHistoryNotifier, AssessmentsHistoryState>((ref) {
  return AssessmentsHistoryNotifier(
    ref.read(assessmentsHistoryRepositoryProvider),
    ref,
  );
});
