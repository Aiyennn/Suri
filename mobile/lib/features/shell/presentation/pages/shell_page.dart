import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import 'package:mobile/features/assessment/presentation/providers/assessments_history_provider.dart';

/// Shell page that wraps tab content with the BottomNavBar.
class ShellPage extends ConsumerWidget {
  final Widget child;

  const ShellPage({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(RoutePaths.assessments)) return 1;
    if (location.startsWith(RoutePaths.history)) return 2;
    if (location.startsWith(RoutePaths.clinic)) return 3;
    return 0;
  }

  void _onTap(BuildContext context, WidgetRef ref, int index) {
    if (index == 0 || index == 2) {
      // Quietly refresh history when navigating to Home or History tabs
      ref.read(assessmentsHistoryProvider.notifier).load();
    }
    switch (index) {
      case 0:
        context.go(RoutePaths.home);
      case 1:
        context.go(RoutePaths.assessments);
      case 2:
        context.go(RoutePaths.history);
      case 3:
        context.go(RoutePaths.clinic);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: child,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex(context),
        onTap: (index) => _onTap(context, ref, index),
      ),
    );
  }
}
