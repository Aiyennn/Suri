import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// The shared top navbar row used across all shell (tab) pages.
///
/// Renders identically to the home page header row:
///   [avatar]  ─────────────  [🔔] [⚙]
///
/// Place this widget directly inside the page body (NOT as Scaffold.appBar)
/// so that padding, height and background are identical on every screen.
/// Wrap the host page in SafeArea and use the same horizontal padding as
/// the home page (AppSpacing.xl = 20).
class AppNavBar extends ConsumerWidget {
  const AppNavBar({super.key});

  String _initials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return '';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final initials = _initials(user?.fullName);

    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Profile avatar – far left ────────────────────────────────────
          Stack(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.primary,
                child: initials.isNotEmpty
                    ? Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.person_rounded,
                        size: 17, color: Colors.white),
              ),
              // Online dot
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // ── Notification bell – far right ────────────────────────────────
          _NavIconButton(icon: Icons.notifications_outlined, onTap: () {}),
          const SizedBox(width: 4),

          // ── Settings – far right ─────────────────────────────────────────
          _NavIconButton(icon: Icons.settings_outlined, onTap: () {}),
        ],
      ),
    );
  }
}

// ── Icon button ───────────────────────────────────────────────────────────────

class _NavIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.05),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 24,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
