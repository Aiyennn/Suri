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

class AssessmentsHistoryState {
  final List<AssessmentHistoryItem> items;
  final int total;
  final bool isLoading;
  final bool isRevalidating;
  final String? error;
  final bool hasLoadedOnce;

  const AssessmentsHistoryState({
    this.items = const [],
    this.total = 0,
    this.isLoading = false,
    this.isRevalidating = false,
    this.error,
    this.hasLoadedOnce = false,
  });

  bool get isEmpty => hasLoadedOnce && items.isEmpty;
  bool get hasData => items.isNotEmpty;
  bool get hasError => error != null && items.isEmpty;

  AssessmentsHistoryState copyWith({
    List<AssessmentHistoryItem>? items,
    int? total,
    bool? isLoading,
    bool? isRevalidating,
    String? error,
    bool? hasLoadedOnce,
    bool clearError = false,
  }) {
    return AssessmentsHistoryState(
      items: items ?? this.items,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isRevalidating: isRevalidating ?? this.isRevalidating,
      error: clearError ? null : (error ?? this.error),
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────────────────

class AssessmentsHistoryNotifier
    extends StateNotifier<AssessmentsHistoryState> {
  final AssessmentsHistoryRepository _repo;

  /// [Ref] is retained so the notifier can read [currentTokenProvider]
  /// at call-time, picking up the latest token even after a token refresh.
  final Ref _ref;

  AssessmentsHistoryNotifier(this._repo, this._ref)
      : super(const AssessmentsHistoryState());

  /// Stale-while-revalidate load:
  /// - If data is already cached, keeps existing data visible and revalidates in the background.
  /// - Only shows full loading indicator on the very first fetch when no cache exists.
  /// - Only updates state/re-renders if incoming data differs from existing data.
  Future<void> load({bool forceRefresh = false}) async {
    if (state.hasLoadedOnce && !forceRefresh) {
      return;
    }

    final hasExistingData = state.hasData || state.hasLoadedOnce;

    if (!hasExistingData) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(isRevalidating: true);
    }

    try {
      final token = _ref.read(currentTokenProvider) ?? '';
      final result = await _repo.fetchAssessments(token: token);

      final newItems = result.assessments;
      final newTotal = result.total;

      final bool hasChanged = _hasDataChanged(state.items, newItems, state.total, newTotal);

      if (hasChanged || !state.hasLoadedOnce) {
        state = state.copyWith(
          items: newItems,
          total: newTotal,
          isLoading: false,
          isRevalidating: false,
          hasLoadedOnce: true,
          clearError: true,
        );
      } else {
        // Data is identical: quietly stop revalidating without replacing items list
        state = state.copyWith(
          isLoading: false,
          isRevalidating: false,
          hasLoadedOnce: true,
        );
      }
    } catch (e) {
      // If cached data exists, preserve it gracefully during background errors
      if (hasExistingData) {
        state = state.copyWith(
          isLoading: false,
          isRevalidating: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isRevalidating: false,
          error: e.toString(),
          hasLoadedOnce: true,
        );
      }
    }
  }

  Future<void> refresh() => load(forceRefresh: true);

  bool _hasDataChanged(
    List<AssessmentHistoryItem> current,
    List<AssessmentHistoryItem> incoming,
    int currentTotal,
    int incomingTotal,
  ) {
    if (current.length != incoming.length || currentTotal != incomingTotal) {
      return true;
    }
    for (int i = 0; i < current.length; i++) {
      if (current[i] != incoming[i]) {
        return true;
      }
    }
    return false;
  }
}

// ── Provider ─────────────────────────────────────────────────────────────

final assessmentsHistoryProvider = StateNotifierProvider<
    AssessmentsHistoryNotifier, AssessmentsHistoryState>((ref) {
  return AssessmentsHistoryNotifier(
    ref.read(assessmentsHistoryRepositoryProvider),
    ref,
  );
});
