import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_nav_bar.dart';
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Navbar ─────────────────────────────────────────────────────
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
              onPressed: () => context.push(RoutePaths.assessmentSelection),
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
            ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: const Color(0xFFE4E9F2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top section ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Left: text content ────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Big title
                      Text(
                        'Assessment',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0D1F3C),
                          height: 1.15,
                        ),
                      ),

                      // Green accent underline
                      const SizedBox(height: 8),
                      Container(
                        width: 36,
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Description
                      Text(
                        'Evaluate skin condition, wound characteristics, and reported symptoms to identify potential concerns and risks.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Right: bandaid illustration ───────────────────────
                const SizedBox(width: AppSpacing.md),
                _BandaidIllustration(),
              ],
            ),
          ),

          // ── Divider ──────────────────────────────────────────────────
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F2F8)),

          // ── Bottom info row ──────────────────────────────────────────
          IntrinsicHeight(
            child: Row(
              children: [
                _InfoStat(
                  iconBg: const Color(0xFFEEF2FF),
                  icon: Icons.schedule_outlined,
                  iconColor: const Color(0xFF6366F1),
                  label: 'EST. TIME',
                  value: '< 2 MIN',
                  labelColor: const Color(0xFF6366F1),
                ),
                const VerticalDivider(
                    width: 1, thickness: 1, color: Color(0xFFF0F2F8)),
                _InfoStat(
                  iconBg: const Color(0xFFFFFBEB),
                  icon: Icons.verified_user_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  label: 'OUTPUT',
                  value: 'Risk Score + Plan',
                  labelColor: const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bandaid illustration ──────────────────────────────────────────────────────

class _BandaidIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        children: [
          // Outer light circle
          Container(
            width: 110,
            height: 110,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
          ),
          // Diagonal stripe accent (bottom-right)
          Positioned(
            right: 2,
            bottom: 14,
            child: Column(
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Container(
                    width: 22,
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Bandaid shape — drawn with CustomPaint
          Center(
            child: Transform.rotate(
              angle: -0.6,
              child: _BandaidShape(),
            ),
          ),
          // Decorative dots top-right
          Positioned(
            top: 6,
            right: 4,
            child: Column(
              children: List.generate(
                2,
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: List.generate(
                      3,
                      (col) => Container(
                        width: 3,
                        height: 3,
                        margin: const EdgeInsets.only(right: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981)
                              .withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BandaidShape extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1), width: 1.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Left perforated end
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (_) => Container(
                width: 3,
                height: 3,
                margin: const EdgeInsets.symmetric(vertical: 1),
                decoration: const BoxDecoration(
                  color: Color(0xFF6366F1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          // Center pad
          Container(
            width: 26,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFFBFDBFE),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.5)),
            ),
          ),
          // Right perforated end
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (_) => Container(
                width: 3,
                height: 3,
                margin: const EdgeInsets.symmetric(vertical: 1),
                decoration: const BoxDecoration(
                  color: Color(0xFF6366F1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info stat tile ────────────────────────────────────────────────────────────

class _InfoStat extends StatelessWidget {
  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color labelColor;

  const _InfoStat({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 15, color: iconColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0D1F3C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
