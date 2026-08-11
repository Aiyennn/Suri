import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/medical_facility_repository_impl.dart';
import '../../domain/entities/medical_facility.dart';
import '../../domain/repositories/medical_facility_repository.dart';

// ── Status ─────────────────────────────────────────────────────────────────

/// All possible states of the nearby-facilities flow.
enum MedicalFacilitiesStatus {
  /// Initial state — nothing has been requested yet.
  initial,

  /// Requesting the user's location (permission + GPS fix).
  locating,

  /// Location obtained; querying the backend.
  loading,

  /// Results returned successfully.
  success,

  /// Query succeeded but no facilities were found within the radius.
  empty,

  /// Location permission was denied by the user.
  locationDenied,

  /// Location permission is permanently denied — must go to settings.
  locationDeniedForever,

  /// Device location services are disabled.
  locationUnavailable,

  /// A network or backend error occurred.
  networkError,
}

// ── State ──────────────────────────────────────────────────────────────────

class MedicalFacilitiesState {
  final MedicalFacilitiesStatus status;
  final List<MedicalFacility> facilities;
  final double? userLat;
  final double? userLng;
  final String? errorMessage;

  const MedicalFacilitiesState({
    this.status = MedicalFacilitiesStatus.initial,
    this.facilities = const [],
    this.userLat,
    this.userLng,
    this.errorMessage,
  });

  MedicalFacilitiesState copyWith({
    MedicalFacilitiesStatus? status,
    List<MedicalFacility>? facilities,
    double? userLat,
    double? userLng,
    String? errorMessage,
  }) {
    return MedicalFacilitiesState(
      status: status ?? this.status,
      facilities: facilities ?? this.facilities,
      userLat: userLat ?? this.userLat,
      userLng: userLng ?? this.userLng,
      errorMessage: errorMessage,
    );
  }

  bool get isLoading =>
      status == MedicalFacilitiesStatus.locating ||
      status == MedicalFacilitiesStatus.loading;
}

// ── Repository provider ────────────────────────────────────────────────────

final medicalFacilityRepositoryProvider =
    Provider<MedicalFacilityRepository>((ref) {
  return MedicalFacilityRepositoryImpl();
});

// ── Main provider ──────────────────────────────────────────────────────────

final medicalFacilitiesProvider =
    StateNotifierProvider<MedicalFacilitiesNotifier, MedicalFacilitiesState>(
  (ref) => MedicalFacilitiesNotifier(
    ref.read(medicalFacilityRepositoryProvider),
    ref,
  ),
);

// ── Notifier ───────────────────────────────────────────────────────────────

class MedicalFacilitiesNotifier
    extends StateNotifier<MedicalFacilitiesState> {
  final MedicalFacilityRepository _repository;
  final Ref _ref;

  /// Default search radius in metres.
  static const int _defaultRadiusMetres = 5000;

  MedicalFacilitiesNotifier(this._repository, this._ref)
      : super(const MedicalFacilitiesState());

  // ── Public actions ──────────────────────────────────────────────────────

  /// Request location permission, get the current position, then fetch
  /// nearby facilities from the backend.
  ///
  /// Call this when the page loads or the user taps "Retry".
  Future<void> loadNearby({int radiusMetres = _defaultRadiusMetres}) async {
    state = state.copyWith(status: MedicalFacilitiesStatus.locating);

    // 1. Check and request location permission.
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (!mounted) return;

    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(
        status: MedicalFacilitiesStatus.locationDeniedForever,
        errorMessage:
            'Location permission is permanently denied. Please enable it in your device settings.',
      );
      return;
    }

    if (permission == LocationPermission.denied) {
      state = state.copyWith(
        status: MedicalFacilitiesStatus.locationDenied,
        errorMessage: 'Location permission was denied. Tap Retry to try again.',
      );
      return;
    }

    // 2. Check that device location services are enabled.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      state = state.copyWith(
        status: MedicalFacilitiesStatus.locationUnavailable,
        errorMessage:
            'Location services are disabled. Please enable GPS in your device settings.',
      );
      return;
    }

    // 3. Obtain the current position.
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        status: MedicalFacilitiesStatus.locationUnavailable,
        errorMessage: 'Could not determine your location. Please try again.',
      );
      return;
    }

    if (!mounted) return;

    state = state.copyWith(
      status: MedicalFacilitiesStatus.loading,
      userLat: position.latitude,
      userLng: position.longitude,
    );

    // 4. Read token from auth provider.
    final token = _ref.read(currentTokenProvider);
    if (token == null) {
      state = state.copyWith(
        status: MedicalFacilitiesStatus.networkError,
        errorMessage: 'You must be signed in to use this feature.',
      );
      return;
    }

    // 5. Fetch nearby facilities from the backend.
    try {
      final facilities = await _repository.getNearbyFacilities(
        lat: position.latitude,
        lng: position.longitude,
        radiusMetres: radiusMetres,
        token: token,
      );

      if (!mounted) return;
      state = state.copyWith(
        status: facilities.isEmpty
            ? MedicalFacilitiesStatus.empty
            : MedicalFacilitiesStatus.success,
        facilities: facilities,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        status: MedicalFacilitiesStatus.networkError,
        errorMessage: _friendlyError(e.toString()),
      );
    }
  }

  /// Open an external maps/navigation app for [facility] using the
  /// platform-native geo: URI scheme.
  ///
  /// On Android this may open Google Maps, HERE, OsmAnd, or any installed
  /// navigation app.  On iOS it opens Apple Maps.
  /// No Google Maps API key is required.
  Future<void> openDirections(MedicalFacility facility) async {
    final lat = facility.latitude;
    final lng = facility.longitude;
    final label = Uri.encodeComponent(facility.displayName);

    final uri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback: OSM-based URL that opens in the browser
      final webUri = Uri.parse(
        'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng&zoom=17',
      );
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  /// Reset to initial state (e.g. when leaving the page).
  void reset() {
    state = const MedicalFacilitiesState();
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  static String _friendlyError(String raw) {
    if (raw.contains('503') || raw.contains('SERVICE_UNAVAILABLE')) {
      return 'The map data service is temporarily unavailable. Please try again later.';
    }
    if (raw.contains('SocketException') ||
        raw.contains('Failed host lookup') ||
        raw.contains('network')) {
      return 'No internet connection. Please check your network and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
