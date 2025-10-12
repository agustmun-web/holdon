import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Servicio de ubicación activo para mantener el geofencing funcionando
/// con máxima precisión y frecuencia
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStream;
  Position? _lastPosition;
  Timer? _keepAliveTimer;
  bool _isActive = false;

  /// Obtiene la última posición conocida
  Position? get lastPosition => _lastPosition;

  /// Verifica si el servicio está activo
  bool get isActive => _isActive;

  /// Inicia el monitoreo activo de ubicación
  Future<bool> startActiveLocationTracking() async {
    if (_isActive) {
      debugPrint('📍 LocationService ya está activo');
      return true;
    }

    try {
      debugPrint('🚀 Iniciando monitoreo activo de ubicación...');

      // Configuración de máxima precisión
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Actualizar cada 5 metros
        timeLimit: const Duration(seconds: 10),
      );

      // Iniciar stream de ubicación continuo
      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _lastPosition = position;
          debugPrint('📍 Ubicación actualizada: ${position.latitude}, ${position.longitude}');
        },
        onError: (error) {
          debugPrint('❌ Error en stream de ubicación: $error');
        },
      );

      // Timer de keep-alive cada 30 segundos
      _keepAliveTimer = Timer.periodic(
        const Duration(seconds: 30),
        (timer) => _performKeepAlive(),
      );

      _isActive = true;
      debugPrint('✅ LocationService iniciado correctamente');
      return true;

    } catch (e) {
      debugPrint('❌ Error al iniciar LocationService: $e');
      return false;
    }
  }

  /// Detiene el monitoreo de ubicación
  Future<void> stopActiveLocationTracking() async {
    debugPrint('🛑 Deteniendo monitoreo de ubicación...');
    
    await _positionStream?.cancel();
    _positionStream = null;
    
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    
    _isActive = false;
    debugPrint('✅ LocationService detenido');
  }

  /// Obtiene la ubicación actual
  Future<Position?> getCurrentPosition() async {
    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      
      _lastPosition = position;
      debugPrint('📍 Ubicación actual obtenida: ${position.latitude}, ${position.longitude}');
      return position;

    } catch (e) {
      debugPrint('❌ Error al obtener ubicación actual: $e');
      return _lastPosition;
    }
  }

  /// Calcula la distancia entre dos puntos
  double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Verifica si una ubicación está dentro del radio especificado
  bool isWithinRadius(
    double userLat, double userLon,
    double targetLat, double targetLon,
    double radiusMeters,
  ) {
    final distance = calculateDistance(userLat, userLon, targetLat, targetLon);
    return distance <= radiusMeters;
  }

  /// Solicita una actualización de ubicación manual
  Future<void> requestLocationUpdate() async {
    debugPrint('🔄 Solicitando actualización manual de ubicación...');
    await getCurrentPosition();
  }

  /// Realiza keep-alive para mantener el servicio activo
  void _performKeepAlive() {
    debugPrint('💓 Keep-alive: Manteniendo servicio de ubicación activo');
    requestLocationUpdate();
  }

  /// Limpia recursos
  void dispose() {
    stopActiveLocationTracking();
  }
}