/// Modelo para representar un hotspot de geofencing
class GeofenceHotspot {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final String activity; // 'ALTA' o 'MODERADA'

  const GeofenceHotspot({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.activity,
  });

  @override
  String toString() {
    return 'GeofenceHotspot(id: $id, name: $name, lat: $latitude, lng: $longitude, radius: $radius, activity: $activity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeofenceHotspot && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}