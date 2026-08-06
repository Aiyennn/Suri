import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Shared app bar used across all screens.
///
/// Behaviour:
///   - Shell screens (`showBack = false`):
///       no leading widget │ page title centred │ profile avatar on right
///   - Sub-screens (`showBack = true`):
///       back button on left │ page title centred │ optional step text on right
class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
        if (!showBack)
          // Profile avatar bubble — shown on all shell screens
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _ProfileAvatar(ref: ref),
          )
        else if (stepText != null)
          // Step indicator on sub-screens
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

// ── Profile avatar ────────────────────────────────────────────────────────────

/// Circular avatar that shows the user's initials (or a person icon as
/// fallback).  Reads the current user from [currentUserProvider].
class _ProfileAvatar extends StatelessWidget {
  final WidgetRef ref;

  const _ProfileAvatar({required this.ref});

  /// Returns up to two uppercase initials from [fullName].
  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final initials = user != null ? _initials(user.fullName) : '';

    return Semantics(
      label: 'Profile',
      button: true,
      child: GestureDetector(
        onTap: () {
          // Wire to profile route when Profile page is implemented.
        },
        child: CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary,
          child: initials.isNotEmpty
              ? Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                )
              : const Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}
