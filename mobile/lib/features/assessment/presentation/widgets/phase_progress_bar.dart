import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Multi-phase animated progress bar.
class PhaseProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String leftLabel;
  final String rightLabel;

  const PhaseProgressBar({
    super.key,
    required this.progress,
    required this.leftLabel,
    required this.rightLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Phase labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              leftLabel,
              style: AppTextStyles.labelMd.copyWith(
                color: progress >= 0.5
                    ? AppColors.primary
                    : AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              rightLabel,
              style: AppTextStyles.labelMd.copyWith(
                color: progress >= 0.9
                    ? AppColors.primary
                    : AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.primaryLight,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}
