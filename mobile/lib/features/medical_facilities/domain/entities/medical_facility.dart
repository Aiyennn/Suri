/// Represents a nearby medical facility sourced from OpenStreetMap.
///
/// All nullable fields may be absent — OSM data quality varies and
/// not every facility has a complete name or address.
///
/// [distanceKm] is a straight-line Haversine approximation only.
/// It does not represent driving or walking distance and should
/// never be used to recommend a facility as medically appropriate.
class MedicalFacility {
  /// Unique identifier constructed from the OSM element type and id
  /// (e.g. "node/123456" or "way/789012").
  final String id;

  /// Facility name from the OSM 'name' tag. May be null.
  final String? name;

  /// Facility category derived from the OSM amenity or healthcare tag
  /// (e.g. 'hospital', 'clinic', 'doctors', 'pharmacy').
  final String type;

  /// Latitude of the facility centre point (WGS84).
  final double latitude;

  /// Longitude of the facility centre point (WGS84).
  final double longitude;

  /// Best-effort address assembled from OSM addr:* tags. May be null.
  final String? address;

  /// Great-circle distance in kilometres from the user's location.
  /// Straight-line approximation — not driving distance. May be null.
  final double? distanceKm;

  const MedicalFacility({
    required this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.name,
    this.address,
    this.distanceKm,
  });

  /// Human-readable display name — falls back to the capitalised type.
  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    return _capitalise(type.replaceAll('_', ' '));
  }

  /// Formatted distance string, e.g. "2.4 km" or "800 m".
  String? get formattedDistance {
    if (distanceKm == null) return null;
    if (distanceKm! < 1.0) {
      return '${(distanceKm! * 1000).round()} m';
    }
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  /// Icon data for the facility type.
  String get typeLabel {
    switch (type.toLowerCase()) {
      case 'hospital':
        return 'Hospital';
      case 'clinic':
        return 'Clinic';
      case 'doctors':
        return 'Doctor\'s Office';
      case 'pharmacy':
        return 'Pharmacy';
      default:
        return _capitalise(type.replaceAll('_', ' '));
    }
  }

  factory MedicalFacility.fromJson(Map<String, dynamic> json) {
    return MedicalFacility(
      id: json['id'] as String,
      name: json['name'] as String?,
      type: json['type'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      distanceKm: json['distance_km'] == null
          ? null
          : (json['distance_km'] as num).toDouble(),
    );
  }

  static String _capitalise(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
