import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../../../shared/widgets/primary_button.dart';

/// Assessments landing page — entry point for starting a new AI wound assessment.
///
/// This page explains what an assessment involves and provides a clear
/// call-to-action to begin. Past results are accessible from the History tab.
class AssessmentsPage extends StatelessWidget {
  const AssessmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppTopBar(
        title: AppStrings.appName,
        stepText: AppStrings.assessments,
        showBack: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xxl),

            // Hero banner
            _HeroBanner(),
            const SizedBox(height: AppSpacing.xxxl),

            // Section title
            Text('Start a New Assessment', style: AppTextStyles.headingMd),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Follow three quick steps to get an AI-powered wound risk evaluation.',
              style: AppTextStyles.bodyMd,
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Steps
            _StepCard(
              step: 1,
              icon: Icons.person_outline_rounded,
              title: 'Patient Details',
              description:
                  'Enter age, sex, symptoms and relevant medical history.',
            ),
            const SizedBox(height: AppSpacing.md),
            _StepCard(
              step: 2,
              icon: Icons.camera_alt_outlined,
              title: 'Upload Images',
              description:
                  'Take or select clear photos of the wound area for AI analysis.',
            ),
            const SizedBox(height: AppSpacing.md),
            _StepCard(
              step: 3,
              icon: Icons.analytics_outlined,
              title: 'Get Results',
              description:
                  'Receive a risk assessment, recommendations and follow-up guidance.',
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // CTA
            PrimaryButton(
              label: AppStrings.startAssessment,
              trailingIcon: Icons.arrow_forward_rounded,
              onPressed: () => context.push(RoutePaths.patientDetails),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Secondary link to history
            Center(
              child: TextButton(
                onPressed: () => context.go(RoutePaths.history),
                child: Text(
                  AppStrings.viewPreviousAssessments,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.primaryLight),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'This tool supports clinical decision-making and does not '
                      'replace the judgment of a licensed healthcare professional.',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.primary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ── Hero banner ──────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A56DB), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A56DB).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    'AI POWERED',
                    style: AppTextStyles.labelSm.copyWith(
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Wound Risk\nAssessment',
                  style: AppTextStyles.headingLg.copyWith(
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Fast, accurate analysis in under 2 minutes.',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: const Icon(
              Icons.healing_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step card ────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final int step;
  final IconData icon;
  final String title;
  final String description;

  const _StepCard({
    required this.step,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Step number circle
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            alignment: Alignment.center,
            child: Text(
              '$step',
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLg),
                const SizedBox(height: 2),
                Text(description, style: AppTextStyles.bodySm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
