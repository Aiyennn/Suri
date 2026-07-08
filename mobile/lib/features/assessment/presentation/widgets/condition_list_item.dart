import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Rule row with name, reason, and score contribution.
class ConditionListItem extends StatelessWidget {
  final String name;
  final String description;
  final int scoreContribution;

  const ConditionListItem({
    super.key,
    required this.name,
    required this.description,
    required this.scoreContribution,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          // Rule info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.labelLg),
                Text(description, style: AppTextStyles.bodySm),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Score contribution
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.errorLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '+$scoreContribution',
              style: AppTextStyles.labelLg.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
