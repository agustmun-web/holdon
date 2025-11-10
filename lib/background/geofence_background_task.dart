import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geofencing_api/geofencing_api.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/geofence_service.dart';

/// Tarea en segundo plano para manejar eventos de geofencing
/// Este archivo se ejecuta incluso cuando la aplicación está cerrada
@pragma('vm:entry-point')
Future<void> geofenceBackgroundTask(GeofenceRegion region, GeofenceStatus status, Location location) async {
  debugPrint('🔄 [BACKGROUND] Evento de geofencing procesado: ${region.id} - $status');
  
  if (GeofenceService.notificationsSuppressed) {
    debugPrint('🔇 [BACKGROUND] Evento suprimido temporalmente: ${region.id}');
    return;
  }

  // Solo procesar eventos de ENTRADA
  if (status == GeofenceStatus.enter) {
    debugPrint('🚨 [BACKGROUND] Usuario entró a zona peligrosa: ${region.id}');
    
    // Buscar el hotspot correspondiente
    try {
      final hotspot = GeofenceService.hotspots.firstWhere(
        (h) => h.id == region.id,
      );
      
      debugPrint('📍 [BACKGROUND] Hotspot encontrado: ${hotspot.activity} - ${hotspot.id}');
      
      // Disparar notificación específica según el nivel de riesgo
      await _showBackgroundNotification(hotspot);
      
      debugPrint('✅ [BACKGROUND] Notificación de alerta enviada');
    } catch (e) {
      debugPrint('❌ [BACKGROUND] Error al procesar hotspot: $e');
    }
  }
}

/// Muestra la notificación en segundo plano según el nivel de riesgo
Future<void> _showBackgroundNotification(GeofenceHotspot hotspot) async {
  final localNotifications = FlutterLocalNotificationsPlugin();
  
  // Configuración básica para notificaciones en segundo plano
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
  
  await localNotifications.initialize(settings);
  
  if (hotspot.activity == 'ALTA') {
    // Notificación para zonas de ALTA peligrosidad
    await localNotifications.show(
      hotspot.id.hashCode,
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
          color: Color(0xFFFF2100), // Color rojo
          playSound: true,
          enableVibration: true,
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
  } else if (hotspot.activity == 'MODERADA') {
    // Notificación para zonas de MODERADA peligrosidad
    await localNotifications.show(
      hotspot.id.hashCode,
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
          color: Color(0xFFFF8C00), // Color ámbar
          playSound: true,
          enableVibration: true,
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
}

/// Configuración de la tarea en segundo plano
@pragma('vm:entry-point')
void setupBackgroundTask() {
  // Configurar el callback de geofencing para tareas en segundo plano
  Geofencing.instance.addGeofenceStatusChangedListener(geofenceBackgroundTask);
  
  debugPrint('🔄 [BACKGROUND] Tarea de geofencing configurada para segundo plano');
}