class CustomZone {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final String zoneType;

  const CustomZone({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.zoneType,
  });

  CustomZone copyWith({
    int? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radius,
    String? zoneType,
  }) {
    return CustomZone(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      zoneType: zoneType ?? this.zoneType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'zone_type': zoneType,
    };
  }

  factory CustomZone.fromMap(Map<String, dynamic> map) {
    final String? rawZoneType = (map['zoneType'] ?? map['zone_type']) as String?;
    return CustomZone(
      id: map['id'] as int?,
      name: map['name'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      radius: (map['radius'] as num).toDouble(),
      zoneType: rawZoneType?.trim().isNotEmpty == true
          ? rawZoneType!.trim()
          : 'other',
    );
  }
}

