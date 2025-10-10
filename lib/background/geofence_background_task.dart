import 'package:flutter/foundation.dart';
import 'package:geofencing_api/geofencing_api.dart';
import '../services/geofence_service.dart';

/// Tarea en segundo plano para manejar eventos de geofencing
/// Este archivo se ejecuta incluso cuando la aplicación está cerrada
@pragma('vm:entry-point')
Future<void> geofenceBackgroundTask(GeofenceRegion region, GeofenceStatus status, Location location) async {
  debugPrint('🔄 [BACKGROUND] Evento de geofencing procesado: ${region.id} - $status');
  
  // Solo procesar eventos de ENTRADA
  if (status == GeofenceStatus.enter) {
    debugPrint('🚨 [BACKGROUND] Usuario entró a zona peligrosa: ${region.id}');
    
    // Buscar el hotspot correspondiente
    try {
      final hotspot = GeofenceService.hotspots.firstWhere(
        (h) => h.id == region.id,
      );
      
      debugPrint('📍 [BACKGROUND] Hotspot encontrado: ${hotspot.activity} - ${hotspot.id}');
      
      // Disparar notificación de alerta
      GeofenceService.showDangerZoneNotification(hotspot);
      
      debugPrint('✅ [BACKGROUND] Notificación de alerta enviada');
    } catch (e) {
      debugPrint('❌ [BACKGROUND] Error al procesar hotspot: $e');
    }
  }
}

/// Configuración de la tarea en segundo plano
@pragma('vm:entry-point')
void setupBackgroundTask() {
  // Configurar el callback de geofencing para tareas en segundo plano
  Geofencing.instance.addGeofenceStatusChangedListener(geofenceBackgroundTask);
  
  debugPrint('🔄 [BACKGROUND] Tarea de geofencing configurada para segundo plano');
}