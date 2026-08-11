import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../domain/entities/medical_facility.dart';
import '../providers/medical_facilities_provider.dart';
import '../widgets/facility_detail_sheet.dart';
import '../widgets/facility_list_tile.dart';
import '../widgets/map_error_view.dart';
import '../widgets/map_loading_view.dart';

/// Main page for the Nearby Medical Facilities feature.
///
/// User flow:
///   1. Page opens → [MedicalFacilitiesNotifier.loadNearby] is called.
///   2. Location permission is requested, GPS fix obtained.
///   3. Backend queries Overpass API and returns normalized results.
///   4. OpenStreetMap map is rendered centred on the user with facility markers.
///   5. A scrollable list of facilities appears below the map.
///   6. Tapping a marker or "View" opens [FacilityDetailSheet].
///
/// Tiles are served by OpenStreetMap — no Google Maps API key required.
/// Attribution is displayed as required by the OSM tile usage policy.
class NearbyFacilitiesPage extends ConsumerStatefulWidget {
  const NearbyFacilitiesPage({super.key});

  @override
  ConsumerState<NearbyFacilitiesPage> createState() =>
      _NearbyFacilitiesPageState();
}

class _NearbyFacilitiesPageState
    extends ConsumerState<NearbyFacilitiesPage> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Trigger load after the first frame so the provider is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(medicalFacilitiesProvider.notifier).loadNearby();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(medicalFacilitiesProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppTopBar(
        title: 'Nearby Facilities',
        showBack: true,
        onBack: () => Navigator.maybePop(context),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(MedicalFacilitiesState state) {
    // Loading states
    if (state.isLoading) {
      return MapLoadingView(status: state.status);
    }

    // Error / permission / empty states
    if (state.status == MedicalFacilitiesStatus.locationDenied ||
        state.status == MedicalFacilitiesStatus.locationDeniedForever ||
        state.status == MedicalFacilitiesStatus.locationUnavailable ||
        state.status == MedicalFacilitiesStatus.networkError ||
        state.status == MedicalFacilitiesStatus.empty) {
      return MapErrorView(
        status: state.status,
        message: state.errorMessage,
        onRetry: () =>
            ref.read(medicalFacilitiesProvider.notifier).loadNearby(),
      );
    }

    // Success state — show map + list
    if (state.status == MedicalFacilitiesStatus.success &&
        state.userLat != null &&
        state.userLng != null) {
      return _buildMapAndList(state);
    }

    // Initial state — nothing yet
    return const SizedBox.shrink();
  }

  Widget _buildMapAndList(MedicalFacilitiesState state) {
    final userLatLng = LatLng(state.userLat!, state.userLng!);

    return CustomScrollView(
      slivers: [
        // ── Map ──────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _MapSection(
            userLatLng: userLatLng,
            facilities: state.facilities,
            mapController: _mapController,
          ),
        ),

        // ── Section header ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Text('Nearby Facilities', style: AppTextStyles.headingSm),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    '${state.facilities.length}',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Privacy note ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              'Distances are straight-line approximations. '
              'Proximity does not indicate medical suitability.',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

        // ── Facility list ────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final facility = state.facilities[index];
                return FacilityListTile(
                  facility: facility,
                  onViewTap: () => FacilityDetailSheet.show(context, facility),
                );
              },
              childCount: state.facilities.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Map section ─────────────────────────────────────────────────────────────

/// The interactive OpenStreetMap section.
///
/// Uses `flutter_map` with OSM tiles — no Google Maps API key required.
/// Attribution is rendered as required by the OSM tile usage policy.
class _MapSection extends StatelessWidget {
  final LatLng userLatLng;
  final List<MedicalFacility> facilities;
  final MapController mapController;

  const _MapSection({
    required this.userLatLng,
    required this.facilities,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder),
        ),
      ),
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: userLatLng,
          initialZoom: 14.0,
          minZoom: 10.0,
          maxZoom: 18.0,
        ),
        children: [
          // ── OSM tile layer ────────────────────────────────────────────
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.suri.mobile',
            // Required by OSM tile usage policy
            additionalOptions: const {
              'attribution':
                  '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
            },
          ),

          // ── Facility markers ──────────────────────────────────────────
          MarkerLayer(
            markers: [
              for (final facility in facilities)
                _facilityMarker(context, facility),
            ],
          ),

          // ── User location marker ──────────────────────────────────────
          MarkerLayer(
            markers: [
              Marker(
                point: userLatLng,
                width: 48,
                height: 48,
                child: const _UserLocationMarker(),
              ),
            ],
          ),

          // ── Required OSM attribution ──────────────────────────────────
          const RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                '© OpenStreetMap contributors',
                onTap: null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Marker _facilityMarker(BuildContext context, MedicalFacility facility) {
    return Marker(
      point: LatLng(facility.latitude, facility.longitude),
      width: 44,
      height: 52,
      child: GestureDetector(
        onTap: () => FacilityDetailSheet.show(context, facility),
        child: _FacilityMarker(type: facility.type),
      ),
    );
  }
}

// ── Custom marker widgets ────────────────────────────────────────────────────

class _FacilityMarker extends StatelessWidget {
  final String type;

  const _FacilityMarker({required this.type});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: _color.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(_icon, size: 18, color: Colors.white),
        ),
        // Pin tip
        CustomPaint(
          size: const Size(12, 6),
          painter: _PinTailPainter(color: _color),
        ),
      ],
    );
  }

  IconData get _icon {
    switch (type.toLowerCase()) {
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

  Color get _color {
    switch (type.toLowerCase()) {
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

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer halo
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
        ),
        // Inner dot
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.5),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Draws the triangular pin tail beneath a facility marker.
class _PinTailPainter extends CustomPainter {
  final Color color;
  const _PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTailPainter old) => old.color != color;
}
