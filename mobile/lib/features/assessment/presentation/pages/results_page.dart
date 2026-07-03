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
import '../widgets/self_care_tile.dart';
import '../widgets/urgency_score_card.dart';

/// Results / Assessment Ready page (Screen 5).
class ResultsPage extends ConsumerStatefulWidget {
  const ResultsPage({super.key});

  @override
  ConsumerState<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends ConsumerState<ResultsPage> {
  bool _showAllConditions = false;

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
          onBack: () => context.go(RoutePaths.home),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final visibleConditions = _showAllConditions
        ? assessment.conditions
        : assessment.conditions.take(2).toList();
    final hiddenCount = assessment.conditions.length - 2;

    return Scaffold(
      appBar: AppTopBar(
        title: AppStrings.appName,
        stepText: AppStrings.assessmentReady,
        showBack: true,
        onBack: () => context.go(RoutePaths.home),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Urgency score card
            UrgencyScoreCard(
              score: assessment.score,
              title: assessment.urgencyTitle,
              description: assessment.urgencyDescription,
              confidence: assessment.confidence,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Recommendation card
            RecommendationCard(
              timeframe: assessment.timeframe,
              description: assessment.recommendationDescription,
              buttonLabel: AppStrings.findNearbyClinic,
              onButtonPressed: () {
                // Open map or clinic finder
              },
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Possible Conditions
            Text(AppStrings.possibleConditions,
                style: AppTextStyles.headingSm),
            const SizedBox(height: AppSpacing.sm),
            ...visibleConditions.map((c) => ConditionListItem(
                  name: c.name,
                  description: c.description,
                  percentage: c.percentage,
                )),

            // View more
            if (!_showAllConditions && hiddenCount > 0)
              TextButton.icon(
                onPressed: () =>
                    setState(() => _showAllConditions = true),
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    size: 20, color: AppColors.primary),
                label: Text(
                  'View $hiddenCount more results',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xl),

            // AI Reasoning
            AiReasoningSection(
              reasoningPoints: assessment.reasoningPoints,
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Self-Care
            Text(AppStrings.immediateSelfCare,
                style: AppTextStyles.labelMd.copyWith(
                  letterSpacing: 1,
                  color: AppColors.textTertiary,
                )),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _buildSelfCareItems(assessment.selfCareItems),
            ),
            const SizedBox(height: AppSpacing.xxxl),

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

            // Emergency button
            DangerButton(
              label: AppStrings.callEmergency,
              icon: Icons.phone,
              onPressed: () {
                // Launch phone dialer
              },
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSelfCareItems(
      List<dynamic> items) {
    final iconMap = <String, IconData>{
      'water_drop': Icons.water_drop_outlined,
      'bed': Icons.bed_outlined,
      'thermostat': Icons.thermostat_outlined,
      'shield': Icons.shield_outlined,
    };

    return items.map((item) {
      return SelfCareTile(
        icon: iconMap[item.iconName] ?? Icons.health_and_safety_outlined,
        label: item.label,
      );
    }).toList();
  }
}
