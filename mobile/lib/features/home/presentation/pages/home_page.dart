import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../widgets/feature_card.dart';
import '../widgets/hero_section.dart';

/// Home / Landing page (Screen 1).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(
        title: AppStrings.home,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),
            // Hero section
            const HeroSection(),
            const SizedBox(height: AppSpacing.xxl),

            // Title
            Text(
              AppStrings.aiHealthAssessment,
              style: AppTextStyles.headingLg,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                AppStrings.homeDescription,
                style: AppTextStyles.bodyMd,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Feature cards
            Row(
              children: [
                Expanded(
                  child: FeatureCard(
                    icon: Icons.fact_check_outlined,
                    label: AppStrings.symptomChecker,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FeatureCard(
                    icon: Icons.image_search_outlined,
                    label: AppStrings.imageAnalysis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Start Assessment CTA
            PrimaryButton(
              label: AppStrings.startAssessment,
              trailingIcon: Icons.arrow_forward,
              onPressed: () => context.push(RoutePaths.patientDetails),
            ),
            const SizedBox(height: AppSpacing.lg),

            // View Previous
            TextButton(
              onPressed: () => context.go(RoutePaths.assessments),
              child: Text(
                AppStrings.viewPreviousAssessments,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Powered by
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  AppStrings.poweredBy,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
