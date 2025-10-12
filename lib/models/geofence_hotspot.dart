/// Modelo para representar un hotspot de geofencing
class GeofenceHotspot {
  /// Identificador único del hotspot
  final String id;
  
  /// Latitud del centro del hotspot
  final double latitude;
  
  /// Longitud del centro del hotspot
  final double longitude;
  
  /// Radio del hotspot en metros
  final double radius;
  
  /// Nivel de actividad del hotspot (ALTA, MODERADA, BAJA)
  final String activity;
  
  /// Nombre descriptivo del hotspot
  final String? name;
  
  /// Descripción adicional del hotspot
  final String? description;

  const GeofenceHotspot({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.activity,
    this.name,
    this.description,
  });

  /// Crea una copia del hotspot con valores modificados
  GeofenceHotspot copyWith({
    String? id,
    double? latitude,
    double? longitude,
    double? radius,
    String? activity,
    String? name,
    String? description,
  }) {
    return GeofenceHotspot(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      activity: activity ?? this.activity,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }

  /// Convierte el hotspot a un mapa para serialización
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'activity': activity,
      'name': name,
      'description': description,
    };
  }

  /// Crea un hotspot desde un mapa (deserialización)
  factory GeofenceHotspot.fromMap(Map<String, dynamic> map) {
    return GeofenceHotspot(
      id: map['id'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      radius: map['radius']?.toDouble() ?? 0.0,
      activity: map['activity'] ?? 'BAJA',
      name: map['name'],
      description: map['description'],
    );
  }

  @override
  String toString() {
    return 'GeofenceHotspot(id: $id, lat: $latitude, lng: $longitude, radius: $radius, activity: $activity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeofenceHotspot &&
        other.id == id &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.radius == radius &&
        other.activity == activity &&
        other.name == name &&
        other.description == description;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      latitude,
      longitude,
      radius,
      activity,
      name,
      description,
    );
  }
}

