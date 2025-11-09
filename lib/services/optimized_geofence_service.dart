import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geofencing_api/geofencing_api.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'location_service.dart';
import '../models/geofence_hotspot.dart';

/// Servicio de geofencing optimizado para Android con máxima precisión
/// y detección dual (nativa + manual)
class OptimizedGeofenceService {
  static final OptimizedGeofenceService _instance = OptimizedGeofenceService._internal();
  factory OptimizedGeofenceService() => _instance;
  OptimizedGeofenceService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final LocationService _locationService = LocationService();
  
  bool _isInitialized = false;
  bool _isMonitoring = false;
  Timer? _hotspotCheckTimer;
  Timer? _keepAliveTimer;
  
  // Control de notificaciones para evitar spam
  final Set<String> _notifiedHotspots = <String>{};
  final Map<String, DateTime> _lastNotificationTime = <String, DateTime>{};
  final Map<String, bool> _isInHotspot = <String, bool>{};
  
  // Lista de hotspots optimizada
  final List<GeofenceHotspot> hotspots = [
    // Hotspots ALTA (Rojo)
    GeofenceHotspot(
      id: 'guardia_civil',
      name: 'Edificio Guardia Civil',
      latitude: 40.93599,
      longitude: -4.11286,
      radius: 183.72,
      activity: 'ALTA',
    ),
    GeofenceHotspot(
      id: 'claret',
      name: 'Claret',
      latitude: 40.94649,
      longitude: -4.11220,
      radius: 116.55,
      activity: 'ALTA',
    ),
    GeofenceHotspot(
      id: 'chamartin',
      name: 'Chamartín',
      latitude: 40.48104,
      longitude: -3.69538,
      radius: 2382.0,
      activity: 'ALTA',
    ),
    // Hotspots MODERADA (Amarillo)
    GeofenceHotspot(
      id: 'hermanitas_pobres',
      name: 'Hermanitas de los pobres',
      latitude: 40.94204,
      longitude: -4.10901,
      radius: 148.69,
      activity: 'MODERADA',
    ),
    GeofenceHotspot(
      id: 'camino_ie',
      name: 'Camino IE',
      latitude: 40.95093,
      longitude: -4.11616,
      radius: 75.40,
      activity: 'MODERADA',
    ),
  ];

  /// Inicializa el servicio de geofencing optimizado
  Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ OptimizedGeofenceService ya inicializado');
      return true;
    }

    try {
      debugPrint('🚀 Inicializando OptimizedGeofenceService...');

      // Inicializar notificaciones locales
      await _initializeNotifications();

      // Iniciar servicio de ubicación activo
      await _locationService.startActiveLocationTracking();

      // Solicitar permisos robustos
      await _requestPermissionsRobust();

      _isInitialized = true;
      debugPrint('✅ OptimizedGeofenceService inicializado correctamente');
      return true;

    } catch (e) {
      debugPrint('❌ Error al inicializar OptimizedGeofenceService: $e');
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

  /// Solicita permisos de forma robusta con delays
  Future<void> _requestPermissionsRobust() async {
    try {
      debugPrint('🔐 Solicitando permisos de forma robusta...');
      
      // Paso 1: Ubicación cuando la app está en uso
      var locationWhenInUse = await Permission.locationWhenInUse.request();
      debugPrint('📍 Paso 1 - locationWhenInUse: $locationWhenInUse');
      
      // Delay para procesamiento del sistema
      await Future.delayed(const Duration(seconds: 1));
      
      if (locationWhenInUse.isGranted) {
        // Paso 2: Ubicación en segundo plano
        var locationAlways = await Permission.locationAlways.request();
        debugPrint('📍 Paso 2 - locationAlways: $locationAlways');
        
        // Delay adicional
        await Future.delayed(const Duration(seconds: 1));
        
        if (locationAlways.isDenied || locationAlways.isPermanentlyDenied) {
          debugPrint('⚠️ Permiso de ubicación en segundo plano no otorgado');
          debugPrint('⚠️ El geofencing puede no funcionar con la app cerrada');
        }
      }
      
      // Paso 3: Notificaciones
      await Future.delayed(const Duration(seconds: 1));
      var notification = await Permission.notification.request();
      debugPrint('🔔 Paso 3 - notification: $notification');
      
      // Verificación final robusta
      await Future.delayed(const Duration(seconds: 2));
      await _verifyFinalPermissions();
      
    } catch (e) {
      debugPrint('❌ Error al solicitar permisos: $e');
    }
  }

  /// Verifica los permisos finales de forma robusta
  Future<void> _verifyFinalPermissions() async {
    debugPrint('🔍 Verificación final de permisos...');
    
    final locationAlwaysStatus = await Permission.locationAlways.status;
    final notificationStatus = await Permission.notification.status;
    
    debugPrint('📊 Estado final de permisos:');
    debugPrint('   - Ubicación siempre: $locationAlwaysStatus');
    debugPrint('   - Notificaciones: $notificationStatus');
    
    if (locationAlwaysStatus.isGranted && notificationStatus.isGranted) {
      debugPrint('✅ Todos los permisos críticos otorgados');
    } else {
      debugPrint('⚠️ Algunos permisos críticos no están otorgados');
      if (!locationAlwaysStatus.isGranted) {
        debugPrint('❌ CRÍTICO: Ubicación en segundo plano no otorgada');
      }
      if (!notificationStatus.isGranted) {
        debugPrint('❌ CRÍTICO: Notificaciones no otorgadas');
      }
    }
  }

  /// Inicia el monitoreo con configuración de máxima precisión
  Future<bool> startMonitoring() async {
    if (!_isInitialized) {
      debugPrint('⚠️ OptimizedGeofenceService no inicializado');
      return false;
    }

    if (_isMonitoring) {
      debugPrint('⚠️ Monitoreo ya está activo');
      return true;
    }

    try {
      debugPrint('🎯 Iniciando monitoreo con máxima precisión...');

      // Configuración de máxima precisión
      Geofencing.instance.setup(
        interval: 1000,        // 1 segundo - máxima frecuencia
        accuracy: 5,           // 5 metros - máxima precisión
        statusChangeDelay: 200, // 200ms - respuesta ultra rápida
        allowsMockLocation: false,
        printsDebugLog: true,
      );

      // Configurar regiones de geofencing
      final regions = hotspots.map((hotspot) => 
        GeofenceRegion.circular(
          id: hotspot.id,
          center: LatLng(hotspot.latitude, hotspot.longitude),
          radius: hotspot.radius,
          data: hotspot.activity, // Metadatos del nivel de riesgo
        )
      ).toSet();

      // Iniciar geofencing nativo
      await Geofencing.instance.start(regions: regions);
      debugPrint('✅ Geofencing nativo iniciado con ${regions.length} regiones');

      // Configurar callback para eventos de geofencing
      Geofencing.instance.addGeofenceStatusChangedListener(_onGeofenceStatusChanged);

      // Iniciar monitoreo manual como respaldo
      _startManualHotspotMonitoring();

      // Iniciar keep-alive timer
      _startKeepAliveTimer();

      _isMonitoring = true;
      debugPrint('🚀 Sistema de geofencing optimizado iniciado correctamente');
      return true;

    } catch (e) {
      debugPrint('❌ Error al iniciar monitoreo: $e');
      return false;
    }
  }

  /// Inicia el monitoreo manual de hotspots como respaldo
  void _startManualHotspotMonitoring() {
    debugPrint('🔄 Iniciando monitoreo manual de hotspots...');
    
    _hotspotCheckTimer = Timer.periodic(
      const Duration(seconds: 3), // Verificación cada 3 segundos
      (timer) => _checkManualHotspotDetection(),
    );
  }

  /// Verifica manualmente la detección de hotspots
  void _checkManualHotspotDetection() async {
    if (!_isMonitoring) return;

    try {
      final position = await _locationService.getCurrentPosition();
      if (position == null) return;

      // Verificar todos los hotspots
      for (final hotspot in hotspots) {
        final distance = _locationService.calculateDistance(
          position.latitude,
          position.longitude,
          hotspot.latitude,
          hotspot.longitude,
        );

        final isCurrentlyInHotspot = distance <= hotspot.radius;
        final wasInHotspot = _isInHotspot[hotspot.id] ?? false;

        if (isCurrentlyInHotspot && !wasInHotspot) {
          // Usuario acaba de entrar a la zona
          debugPrint('🎯 [MANUAL] ENTRADA detectada en ${hotspot.name} (${distance.toStringAsFixed(1)}m)');
          
          // Verificar si ya se notificó recientemente
          if (_shouldSendNotification(hotspot.id)) {
            // Mostrar notificación según el nivel de riesgo
            if (hotspot.activity == 'ALTA') {
              await _showHighDangerNotification(hotspot);
            } else {
              await _showModerateDangerNotification(hotspot);
            }
            
            // Marcar como notificado
            _markHotspotAsNotified(hotspot.id);
          }
        } else if (!isCurrentlyInHotspot && wasInHotspot) {
          // Usuario acaba de salir de la zona
          debugPrint('✅ [MANUAL] SALIDA detectada de ${hotspot.name}');
          _markHotspotAsExited(hotspot.id);
        }

        // Actualizar estado actual
        _isInHotspot[hotspot.id] = isCurrentlyInHotspot;
      }

    } catch (e) {
      debugPrint('❌ Error en verificación manual: $e');
    }
  }

  /// Inicia el timer de keep-alive
  void _startKeepAliveTimer() {
    debugPrint('💓 Iniciando keep-alive timer...');
    
    _keepAliveTimer = Timer.periodic(
      const Duration(minutes: 5), // Keep-alive cada 5 minutos
      (timer) => _performKeepAlive(),
    );
  }

  /// Realiza keep-alive para mantener el servicio activo
  void _performKeepAlive() {
    debugPrint('💓 Keep-alive: Manteniendo servicios activos...');
    _locationService.requestLocationUpdate();
  }

  /// Verifica si se debe enviar una notificación para un hotspot
  bool _shouldSendNotification(String hotspotId) {
    // Si ya se notificó recientemente (en los últimos 5 minutos), no enviar otra
    final lastTime = _lastNotificationTime[hotspotId];
    if (lastTime != null) {
      final timeSinceLastNotification = DateTime.now().difference(lastTime);
      if (timeSinceLastNotification.inMinutes < 5) {
        debugPrint('⚠️ Notificación omitida para $hotspotId (última notificación hace ${timeSinceLastNotification.inMinutes} minutos)');
        return false;
      }
    }
    
    return true;
  }

  /// Marca un hotspot como notificado
  void _markHotspotAsNotified(String hotspotId) {
    _notifiedHotspots.add(hotspotId);
    _lastNotificationTime[hotspotId] = DateTime.now();
    _isInHotspot[hotspotId] = true;
    debugPrint('📝 Hotspot $hotspotId marcado como notificado');
  }

  /// Marca un hotspot como salido
  void _markHotspotAsExited(String hotspotId) {
    _notifiedHotspots.remove(hotspotId);
    _isInHotspot[hotspotId] = false;
    debugPrint('📝 Hotspot $hotspotId marcado como salido');
  }

  /// Maneja los eventos de geofencing nativo
  static Future<void> _onGeofenceStatusChanged(
    GeofenceRegion region, 
    GeofenceStatus status, 
    Location location
  ) async {
    debugPrint('🎯 [NATIVO] Evento de geofencing: ${region.id} - $status');
    
    final instance = OptimizedGeofenceService();
    final hotspot = instance.hotspots.firstWhere(
      (h) => h.id == region.id,
      orElse: () => throw Exception('Hotspot no encontrado'),
    );

    if (status == GeofenceStatus.enter) {
      debugPrint('🚨 [NATIVO] Entrada detectada en ${hotspot.name}');
      
      // Verificar si ya se notificó recientemente
      if (instance._shouldSendNotification(hotspot.id)) {
        // Mostrar notificación según el nivel de riesgo
        if (hotspot.activity == 'ALTA') {
          await instance._showHighDangerNotification(hotspot);
        } else {
          await instance._showModerateDangerNotification(hotspot);
        }
        
        // Marcar como notificado
        instance._markHotspotAsNotified(hotspot.id);
      } else {
        debugPrint('⚠️ [NATIVO] Notificación omitida para ${hotspot.name} (ya notificado recientemente)');
      }
    } else if (status == GeofenceStatus.exit) {
      debugPrint('✅ [NATIVO] Salida detectada de ${hotspot.name}');
      instance._markHotspotAsExited(hotspot.id);
    }
  }

  /// Muestra notificación de peligro alto
  Future<void> _showHighDangerNotification(GeofenceHotspot hotspot) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_danger_alerts',
      'Alertas de Peligro Alto',
      channelDescription: 'Notificaciones para zonas de alta peligrosidad',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      color: Color(0xFFFF2100), // Rojo
      icon: '@mipmap/ic_launcher',
      actions: [
        AndroidNotificationAction(
          'activate_system',
          'Activar Sistema',
          icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        ),
      ],
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      interruptionLevel: InterruptionLevel.critical,
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      hotspot.hashCode,
      'Alerta, estás en una zona de alta peligrosidad.',
      'Activa el sistema para estar a salvo',
      details,
      payload: 'high_danger_alert:${hotspot.id}',
    );

    debugPrint('🚨 Notificación de peligro alto enviada para ${hotspot.name}');
  }

  /// Muestra notificación de peligro moderado
  Future<void> _showModerateDangerNotification(GeofenceHotspot hotspot) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'moderate_danger_alerts',
      'Alertas de Peligro Moderado',
      channelDescription: 'Notificaciones para zonas de peligrosidad moderada',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.status,
      ongoing: false,
      autoCancel: true,
      color: Color(0xFFFF8C00), // Ámbar
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      interruptionLevel: InterruptionLevel.timeSensitive,
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      hotspot.hashCode,
      'Alerta, zona de peligrosidad moderada.',
      'Activa el sistema para estar a salvo',
      details,
      payload: 'moderate_danger_alert:${hotspot.id}',
    );

    debugPrint('⚠️ Notificación de peligro moderado enviada para ${hotspot.name}');
  }

  /// Maneja el tap en las notificaciones
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('👆 Notificación tocada: ${response.payload}');
    
    if (response.payload != null) {
      final parts = response.payload!.split(':');
      if (parts.length == 2) {
        final alertType = parts[0];
        final hotspotId = parts[1];
        
        debugPrint('🎯 Tipo de alerta: $alertType, Hotspot: $hotspotId');
        
        // Aquí puedes agregar lógica adicional para manejar el tap
        // Por ejemplo, abrir la app o activar el sistema de seguridad
      }
    }
  }

  /// Detiene el monitoreo
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    debugPrint('🛑 Deteniendo monitoreo de geofencing...');
    
    await Geofencing.instance.stop();
    
    _hotspotCheckTimer?.cancel();
    _hotspotCheckTimer = null;
    
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    
    await _locationService.stopActiveLocationTracking();
    
    // Limpiar estado de notificaciones
    _notifiedHotspots.clear();
    _lastNotificationTime.clear();
    _isInHotspot.clear();
    
    _isMonitoring = false;
    debugPrint('✅ Monitoreo detenido');
  }

  /// Verifica si el usuario está dentro de algún hotspot
  Future<bool> isUserInsideHotspot() async {
    final position = await _locationService.getCurrentPosition();
    if (position == null) return false;

    for (final hotspot in hotspots) {
      final distance = _locationService.calculateDistance(
        position.latitude,
        position.longitude,
        hotspot.latitude,
        hotspot.longitude,
      );

      if (distance <= hotspot.radius) {
        return true;
      }
    }

    return false;
  }

  /// Obtiene la actividad del hotspot más cercano
  Future<String?> getUserHotspotActivity() async {
    final position = await _locationService.getCurrentPosition();
    if (position == null) return null;

    GeofenceHotspot? closestHotspot;
    double closestDistance = double.infinity;

    for (final hotspot in hotspots) {
      final distance = _locationService.calculateDistance(
        position.latitude,
        position.longitude,
        hotspot.latitude,
        hotspot.longitude,
      );

      if (distance <= hotspot.radius && distance < closestDistance) {
        closestHotspot = hotspot;
        closestDistance = distance;
      }
    }

    return closestHotspot?.activity;
  }

  /// Obtiene el estado del servicio
  Map<String, dynamic> getServiceStatus() {
    return {
      'isInitialized': _isInitialized,
      'isMonitoring': _isMonitoring,
      'locationServiceActive': _locationService.isActive,
      'lastPosition': _locationService.lastPosition?.toString(),
      'hotspotCheckTimerActive': _hotspotCheckTimer?.isActive ?? false,
      'keepAliveTimerActive': _keepAliveTimer?.isActive ?? false,
      'notifiedHotspots': _notifiedHotspots.toList(),
      'hotspotsInZone': _isInHotspot.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList(),
      'lastNotificationTimes': _lastNotificationTime.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
    };
  }

  /// Limpia recursos
  void dispose() {
    stopMonitoring();
    _locationService.dispose();
  }
}