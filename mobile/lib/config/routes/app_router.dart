import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/assessment/presentation/pages/analyzing_page.dart';
import '../../features/assessment/presentation/pages/assessment_selection_page.dart';
import '../../features/assessment/presentation/pages/assessments_page.dart';
import '../../features/assessment/presentation/pages/history_page.dart';
import '../../features/assessment/presentation/pages/patient_details_page.dart';
import '../../features/assessment/presentation/pages/results_page.dart';
import '../../features/assessment/presentation/pages/upload_images_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/shell/presentation/pages/shell_page.dart';

/// Route paths.
abstract final class RoutePaths {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/';
  static const String assessments = '/assessments';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String clinic = '/clinic';
  static const String assessmentSelection = '/assessment/select';
  static const String patientDetails = '/assessment/patient-details';
  static const String uploadImages = '/assessment/upload-images';
  static const String analyzing = '/assessment/analyzing';
  static const String results = '/assessment/results';
}

/// Routes that don't require authentication.
const _publicRoutes = {RoutePaths.login, RoutePaths.register};

/// GoRouter configuration provider.
///
/// Uses [RouterNotifier] to safely bridge Riverpod auth state into
/// GoRouter's [refreshListenable] without calling ref.listen inside
/// a non-widget context.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider.notifier);

  return GoRouter(
    initialLocation: RoutePaths.home,
    refreshListenable: notifier,

    // ── Redirect guard ─────────────────────────────────────────────────────
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isPublic = _publicRoutes.contains(state.matchedLocation);

      // Still checking stored token — don't redirect yet.
      if (authState is AuthLoading) return null;

      final isAuthed = authState is AuthAuthenticated;

      // Unauthenticated user on a protected route → send to login.
      if (!isAuthed && !isPublic) return RoutePaths.login;

      // Authenticated user visiting login/register → send home.
      if (isAuthed && isPublic) return RoutePaths.home;

      return null;
    },

    routes: [
      // ── Auth routes (no shell / no bottom nav) ─────────────────────────
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterPage(),
      ),

      // ── Shell route for bottom nav ─────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => ShellPage(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            path: RoutePaths.assessments,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AssessmentsPage(),
            ),
          ),
          GoRoute(
            path: RoutePaths.history,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HistoryPage(),
            ),
          ),
          GoRoute(
            path: RoutePaths.clinic,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _PlaceholderPage(title: 'Clinic'),
            ),
          ),
        ],
      ),

      // ── Assessment flow (no bottom nav) ─────────────────────────────────
      GoRoute(
        path: RoutePaths.assessmentSelection,
        builder: (context, state) => const AssessmentSelectionPage(),
      ),
      GoRoute(
        path: RoutePaths.patientDetails,
        builder: (context, state) => const PatientDetailsPage(),
      ),
      GoRoute(
        path: RoutePaths.uploadImages,
        builder: (context, state) => const UploadImagesPage(),
      ),
      GoRoute(
        path: RoutePaths.analyzing,
        builder: (context, state) => const AnalyzingPage(),
      ),
      GoRoute(
        path: RoutePaths.results,
        builder: (context, state) => const ResultsPage(),
      ),
    ],
  );
});

// ── Router notifier ──────────────────────────────────────────────────────────

/// Internal provider that bridges [authProvider] changes to GoRouter's
/// [refreshListenable] using a proper [Notifier] — this avoids the crash
/// caused by calling ref.listen inside a plain Provider body.
final _routerNotifierProvider =
    NotifierProvider<RouterNotifier, void>(RouterNotifier.new);

class RouterNotifier extends Notifier<void> implements Listenable {
  VoidCallback? _routerListener;

  @override
  void build() {
    // Watch the auth provider so this notifier rebuilds on auth changes,
    // which in turn calls notifyListeners() → GoRouter re-evaluates redirect.
    ref.listen<AuthState>(authProvider, (_, _) {
      _routerListener?.call();
    });
  }

  @override
  void addListener(VoidCallback listener) {
    _routerListener = listener;
  }

  @override
  void removeListener(VoidCallback listener) {
    _routerListener = null;
  }
}

// ── Placeholder page ──────────────────────────────────────────────────────────

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction_rounded, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text('Coming soon', style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }
}
