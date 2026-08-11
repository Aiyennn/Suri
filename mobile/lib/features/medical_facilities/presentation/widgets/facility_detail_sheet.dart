import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/medical_facility.dart';
import '../providers/medical_facilities_provider.dart';

/// Bottom sheet that appears when a facility marker or list "View" button
/// is tapped.  Shows facility name, type, address, distance, and a
/// "Get Directions" action.
///
/// Directions open via the geo: URI scheme — no Google Maps API required.
class FacilityDetailSheet extends ConsumerWidget {
  final MedicalFacility facility;

  const FacilityDetailSheet({super.key, required this.facility});

  /// Show this sheet as a modal bottom sheet.
  static Future<void> show(BuildContext context, MedicalFacility facility) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FacilityDetailSheet(facility: facility),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Facility icon + name
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(_iconData, size: 26, color: _iconColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      facility.displayName,
                      style: AppTextStyles.headingSm,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    _TypeBadge(label: facility.typeLabel, color: _iconColor),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Info rows
          if (facility.address != null) ...[
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Address',
              value: facility.address!,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (facility.formattedDistance != null) ...[
            _InfoRow(
              icon: Icons.straighten_rounded,
              label: 'Distance',
              value:
                  '${facility.formattedDistance!} (straight-line approximation)',
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Medical safety note
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Distance is approximate. Please follow your assessment\'s '
                    'urgency guidance when choosing a facility.',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Get Directions button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ref
                    .read(medicalFacilitiesProvider.notifier)
                    .openDirections(facility);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
              icon: const Icon(Icons.directions_rounded, size: 20),
              label: Text(
                'Get Directions',
                style: AppTextStyles.buttonLg,
              ),
            ),
          ),
        ],
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

// ── Helper widgets ──────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.bodyMd),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TypeBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(color: color),
      ),
    );
  }
}
