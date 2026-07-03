import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../providers/assessment_provider.dart';
import '../widgets/analysis_step_item.dart';
import '../widgets/phase_progress_bar.dart';

/// Analyzing Data page (Screen 4).
class AnalyzingPage extends ConsumerStatefulWidget {
  const AnalyzingPage({super.key});

  @override
  ConsumerState<AnalyzingPage> createState() => _AnalyzingPageState();
}

class _AnalyzingPageState extends ConsumerState<AnalyzingPage> {
  @override
  void initState() {
    super.initState();
    // Start analysis when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnalysis();
    });
  }

  Future<void> _startAnalysis() async {
    await ref.read(assessmentProvider.notifier).startAnalysis();
    if (mounted) {
      context.go(RoutePaths.results);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentProvider);

    return Scaffold(
      appBar: AppTopBar(
        title: AppStrings.appName,
        stepText: 'Step 3 of 5',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),

                  // Title
                  Text(AppStrings.analyzingData,
                      style: AppTextStyles.headingLg),
                  const SizedBox(height: AppSpacing.sm),
                  Text(AppStrings.analyzingSubtitle,
                      style: AppTextStyles.bodyMd),
                  const SizedBox(height: AppSpacing.xxxl),

                  // Analysis steps
                  _buildStep(
                    icon: Icons.person_outline,
                    title: AppStrings.patientInformation,
                    subtitle: AppStrings.patientInfoDesc,
                    status: state.stepStatuses[AnalysisStep.patientInfo] ??
                        StepStatus.pending,
                  ),
                  _buildDivider(),
                  _buildStep(
                    icon: Icons.analytics_outlined,
                    title: AppStrings.symptomAnalysis,
                    subtitle: AppStrings.symptomAnalysisDesc,
                    status:
                        state.stepStatuses[AnalysisStep.symptomAnalysis] ??
                            StepStatus.pending,
                  ),
                  _buildDivider(),
                  _buildStep(
                    icon: Icons.image_outlined,
                    title: AppStrings.medicalImageModel,
                    subtitle: AppStrings.medicalImageDesc,
                    status:
                        state.stepStatuses[AnalysisStep.medicalImage] ??
                            StepStatus.pending,
                  ),
                  _buildDivider(),
                  _buildStep(
                    icon: Icons.speed_outlined,
                    title: AppStrings.riskScoring,
                    subtitle: AppStrings.riskScoringDesc,
                    status:
                        state.stepStatuses[AnalysisStep.riskScoring] ??
                            StepStatus.pending,
                  ),
                  _buildDivider(),
                  _buildStep(
                    icon: Icons.menu_book_outlined,
                    title: AppStrings.knowledgeBase,
                    subtitle: AppStrings.knowledgeBaseDesc,
                    status:
                        state.stepStatuses[AnalysisStep.knowledgeBase] ??
                            StepStatus.pending,
                  ),
                  _buildDivider(),
                  _buildStep(
                    icon: Icons.auto_awesome_outlined,
                    title: AppStrings.llmExplanation,
                    subtitle: AppStrings.llmExplanationDesc,
                    status:
                        state.stepStatuses[AnalysisStep.llmExplanation] ??
                            StepStatus.pending,
                  ),

                  const SizedBox(height: AppSpacing.xxxl),

                  // Progress bar
                  PhaseProgressBar(
                    progress: state.analysisProgress,
                    leftLabel: AppStrings.generatingAssessment,
                    rightLabel: AppStrings.finalizing,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Status text
                  Center(
                    child: Text(
                      AppStrings.synthesizingData,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),

          // Please Wait button
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowMedium,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: PrimaryButton(
              label: AppStrings.pleaseWait,
              trailingIcon: Icons.hourglass_empty_rounded,
              onPressed: null, // Disabled
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required StepStatus status,
  }) {
    return AnalysisStepItem(
      icon: icon,
      title: title,
      subtitle: subtitle,
      status: status,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Container(
        width: 1,
        height: 12,
        color: AppColors.cardBorder,
      ),
    );
  }
}
