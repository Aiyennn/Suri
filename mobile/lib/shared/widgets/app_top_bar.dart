import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// App bar used on sub-screens (push routes) that need a back button.
///
/// Layout:
///   - back arrow on left
///   - page title centred
///   - optional step text (e.g. "Step 1 of 3") on right
///
/// Shell tab pages should use [AppNavBar] inside their body instead.
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
      automaticallyImplyLeading: false,

      // ── Leading ────────────────────────────────────────────────────────
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
              onPressed: onBack ?? () => Navigator.maybePop(context),
              tooltip: 'Back',
            )
          : null,

      // ── Title ──────────────────────────────────────────────────────────
      title: Text(
        title,
        style: AppTextStyles.headingSm.copyWith(
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      centerTitle: true,

      // ── Actions ─────────────────────────────────────────────────────────
      actions: [
        if (stepText != null)
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
      ],
    );
  }
}
