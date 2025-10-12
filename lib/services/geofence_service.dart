import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geofencing_api/geofencing_api.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class GeofenceService {
  static final GeofenceService _instance = GeofenceService._internal();
  factory GeofenceService() => _instance;
  GeofenceService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  bool _isMonitoring = false;

  // Definición de los 4 Hotspots específicos
  static const List<GeofenceHotspot> hotspots = [
    // Edificio de la guardia civil (ALTA)
    GeofenceHotspot(
      id: 'guardia_civil',
      latitude: 40.93599,
      longitude: -4.11286,
      radius: 183.72,
      activity: 'ALTA',
      color: '#ff2100',
    ),
    
    // Claret (ALTA)
    GeofenceHotspot(
      id: 'claret',
      latitude: 40.94649,
      longitude: -4.11220,
      radius: 116.55,
      activity: 'ALTA',
      color: '#ff2100',
    ),
    
    // Hermanitas de los pobres (MODERADA)
    GeofenceHotspot(
      id: 'hermanitas_pobres',
      latitude: 40.94204,
      longitude: -4.10901,
      radius: 148.69,
      activity: 'MODERADA',
      color: '#ffc700',
    ),
    
    // Camino IE (MODERADA)
    GeofenceHotspot(
      id: 'camino_ie',
      latitude: 40.95093,
      longitude: -4.11616,
      radius: 75.40,
      activity: 'MODERADA',
      color: '#ffc700',
    ),
  ];

  /// Inicializa el servicio de geofencing y notificaciones locales
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Inicializar notificaciones locales
      await _initializeNotifications();
      
      // Solicitar permisos necesarios
      await _requestPermissions();
      
      _isInitialized = true;
      debugPrint('✅ GeofenceService inicializado correctamente');
      return true;
    } catch (e) {
      debugPrint('❌ Error al inicializar GeofenceService: $e');
      return false;
    }
  }

  /// Inicializa las notificaciones locales
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    debugPrint('🔔 Notificaciones locales inicializadas');
  }

  /// Solicita los permisos necesarios
  Future<void> _requestPermissions() async {
    try {
      debugPrint('🔐 Solicitando permisos de ubicación...');
      
      // Solicitar permiso de ubicación cuando la app está en uso primero
      var locationWhenInUse = await Permission.locationWhenInUse.request();
      debugPrint('📍 Permiso locationWhenInUse: $locationWhenInUse');
      
      if (locationWhenInUse.isGranted) {
        // Solo solicitar ubicación en segundo plano si el permiso básico está otorgado
        var locationAlways = await Permission.locationAlways.request();
        debugPrint('📍 Permiso locationAlways: $locationAlways');
        
        if (locationAlways.isDenied || locationAlways.isPermanentlyDenied) {
          debugPrint('⚠️ Permiso de ubicación en segundo plano no otorgado');
          debugPrint('⚠️ El geofencing puede no funcionar con la app cerrada');
        }
      }
      
      // Solicitar permisos de notificaciones
      var notification = await Permission.notification.request();
      debugPrint('🔔 Permiso notification: $notification');
      
      // Verificar permisos críticos
      final locationAlwaysStatus = await Permission.locationAlways.status;
      final notificationStatus = await Permission.notification.status;
      
      debugPrint('🔍 Estado final de permisos:');
      debugPrint('   - Ubicación siempre: $locationAlwaysStatus');
      debugPrint('   - Notificaciones: $notificationStatus');
      
      if (locationAlwaysStatus.isGranted && notificationStatus.isGranted) {
        debugPrint('✅ Todos los permisos críticos otorgados');
      } else {
        debugPrint('⚠️ Algunos permisos críticos no están otorgados');
      }
      
    } catch (e) {
      debugPrint('❌ Error al solicitar permisos: $e');
    }
  }

  /// Verifica que los permisos críticos estén otorgados
  Future<bool> _checkRequiredPermissions() async {
    final locationAlwaysStatus = await Permission.locationAlways.status;
    final notificationStatus = await Permission.notification.status;
    
    debugPrint('🔍 Verificando permisos críticos:');
    debugPrint('   - Ubicación siempre: $locationAlwaysStatus');
    debugPrint('   - Notificaciones: $notificationStatus');
    
    if (!locationAlwaysStatus.isGranted) {
      debugPrint('❌ Permiso de ubicación en segundo plano no otorgado');
      return false;
    }
    
    if (!notificationStatus.isGranted) {
      debugPrint('❌ Permiso de notificaciones no otorgado');
      return false;
    }
    
    debugPrint('✅ Todos los permisos críticos están otorgados');
    return true;
  }

  /// Inicia el monitoreo de los hotspots
  Future<bool> startMonitoring() async {
    if (!_isInitialized) {
      debugPrint('⚠️ GeofenceService no inicializado');
      return false;
    }

    if (_isMonitoring) {
      debugPrint('⚠️ Monitoreo ya está activo');
      return true;
    }

    // Verificar permisos antes de iniciar
    if (!await _checkRequiredPermissions()) {
      debugPrint('❌ No se pueden iniciar servicios sin permisos críticos');
      return false;
    }

    try {
      // Configurar el servicio de geofencing
      Geofencing.instance.setup(
        interval: 5000, // 5 segundos
        accuracy: 100, // 100 metros de precisión
        statusChangeDelay: 1000, // 1 segundo de delay
        allowsMockLocation: false,
        printsDebugLog: true,
      );

      // Crear las regiones de geofencing
      final Set<GeofenceRegion> regions = hotspots.map((hotspot) => 
        GeofenceRegion.circular(
          id: hotspot.id,
          center: LatLng(hotspot.latitude, hotspot.longitude),
          radius: hotspot.radius,
          data: hotspot.activity, // Almacenar el nivel de actividad
          loiteringDelay: 30000, // 30 segundos antes de cambiar a dwell
        ),
      ).toSet();

      // Configurar el callback para eventos de geofencing
      Geofencing.instance.addGeofenceStatusChangedListener(_onGeofenceStatusChanged);

      // Iniciar el monitoreo
      await Geofencing.instance.start(regions: regions);
      
      _isMonitoring = true;
      debugPrint('🚨 Monitoreo de hotspots iniciado - ${hotspots.length} zonas activas');
      
      // Mostrar notificación de confirmación
      await _showStartupNotification();
      
      return true;
    } catch (e) {
      debugPrint('❌ Error al iniciar monitoreo: $e');
      return false;
    }
  }

  /// Detiene el monitoreo de hotspots
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    try {
      await Geofencing.instance.stop(keepsRegions: false);
      _isMonitoring = false;
      debugPrint('🛑 Monitoreo de hotspots detenido');
    } catch (e) {
      debugPrint('❌ Error al detener monitoreo: $e');
    }
  }

  /// Callback que se ejecuta cuando cambia el estado de un geofence
  static Future<void> _onGeofenceStatusChanged(
    GeofenceRegion region, 
    GeofenceStatus status, 
    Location location
  ) async {
    debugPrint('🚨 Evento de geofencing detectado: ${region.id} - $status');
    
    // Solo procesar eventos de ENTRADA
    if (status == GeofenceStatus.enter) {
      // Encontrar el hotspot correspondiente
      final hotspot = hotspots.firstWhere(
        (h) => h.id == region.id,
        orElse: () => throw Exception('Hotspot no encontrado: ${region.id}'),
      );
      
      // Disparar notificación específica según el nivel de riesgo
      if (hotspot.activity == 'ALTA') {
        await _showHighDangerZoneNotification(hotspot);
      } else if (hotspot.activity == 'MODERADA') {
        await _showModerateDangerZoneNotification(hotspot);
      }
    }
  }

  /// Muestra la notificación para zonas de ALTA peligrosidad
  static Future<void> _showHighDangerZoneNotification(GeofenceHotspot hotspot) async {
    debugPrint('🔴 Mostrando notificación ALTA para hotspot: ${hotspot.id}');
    
    final GeofenceService instance = GeofenceService();
    await instance._localNotifications.show(
      hotspot.id.hashCode, // ID único para cada hotspot
      'Alerta, estás en una zona de alta peligrosidad.',
      'Activa el sistema para estar a salvo.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_danger_alerts',
          'Alertas de Alta Peligrosidad',
          channelDescription: 'Notificaciones de alerta para zonas de alta peligrosidad',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          ongoing: true,
          autoCancel: false,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFFF2100), // Color rojo
          playSound: true,
          enableVibration: true,
          showWhen: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
      payload: 'high_danger_alert:${hotspot.id}',
    );
  }

  /// Muestra la notificación para zonas de MODERADA peligrosidad
  static Future<void> _showModerateDangerZoneNotification(GeofenceHotspot hotspot) async {
    debugPrint('🟡 Mostrando notificación MODERADA para hotspot: ${hotspot.id}');
    
    final GeofenceService instance = GeofenceService();
    await instance._localNotifications.show(
      hotspot.id.hashCode, // ID único para cada hotspot
      'Alerta, zona de peligrosidad moderada.',
      'Activa el sistema para estar a salvo.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'moderate_danger_alerts',
          'Alertas de Peligrosidad Moderada',
          channelDescription: 'Notificaciones de alerta para zonas de peligrosidad moderada',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.status,
          ongoing: false,
          autoCancel: true,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFFF8C00), // Color ámbar
          playSound: true,
          enableVibration: true,
          showWhen: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: 'moderate_danger_alert:${hotspot.id}',
    );
  }

  /// Muestra notificación de confirmación al iniciar el monitoreo
  Future<void> _showStartupNotification() async {
    await _localNotifications.show(
      'startup'.hashCode,
      '🔒 HoldOn - Protección Activa',
      'Monitoreo de hotspots iniciado. ${hotspots.length} zonas vigiladas.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'system_status',
          'Estado del Sistema',
          channelDescription: 'Notificaciones del estado del sistema',
          importance: Importance.low,
          priority: Priority.low,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: true,
          presentSound: false,
        ),
      ),
    );
  }

  /// Callback cuando se toca una notificación
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notificación tocada: ${response.payload}');
    
    if (response.payload != null) {
      if (response.payload!.startsWith('high_danger_alert:')) {
        debugPrint('🔴 Usuario tocó alerta de alta peligrosidad');
        // Aquí puedes agregar lógica adicional para alertas de alta peligrosidad
      } else if (response.payload!.startsWith('moderate_danger_alert:')) {
        debugPrint('🟡 Usuario tocó alerta de peligrosidad moderada');
        // Aquí puedes agregar lógica adicional para alertas moderadas
      } else if (response.payload!.startsWith('hotspot_alert:')) {
        debugPrint('🚨 Usuario tocó alerta de hotspot (legacy)');
        // Mantener compatibilidad con el formato anterior
      }
    }
  }

  /// Obtiene la lista de hotspots
  List<GeofenceHotspot> get hotspotsList => List.unmodifiable(hotspots);

  /// Verifica si el monitoreo está activo
  bool get isMonitoring => _isMonitoring;

  /// Verifica si el servicio está inicializado
  bool get isInitialized => _isInitialized;

  /// Verifica si el usuario está dentro de algún hotspot y retorna el nivel de actividad
  Future<String?> getUserHotspotActivity() async {
    try {
      // Obtener la ubicación actual del usuario
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );

      final double userLat = position.latitude;
      final double userLng = position.longitude;

      // Verificar si está dentro de algún hotspot
      for (final hotspot in hotspots) {
        final double distance = Geolocator.distanceBetween(
          userLat,
          userLng,
          hotspot.latitude,
          hotspot.longitude,
        );

        if (distance <= hotspot.radius) {
          debugPrint('📍 Usuario dentro del hotspot: ${hotspot.id} (${hotspot.activity}) - distancia: ${distance.toStringAsFixed(1)}m');
          return hotspot.activity; // Retornar ALTA o MODERADA
        }
      }

      debugPrint('📍 Usuario fuera de todos los hotspots');
      return null; // No está en ningún hotspot
    } catch (e) {
      debugPrint('❌ Error al verificar ubicación del usuario: $e');
      return null; // En caso de error, asumir que está fuera
    }
  }

  /// Verifica si el usuario está dentro de algún hotspot (método legacy para compatibilidad)
  Future<bool> isUserInsideHotspot() async {
    final String? activity = await getUserHotspotActivity();
    return activity != null;
  }
}

/// Modelo para representar un hotspot de geofencing
class GeofenceHotspot {
  final String id;
  final double latitude;
  final double longitude;
  final double radius;
  final String activity; // ALTA o MODERADA
  final String color; // Color hex asociado

  const GeofenceHotspot({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.activity,
    required this.color,
  });

  @override
  String toString() {
    return 'GeofenceHotspot(id: $id, lat: $latitude, lng: $longitude, radius: $radius, activity: $activity)';
  }
}