import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/app_nav_bar.dart';
import '../widgets/daily_wellness_card.dart';
import '../widgets/home_feature_card.dart';
import '../widgets/recent_assessments_section.dart';
import '../widgets/symptom_input_card.dart';

/// Redesigned Home page matching the reference UI.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final token = ref.watch(currentTokenProvider) ?? '';
    final firstName = _firstName(user?.fullName);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Sticky navbar ──────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: AppNavBar(),
            ),

            // ── Scrollable content ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xl),

                    // ── Greeting ─────────────────────────────────────────
                    _GreetingHeader(firstName: firstName),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Symptom input card ───────────────────────────────
                    SymptomInputCard(
                      token: token,
                      onSend: (_) => context.push(RoutePaths.assessmentSelection),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Feature cards ───────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: HomeFeatureCard(
                            gradientColors: const [
                              Color(0xFFE8F5E9),
                              Color(0xFFD0F0E8),
                            ],
                            iconWidget: const _WoundIcon(),
                            title: 'Analyze a wound',
                            subtitle:
                                'Get AI-powered insights\nand care recommendations',
                            onTap: () => context.push(RoutePaths.assessmentSelection),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: HomeFeatureCard(
                            gradientColors: const [
                              Color(0xFFEDE7F6),
                              Color(0xFFD8D4F5),
                            ],
                            iconWidget: const _HeartbeatIcon(),
                            title: 'Check my symptoms',
                            subtitle:
                                'Understand possible\ncauses and next steps',
                            onTap: () => context.push(RoutePaths.assessmentSelection),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Daily wellness tip ───────────────────────────────
                    const DailyWellnessCard(),
                    const SizedBox(height: AppSpacing.xxl),

                    // ── Recent assessments ───────────────────────────────
                    RecentAssessmentsSection(
                      onViewAll: () => context.go(RoutePaths.assessments),
                    ),
                    // Extra bottom padding so content clears the floating nav bar
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _firstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return 'there';
    return fullName.trim().split(RegExp(r'\s+')).first;
  }
}

// ── Greeting header ──────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  final String firstName;

  const _GreetingHeader({required this.firstName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            children: [
              TextSpan(text: 'Hello, $firstName '),
              const TextSpan(text: '👋'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'How can I help you feel better today?',
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}


// ── Wound icon illustration ───────────────────────────────────────────────────

class _WoundIcon extends StatelessWidget {
  const _WoundIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFB8E0C8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.healing_rounded,
        color: Color(0xFF2E7D56),
        size: 28,
      ),
    );
  }
}

// ── Heartbeat icon illustration ───────────────────────────────────────────────

class _HeartbeatIcon extends StatelessWidget {
  const _HeartbeatIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFC9BDEE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.favorite_rounded,
        color: Color(0xFF5C35C9),
        size: 28,
      ),
    );
  }
}
