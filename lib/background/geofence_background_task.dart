import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geofencing_api/geofencing_api.dart';
import '../services/geofence_service.dart';
import '../services/notification_manager.dart';
import '../services/security_service.dart';

/// Tarea en segundo plano para manejar eventos de geofencing
/// Este archivo se ejecuta incluso cuando la aplicación está cerrada
@pragma('vm:entry-point')
Future<void> geofenceBackgroundTask(GeofenceRegion region, GeofenceStatus status, Location location) async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationManager.instance.ensureInitialized();
  debugPrint('🔄 [BACKGROUND] Evento de geofencing procesado: ${region.id} - $status');
  
  if (GeofenceService.notificationsSuppressed) {
    debugPrint('🔇 [BACKGROUND] Evento suprimido temporalmente: ${region.id}');
    return;
  }

  try {
    final hotspot = GeofenceService.hotspots.firstWhere(
      (h) => h.id == region.id,
    );

    if (status == GeofenceStatus.enter) {
      debugPrint('🚨 [BACKGROUND] Usuario entró a zona peligrosa: ${hotspot.name}');
      await NotificationManager.instance.showZoneEntryNotification(
        hotspotName: hotspot.name,
        severity: hotspot.activity,
      );
      final securityService = SecurityService();
      if (!securityService.isSecurityActive) {
        final activated = await securityService.activateSecurity(showSensorValues: true);
        debugPrint(
          activated
              ? '✅ [BACKGROUND] Sistema activado automáticamente'
              : '⚠️ [BACKGROUND] No se pudo activar el sistema automáticamente',
        );
      }
      debugPrint('✅ [BACKGROUND] Notificación de entrada enviada');
    } else if (status == GeofenceStatus.exit) {
      debugPrint('✅ [BACKGROUND] Usuario salió de zona peligrosa: ${hotspot.name}');
      await NotificationManager.instance.showZoneExitNotification(
        hotspotName: hotspot.name,
      );
      debugPrint('✅ [BACKGROUND] Notificación de salida enviada');
    }
  } catch (e) {
    debugPrint('❌ [BACKGROUND] Error al procesar hotspot: $e');
  }
}

/// Configuración de la tarea en segundo plano
@pragma('vm:entry-point')
void setupBackgroundTask() {
  // Configurar el callback de geofencing para tareas en segundo plano
  Geofencing.instance.addGeofenceStatusChangedListener(geofenceBackgroundTask);
  
  debugPrint('🔄 [BACKGROUND] Tarea de geofencing configurada para segundo plano');
}