import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('es'),
    Locale('en'),
  ];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'app.title': {
      'es': 'HoldOn! Anti-Theft App',
      'en': 'HoldOn! Anti-Theft App',
    },
    'tab.security': {
      'es': 'Seguridad',
      'en': 'Security',
    },
    'tab.map': {
      'es': 'Mapa',
      'en': 'Map',
    },
    'tab.zones': {
      'es': 'Zonas',
      'en': 'Zones',
    },
    'tab.history': {
      'es': 'Historial',
      'en': 'History',
    },
    'settings.title': {
      'es': 'Configuración',
      'en': 'Settings',
    },
    'settings.section.general': {
      'es': 'General',
      'en': 'General',
    },
    'settings.section.diagnostics': {
      'es': 'Diagnóstico',
      'en': 'Diagnostics',
    },
    'settings.option.notifications': {
      'es': 'Notificaciones push',
      'en': 'Push notifications',
    },
    'settings.option.notifications.subtitle': {
      'es': 'Recibir alertas del sistema en tiempo real',
      'en': 'Receive real-time system alerts',
    },
    'settings.option.vibration': {
      'es': 'Vibración',
      'en': 'Vibration',
    },
    'settings.option.vibration.subtitle': {
      'es': 'Activar vibración en alarmas y avisos',
      'en': 'Enable vibration for alarms and alerts',
    },
    'settings.option.darkmode': {
      'es': 'Modo oscuro',
      'en': 'Dark mode',
    },
    'settings.option.darkmode.subtitle': {
      'es': 'Mantener la interfaz en modo oscuro',
      'en': 'Keep the interface in dark mode',
    },
    'settings.option.language': {
      'es': 'Idioma',
      'en': 'Language',
    },
    'settings.option.language.subtitle': {
      'es': 'Selecciona el idioma de la aplicación',
      'en': 'Choose the application language',
    },
    'settings.option.language.es': {
      'es': 'Español',
      'en': 'Spanish',
    },
    'settings.option.language.en': {
      'es': 'Inglés',
      'en': 'English',
    },
    'settings.option.sensorTest': {
      'es': 'Prueba de sensores',
      'en': 'Sensor test',
    },
    'settings.option.sensorTest.subtitle': {
      'es': 'Ver valores de sensores en tiempo real',
      'en': 'See real-time sensor values',
    },
    'security.title': {
      'es': 'Seguridad',
      'en': 'Security',
    },
    'security.status.safe': {
      'es': 'Seguro',
      'en': 'Safe',
    },
    'security.status.safe.title': {
      'es': 'Zona segura',
      'en': 'Safe zone',
    },
    'security.status.safe.subtitle': {
      'es': 'Sin hotspots cercanos • Todo en orden',
      'en': 'No nearby hotspots • All clear',
    },
    'security.status.high': {
      'es': 'Alta',
      'en': 'High',
    },
    'security.status.high.title': {
      'es': 'Zona de alta actividad',
      'en': 'High activity zone',
    },
    'security.status.high.subtitle': {
      'es': 'Alerta, zona con alta peligrosidad',
      'en': 'Alert, high risk area',
    },
    'security.status.medium': {
      'es': 'Media',
      'en': 'Medium',
    },
    'security.status.medium.title': {
      'es': 'Zona de actividad moderada',
      'en': 'Moderate activity zone',
    },
    'security.status.medium.subtitle': {
      'es': 'Precaución, zona con peligrosidad moderada',
      'en': 'Caution, moderate risk area',
    },
    'security.system.paused': {
      'es': 'Monitoreo pausado',
      'en': 'Monitoring paused',
    },
    'security.system.active': {
      'es': 'Sistema seguro y monitoreando',
      'en': 'System secure and monitoring',
    },
    'security.system.alarm': {
      'es': 'Dispositivo posiblemente robado',
      'en': 'Device possibly stolen',
    },
    'security.deactivated.title': {
      'es': 'Sistema desactivado',
      'en': 'System deactivated',
    },
    'security.deactivated.description': {
      'es': 'Todos los sensores han sido desactivados, no recibirás alertas hasta reactivar el sistema',
      'en': 'All sensors are currently off, you will not receive alerts until the system is reactivated',
    },
    'security.deactivated.schedule': {
      'es': 'Programar reactivación',
      'en': 'Schedule reactivation',
    },
    'security.deactivated.reactivate': {
      'es': 'Reactivar',
      'en': 'Reactivate',
    },
    'security.sensitivity.title': {
      'es': 'Sensibilidad',
      'en': 'Sensitivity',
    },
    'security.sensitivity.description': {
      'es': 'Ajusta la sensibilidad del sistema',
      'en': 'Adjust system sensitivity',
    },
    'security.sensitivity.low': {
      'es': 'Baja',
      'en': 'Low',
    },
    'security.sensitivity.normal': {
      'es': 'Normal',
      'en': 'Normal',
    },
    'security.sensitivity.high': {
      'es': 'Alta',
      'en': 'High',
    },
    'security.central.state.alarm': {
      'es': 'Alarma activada',
      'en': 'Alarm active',
    },
    'security.central.state.active': {
      'es': 'Activo',
      'en': 'Active',
    },
    'security.central.state.paused': {
      'es': 'Monitoreo pausado',
      'en': 'Monitoring paused',
    },
    'security.central.action.alarm': {
      'es': 'Toque para detener alarma',
      'en': 'Tap to stop alarm',
    },
    'security.central.action.deactivate': {
      'es': 'Toque para desactivar',
      'en': 'Tap to deactivate',
    },
    'security.central.action.activate': {
      'es': 'Toque para activar',
      'en': 'Tap to activate',
    },
    'security.schedule.dialog.title': {
      'es': 'Programar Reactivación',
      'en': 'Schedule Reactivation',
    },
    'security.schedule.dialog.description': {
      'es': 'Selecciona la hora para reactivar el sistema:',
      'en': 'Choose the time to reactivate the system:',
    },
    'security.schedule.dialog.pick': {
      'es': 'Seleccionar hora',
      'en': 'Pick a time',
    },
    'common.accept': {
      'es': 'Aceptar',
      'en': 'OK',
    },
    'common.cancel': {
      'es': 'Cancelar',
      'en': 'Cancel',
    },
    'common.delete': {
      'es': 'Eliminar',
      'en': 'Delete',
    },
    'common.retry': {
      'es': 'Reintentar',
      'en': 'Retry',
    },
    'common.schedule': {
      'es': 'Programar',
      'en': 'Schedule',
    },
    'security.schedule.confirmation': {
      'es': 'Reactivación programada para las {time}',
      'en': 'Reactivation scheduled for {time}',
    },
    'security.schedule.notification': {
      'es': 'Sistema reactivado automáticamente',
      'en': 'System reactivated automatically',
    },
    'map.loading.error': {
      'es': 'Error al inicializar el mapa: {error}',
      'en': 'Error while loading the map: {error}',
    },
    'map.retry': {
      'es': 'Reintentar',
      'en': 'Retry',
    },
    'map.hotspot.title': {
      'es': 'Zona de Hotspot',
      'en': 'Hotspot Zone',
    },
    'map.hotspot.activity': {
      'es': 'Nivel de Actividad: {activity}',
      'en': 'Activity level: {activity}',
    },
    'map.hotspot.radius': {
      'es': 'Radio: {meters} metros',
      'en': 'Radius: {meters} meters',
    },
    'map.hotspot.alert.high': {
      'es': '⚠️ Zona de alta actividad - Ten precaución',
      'en': '⚠️ High activity area - Stay alert',
    },
    'map.hotspot.alert.medium': {
      'es': '⚠️ Zona de actividad moderada - Mantente alerta',
      'en': '⚠️ Moderate activity area - Be cautious',
    },
    'map.default.hotspot.guardia_civil': {
      'es': 'Edificio Guardia Civil',
      'en': 'Guardia Civil Building',
    },
    'map.default.hotspot.hermanitas_pobres': {
      'es': 'Hermanitas de los Pobres',
      'en': 'Little Sisters of the Poor',
    },
    'map.default.hotspot.claret': {
      'es': 'Claret',
      'en': 'Claret',
    },
    'map.default.hotspot.camino_ie': {
      'es': 'Camino IE',
      'en': 'IE Path',
    },
    'zones.title': {
      'es': 'Zonas personalizadas',
      'en': 'Custom zones',
    },
    'zones.empty.title': {
      'es': 'Sin zonas guardadas',
      'en': 'No zones saved',
    },
    'zones.empty.subtitle': {
      'es': 'Crea una zona manteniendo pulsado sobre el mapa para verla aquí.',
      'en': 'Create a zone with a long press on the map to see it here.',
    },
    'zones.item.type': {
      'es': 'Tipo: {type}',
      'en': 'Type: {type}',
    },
    'zones.item.radius': {
      'es': 'Radio: {meters} m',
      'en': 'Radius: {meters} m',
    },
    'zones.item.coordinates': {
      'es': 'Lat: {lat}, Lng: {lng}',
      'en': 'Lat: {lat}, Lng: {lng}',
    },
    'zones.delete.confirm.title': {
      'es': 'Eliminar zona',
      'en': 'Delete zone',
    },
    'zones.delete.confirm.message': {
      'es': '¿Quieres eliminar la zona "{name}"?',
      'en': 'Do you want to delete the "{name}" zone?',
    },
    'zones.delete.success': {
      'es': 'Zona eliminada',
      'en': 'Zone deleted',
    },
    'zones.delete.error': {
      'es': 'No se pudo eliminar la zona: {error}',
      'en': 'Could not delete the zone: {error}',
    },
    'zones.load.error': {
      'es': 'No se pudieron cargar las zonas: {error}',
      'en': 'Could not load zones: {error}',
    },
    'sensor.title': {
      'es': 'Prueba de Sensores',
      'en': 'Sensor Test',
    },
    'sensor.section.status': {
      'es': 'Estado del Sistema',
      'en': 'System Status',
    },
    'sensor.security.active': {
      'es': 'Seguridad: ACTIVA',
      'en': 'Security: ACTIVE',
    },
    'sensor.security.inactive': {
      'es': 'Seguridad: INACTIVA',
      'en': 'Security: INACTIVE',
    },
    'sensor.alarm.on': {
      'es': 'Alarma: SONANDO',
      'en': 'Alarm: TRIGGERED',
    },
    'sensor.alarm.off': {
      'es': 'Alarma: SILENCIOSA',
      'en': 'Alarm: SILENT',
    },
    'sensor.section.instructions': {
      'es': 'Instrucciones',
      'en': 'Instructions',
    },
    'sensor.instructions.body': {
      'es': '1. Presiona "Activar Seguridad" para iniciar la detección\n2. Los valores de los sensores aparecerán en el terminal\n3. Mueve el dispositivo bruscamente para probar la detección\n4. Los umbrales son: Aceleración > 50 m/s², Giroscopio > 9 rad/s',
      'en': '1. Press "Activate Security" to start detection\n2. Sensor values appear in the terminal\n3. Move the device sharply to test detection\n4. Thresholds: Acceleration > 50 m/s², Gyroscope > 9 rad/s',
    },
    'sensor.button.toggle.active': {
      'es': 'Desactivar Seguridad',
      'en': 'Deactivate Security',
    },
    'sensor.button.toggle.inactive': {
      'es': 'Activar Seguridad',
      'en': 'Activate Security',
    },
    'sensor.button.stop.alarm': {
      'es': 'Detener Alarma',
      'en': 'Stop Alarm',
    },
    'sensor.section.info': {
      'es': 'Información',
      'en': 'Information',
    },
    'sensor.info.body': {
      'es': 'Los valores de los sensores se muestran cada 10 eventos en el terminal. Observa la consola para ver los datos en tiempo real.',
      'en': 'Sensor values are printed to the terminal every 10 events. Watch the console for live data.',
    },
  };

  String translate(String key, {Map<String, String>? params}) {
    final languageCode = locale.languageCode;
    final values = _localizedValues[key];
    if (values == null) {
      return key;
    }
    String? value = values[languageCode] ?? values['en'] ?? values.values.first;
    if (params != null && params.isNotEmpty) {
      params.forEach((paramKey, paramValue) {
        value = value!.replaceAll('{$paramKey}', paramValue);
      });
    }
    return value ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .any((supportedLocale) => supportedLocale.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

extension AppLocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

