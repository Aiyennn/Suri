import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

/// Card with a colored left border accent, used for form sections.
class SectionCard extends StatelessWidget {
  final Widget child;
  final Color accentColor;
  final EdgeInsets? padding;

  const SectionCard({
    super.key,
    required this.child,
    this.accentColor = AppColors.primary,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            constraints: const BoxConstraints(minHeight: 60),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusMd),
                bottomLeft: Radius.circular(AppSpacing.radiusMd),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: padding ??
                  const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
