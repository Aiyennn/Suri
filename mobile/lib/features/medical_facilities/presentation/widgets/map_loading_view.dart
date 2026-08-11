import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../providers/medical_facilities_provider.dart';

/// Animated loading/locating placeholder shown while the feature is either
/// requesting the user's location or fetching data from the backend.
class MapLoadingView extends StatefulWidget {
  final MedicalFacilitiesStatus status;

  const MapLoadingView({super.key, required this.status});

  @override
  State<MapLoadingView> createState() => _MapLoadingViewState();
}

class _MapLoadingViewState extends State<MapLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing icon
            ScaleTransition(
              scale: _pulse,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.status == MedicalFacilitiesStatus.locating
                      ? Icons.my_location_rounded
                      : Icons.local_hospital_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              widget.status == MedicalFacilitiesStatus.locating
                  ? 'Getting your location…'
                  : 'Finding nearby facilities…',
              style: AppTextStyles.headingSm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.status == MedicalFacilitiesStatus.locating
                  ? 'Requesting GPS access'
                  : 'Querying OpenStreetMap data',
              style: AppTextStyles.bodyMd,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Progress indicator
            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.primaryLight,
                color: AppColors.primary,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
