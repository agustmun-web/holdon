import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationManager {
  NotificationManager._();
  static final NotificationManager instance = NotificationManager._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _entryChannelId = 'danger_zone_entry';
  static const String _entryChannelName = 'Alertas de entrada a zonas';
  static const String _exitChannelId = 'danger_zone_exit';
  static const String _exitChannelName = 'Alertas de salida de zonas';

  Future<void> ensureInitialized() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);

    const AndroidNotificationChannel entryChannel = AndroidNotificationChannel(
      _entryChannelId,
      _entryChannelName,
      description: 'Notificaciones al entrar en zonas de peligro',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel exitChannel = AndroidNotificationChannel(
      _exitChannelId,
      _exitChannelName,
      description: 'Notificaciones al salir de zonas de peligro',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(entryChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(exitChannel);

    _initialized = true;
  }

  Future<void> showZoneEntryNotification({
    required String hotspotName,
    required String severity,
  }) async {
    await ensureInitialized();
    final bool isHigh = severity.toUpperCase() == 'ALTA';
    final String title = isHigh
        ? 'Has entrado en una zona de alto riesgo'
        : 'Has entrado en una zona de riesgo moderado';
    final String body =
        'La zona "$hotspotName" está activada. El sistema de seguridad está en funcionamiento.';

    await _notificationsPlugin.show(
      'entry_$hotspotName'.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _entryChannelId,
          _entryChannelName,
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          autoCancel: true,
        ),
        iOS: const DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.critical,
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'zone_entry:$hotspotName',
    );
  }

  Future<void> showZoneExitNotification({
    required String hotspotName,
  }) async {
    await ensureInitialized();
    const String title =
        'Has salido de la zona de peligro';
    final String body =
        '¿Quieres desactivar el sistema? Abre la aplicación para decidir. Zona: "$hotspotName".';

    await _notificationsPlugin.show(
      'exit_$hotspotName'.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _exitChannelId,
          _exitChannelName,
          importance: Importance.high,
          priority: Priority.high,
          autoCancel: true,
        ),
        iOS: const DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.timeSensitive,
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'zone_exit:$hotspotName',
    );
  }
}

