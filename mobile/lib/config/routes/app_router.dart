import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/assessment/presentation/pages/analyzing_page.dart';
import '../../features/assessment/presentation/pages/patient_details_page.dart';
import '../../features/assessment/presentation/pages/results_page.dart';
import '../../features/assessment/presentation/pages/upload_images_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/shell/presentation/pages/shell_page.dart';

/// Route paths.
abstract final class RoutePaths {
  static const String home = '/';
  static const String assessments = '/assessments';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String patientDetails = '/assessment/patient-details';
  static const String uploadImages = '/assessment/upload-images';
  static const String analyzing = '/assessment/analyzing';
  static const String results = '/assessment/results';
}

/// GoRouter configuration provider.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.home,
    routes: [
      // Shell route for bottom nav
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
              child: _PlaceholderPage(title: 'Assessments'),
            ),
          ),
          GoRoute(
            path: RoutePaths.history,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _PlaceholderPage(title: 'History'),
            ),
          ),
          GoRoute(
            path: RoutePaths.profile,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _PlaceholderPage(title: 'Profile'),
            ),
          ),
        ],
      ),
      // Assessment flow (no bottom nav)
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

/// Placeholder page for stub tabs.
class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            Text(
              'Coming soon',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}
