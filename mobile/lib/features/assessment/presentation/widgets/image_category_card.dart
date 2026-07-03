import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Category card for image upload (Skin, Throat, Eye, Wound).
class ImageCategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final int imageCount;
  final Color? badgeColor;
  final VoidCallback? onUpload;
  final VoidCallback? onCamera;

  const ImageCategoryCard({
    super.key,
    required this.label,
    required this.icon,
    this.imageCount = 0,
    this.badgeColor,
    this.onUpload,
    this.onCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: AppColors.primary.withValues(alpha: 0.6)),
              const SizedBox(height: AppSpacing.xs),
              Text(label, style: AppTextStyles.labelMd),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionIcon(
                    icon: Icons.upload_outlined,
                    onTap: onUpload,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _ActionIcon(
                    icon: Icons.camera_alt_outlined,
                    onTap: onCamera,
                  ),
                ],
              ),
            ],
          ),
          // Count badge
          if (imageCount > 0)
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
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ActionIcon({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }
}
