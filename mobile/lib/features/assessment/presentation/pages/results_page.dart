import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../../../shared/widgets/danger_button.dart';
import '../../../../shared/widgets/outlined_button_widget.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../providers/assessment_provider.dart';
import '../widgets/ai_reasoning_section.dart';
import '../widgets/condition_list_item.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/urgency_score_card.dart';

/// Results / Assessment Ready page (Screen 5).
class ResultsPage extends ConsumerStatefulWidget {
  const ResultsPage({super.key});

  @override
  ConsumerState<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends ConsumerState<ResultsPage> {
  bool _showAllRules = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentProvider);
    final assessment = state.result;

    if (assessment == null) {
      return Scaffold(
        appBar: AppTopBar(
          title: AppStrings.appName,
          stepText: AppStrings.assessmentReady,
          showBack: true,
          onBack: () =>
              context.canPop() ? context.pop() : context.go(RoutePaths.home),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final visibleRules = _showAllRules
        ? assessment.triggeredRules
        : assessment.triggeredRules.take(2).toList();
    final hiddenCount = assessment.triggeredRules.length - 2;

    return Scaffold(
      appBar: AppTopBar(
        title: AppStrings.appName,
        stepText: AppStrings.assessmentReady,
        showBack: true,
        onBack: () =>
            context.canPop() ? context.pop() : context.go(RoutePaths.home),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Urgency score card
            UrgencyScoreCard(
              score: assessment.riskScore,
              title: assessment.riskLevel,
              description: assessment.disclaimer,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Recommendation card
            RecommendationCard(
              timeframe: assessment.followUp,
              description: assessment.recommendations.isNotEmpty 
                  ? assessment.recommendations.first 
                  : 'Please consult a healthcare professional.',
              buttonLabel: AppStrings.findNearbyClinic,
              onButtonPressed: () => context.push(RoutePaths.nearbyFacilities),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Triggered Rules (Clinical Findings)
            Text("Clinical Findings", style: AppTextStyles.headingSm),
            const SizedBox(height: AppSpacing.sm),
            ...visibleRules.map((r) => ConditionListItem(
                  name: r.name,
                  description: r.reason,
                  scoreContribution: r.scoreContribution,
                )),

            // View more
            if (!_showAllRules && hiddenCount > 0)
              TextButton.icon(
                onPressed: () => setState(() => _showAllRules = true),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 20, color: AppColors.primary),
                label: Text(
                  'View $hiddenCount more findings',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xl),

            // AI Reasoning (All recommendations)
            AiReasoningSection(
              reasoningPoints: assessment.recommendations,
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButtonWidget(
                    label: AppStrings.saveAssessment,
                    icon: Icons.bookmark_outline,
                    onPressed: () => context.go(RoutePaths.assessments),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PrimaryButton(
                    label: AppStrings.bookConsult,
                    trailingIcon: Icons.calendar_month_outlined,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Emergency button (Conditionally rendered)
            if (assessment.emergency)
              DangerButton(
                label: AppStrings.callEmergency,
                icon: Icons.phone,
                onPressed: () {
                  // Launch phone dialer
                },
              ),
            if (assessment.emergency) const SizedBox(height: AppSpacing.xxl),
            
            // Padding if emergency is absent
            if (!assessment.emergency) const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
