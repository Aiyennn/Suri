import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Custom app bar used across all screens.
/// Supports back navigation, title, and step indicator.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? stepText;
  final bool showBack;
  final VoidCallback? onBack;
  final Color? titleColor;

  const AppTopBar({
    super.key,
    required this.title,
    this.stepText,
    this.showBack = false,
    this.onBack,
    this.titleColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              onPressed: onBack ?? () => Navigator.maybePop(context),
            )
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
      title: Text(
        title,
        style: AppTextStyles.headingSm.copyWith(
          color: titleColor ?? AppColors.primary,
        ),
      ),
      centerTitle: true,
      actions: stepText != null
          ? [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    stepText!,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ]
          : null,
    );
  }
}
