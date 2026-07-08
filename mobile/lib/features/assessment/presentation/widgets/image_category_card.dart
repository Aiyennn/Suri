import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Category card for image upload (Skin, Throat, Eye, Wound).
///
/// When [disabled] is true the card is greyed-out and non-interactive,
/// but the icons remain visible as required.
class ImageCategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final int imageCount;
  final Color? badgeColor;
  final VoidCallback? onUpload;
  final VoidCallback? onCamera;
  final bool disabled;

  const ImageCategoryCard({
    super.key,
    required this.label,
    required this.icon,
    this.imageCount = 0,
    this.badgeColor,
    this.onUpload,
    this.onCamera,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.45 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: disabled ? AppColors.surface.withValues(alpha: 0.6) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: AppColors.primary.withValues(alpha: disabled ? 0.3 : 0.6)),
                const SizedBox(height: AppSpacing.xs),
                Text(label, style: AppTextStyles.labelMd),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionIcon(
                      icon: Icons.upload_outlined,
                      onTap: disabled ? null : onUpload,
                      disabled: disabled,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _ActionIcon(
                      icon: Icons.camera_alt_outlined,
                      onTap: disabled ? null : onCamera,
                      disabled: disabled,
                    ),
                  ],
                ),
              ],
            ),
            // Count badge (only for active cards)
            if (imageCount > 0 && !disabled)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: badgeColor ?? AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$imageCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            // "Not available" lock overlay
            if (disabled)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  const _ActionIcon({required this.icon, this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: disabled
              ? AppColors.cardBorder.withValues(alpha: 0.5)
              : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: disabled
              ? AppColors.textSecondary.withValues(alpha: 0.4)
              : AppColors.primary,
        ),
      ),
    );
  }
}
