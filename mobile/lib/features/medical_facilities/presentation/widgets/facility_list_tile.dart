import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/medical_facility.dart';

/// A single row in the facilities list below the map.
class FacilityListTile extends StatelessWidget {
  final MedicalFacility facility;
  final VoidCallback? onViewTap;

  const FacilityListTile({
    super.key,
    required this.facility,
    this.onViewTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(_iconData, size: 20, color: _iconColor),
            ),
            const SizedBox(width: AppSpacing.md),

            // Name + type
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    facility.displayName,
                    style: AppTextStyles.labelLg,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        facility.typeLabel,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      if (facility.formattedDistance != null) ...[
                        Text(
                          ' · ',
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        Text(
                          facility.formattedDistance!,
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // View button
            OutlinedButton(
              onPressed: onViewTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _iconData {
    switch (facility.type.toLowerCase()) {
      case 'hospital':
        return Icons.local_hospital_rounded;
      case 'clinic':
      case 'doctors':
        return Icons.medical_services_rounded;
      case 'pharmacy':
        return Icons.medication_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  Color get _iconColor {
    switch (facility.type.toLowerCase()) {
      case 'hospital':
        return AppColors.urgencyHigh;
      case 'clinic':
      case 'doctors':
        return AppColors.primary;
      case 'pharmacy':
        return AppColors.success;
      default:
        return AppColors.secondary;
    }
  }
}
