import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../providers/medical_facilities_provider.dart';

/// Full-screen error / permission-denied state view.
///
/// Adapts its message and action based on [status].
class MapErrorView extends StatelessWidget {
  final MedicalFacilitiesStatus status;
  final String? message;
  final VoidCallback? onRetry;

  const MapErrorView({
    super.key,
    required this.status,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration container
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _iconBgColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconData, size: 40, color: _iconBgColor),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Title
            Text(
              _title,
              style: AppTextStyles.headingSm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Description
            Text(
              message ?? _defaultMessage,
              style: AppTextStyles.bodyMd,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Primary action
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _primaryAction(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
                child: Text(
                  _primaryLabel,
                  style: AppTextStyles.buttonLg,
                ),
              ),
            ),

            // Secondary action for permanently-denied (open settings)
            if (status ==
                MedicalFacilitiesStatus.locationDeniedForever) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => Geolocator.openAppSettings(),
                child: Text(
                  'Open App Settings',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Computed values ────────────────────────────────────────────────────

  String get _title {
    switch (status) {
      case MedicalFacilitiesStatus.locationDenied:
        return 'Location Access Needed';
      case MedicalFacilitiesStatus.locationDeniedForever:
        return 'Permission Permanently Denied';
      case MedicalFacilitiesStatus.locationUnavailable:
        return 'Location Unavailable';
      case MedicalFacilitiesStatus.networkError:
        return 'Connection Error';
      case MedicalFacilitiesStatus.empty:
        return 'No Facilities Found';
      default:
        return 'Something Went Wrong';
    }
  }

  String get _defaultMessage {
    switch (status) {
      case MedicalFacilitiesStatus.locationDenied:
        return 'Suri needs access to your location to find nearby medical facilities.';
      case MedicalFacilitiesStatus.locationDeniedForever:
        return 'Location access is permanently denied. Open App Settings and enable location for Suri.';
      case MedicalFacilitiesStatus.locationUnavailable:
        return 'Unable to determine your location. Please enable GPS and try again.';
      case MedicalFacilitiesStatus.networkError:
        return 'Could not load nearby facilities. Check your internet connection and try again.';
      case MedicalFacilitiesStatus.empty:
        return 'No hospitals or clinics were found within the search area. Try expanding the radius.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  IconData get _iconData {
    switch (status) {
      case MedicalFacilitiesStatus.locationDenied:
      case MedicalFacilitiesStatus.locationDeniedForever:
        return Icons.location_off_rounded;
      case MedicalFacilitiesStatus.locationUnavailable:
        return Icons.gps_off_rounded;
      case MedicalFacilitiesStatus.networkError:
        return Icons.wifi_off_rounded;
      case MedicalFacilitiesStatus.empty:
        return Icons.search_off_rounded;
      default:
        return Icons.error_outline_rounded;
    }
  }

  Color get _iconBgColor {
    switch (status) {
      case MedicalFacilitiesStatus.networkError:
        return AppColors.error;
      case MedicalFacilitiesStatus.empty:
        return AppColors.textSecondary;
      default:
        return AppColors.warning;
    }
  }

  String get _primaryLabel {
    if (status == MedicalFacilitiesStatus.locationUnavailable) {
      return 'Open Location Settings';
    }
    return 'Retry';
  }

  VoidCallback? _primaryAction(BuildContext context) {
    if (status == MedicalFacilitiesStatus.locationUnavailable) {
      return () => Geolocator.openLocationSettings();
    }
    return onRetry;
  }
}
