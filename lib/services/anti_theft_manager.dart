import 'dart:async';
import 'package:flutter/services.dart';

/// Interfaz para manejar las callbacks de alarma
abstract class AlarmCallbacks {
  /// Se llama cuando se detecta un robo y se debe activar la alarma
  void onAlarmTriggered();
  
  /// Se llama cuando se debe detener la alarma
  void onAlarmStopped();
  
  /// Se llama para bloquear la pantalla del dispositivo
  Future<void> lockDevice();
}

/// Manager principal para el sistema de detección antirrobo
/// 
/// Esta clase maneja el control del Foreground Service que ejecuta
/// la detección de sensores en segundo plano continuo.
class AntiTheftManager {
  // Callbacks de alarma
  AlarmCallbacks? _alarmCallbacks;
  
  // Platform Channels para comunicación con Android
  static const MethodChannel _platformChannel = MethodChannel('holdon.device_lock');
  static const EventChannel _serviceEventChannel = EventChannel('holdon.service_events');
  static const EventChannel _volumeEventChannel = EventChannel('holdon.volume_monitor');
  
  // Stream de eventos del servicio y volumen
  StreamSubscription<dynamic>? _serviceSubscription;
  StreamSubscription<dynamic>? _volumeSubscription;
  
  // Estado del sistema
  bool _isActive = false;
  bool _isAlarmActive = false;
  bool _showSensorValues = true; // Mostrar valores de sensores en terminal
  int _pocketGraceSeconds = 5;
  bool _pocketGraceLoaded = false;
  
  /// Verifica si el sistema de seguridad está activo
  bool get isActive => _isActive;
  
  /// Verifica si la alarma está activa
  bool get isAlarmActive => _isAlarmActive;
  
  /// Detiene la alarma sin desactivar el sistema de seguridad
  Future<void> stopAlarm() async {
    if (!_isAlarmActive) {
      print('⚠️ No hay alarma activa para detener');
      return;
    }
    
    try {
      await _platformChannel.invokeMethod('stopAlarm');
      // Actualizar estado inmediatamente para la UI
      _isAlarmActive = false;
      _alarmCallbacks?.onAlarmStopped();
      print('🔕 Alarma detenida - Sistema de seguridad sigue activo');
    } catch (e) {
      print('❌ Error al detener la alarma: $e');
    }
  }
  
  /// Activa el sistema de detección antirrobo
  /// 
  /// [callbacks] - Interfaz con los métodos para manejar las alarmas
  /// [showSensorValues] - Si mostrar valores de sensores en terminal (default: true)
  /// 
  /// Lanza [StateError] si el sistema ya está activo
  Future<void> activateSecurity({
    required AlarmCallbacks callbacks,
    bool showSensorValues = true,
  }) async {
    if (_isActive) {
      throw StateError('El sistema de seguridad ya está activo');
    }
    
    _alarmCallbacks = callbacks;
    _isActive = true;
    _showSensorValues = showSensorValues;
    
    await _ensurePocketGraceSecondsLoaded();
    
    // Iniciar Foreground Service
    await _startForegroundService();

    // Iniciar escucha de eventos del servicio
    _startServiceEventListening();

    // Iniciar monitoreo de volumen
    _startVolumeMonitoring();

    print('🛡️ Sistema de seguridad antirrobo activado');
    if (_showSensorValues) {
      print('📊 Mostrando valores de sensores cada 10 eventos');
      print('🎯 Umbrales: Aceleración > 50.0m/s², Giroscopio > 9.0rad/s');
      print('─' * 60);
    }
  }
  
  /// Desactiva el sistema de detección antirrobo
  /// 
  /// Cancela todas las suscripciones y llama al callback de detención
  void deactivateSecurity() {
    if (!_isActive) {
      return; // Ya está desactivado
    }
    
    // Detener Foreground Service
    _stopForegroundService();

    // Detener escucha de eventos del servicio
    _stopServiceEventListening();

    // Detener monitoreo de volumen
    _stopVolumeMonitoring();
    
    // Llamar al callback de detención si existe
    _alarmCallbacks?.onAlarmStopped();
    
    // Limpiar estado
    _alarmCallbacks = null;
    _isActive = false;
    _isAlarmActive = false;
    
    print('🔒 Sistema de seguridad antirrobo desactivado');
  }
  
  /// Inicia el Foreground Service
  Future<void> _startForegroundService() async {
    try {
      await _platformChannel.invokeMethod('startForegroundService', {
        'showSensorValues': _showSensorValues,
        'pocketGraceSeconds': _pocketGraceSeconds,
      });
      print('🚀 Foreground Service iniciado');
    } catch (e) {
      print('❌ Error al iniciar Foreground Service: $e');
      throw e;
    }
  }
  
  /// Detiene el Foreground Service
  Future<void> _stopForegroundService() async {
    try {
      await _platformChannel.invokeMethod('stopForegroundService');
      print('🛑 Foreground Service detenido');
    } catch (e) {
      print('❌ Error al detener Foreground Service: $e');
    }
  }
  
  /// Inicia la escucha de eventos del servicio
  void _startServiceEventListening() {
    try {
      _serviceSubscription = _serviceEventChannel.receiveBroadcastStream().listen(
        _onServiceEvent,
        onError: _onServiceError,
      );
      print('📡 Escucha de eventos del servicio iniciada');
    } catch (e) {
      print('❌ Error al iniciar escucha de eventos: $e');
    }
  }
  
  /// Detiene la escucha de eventos del servicio
  void _stopServiceEventListening() {
    _serviceSubscription?.cancel();
    _serviceSubscription = null;
    print('📡 Escucha de eventos del servicio detenida');
  }

  /// Inicia el monitoreo de volumen
  void _startVolumeMonitoring() {
    _volumeSubscription = _volumeEventChannel.receiveBroadcastStream().listen(
      _onVolumeEvent,
      onError: _onVolumeError,
    );
    print('🔊 Monitoreo de volumen iniciado');
  }

  /// Detiene el monitoreo de volumen
  void _stopVolumeMonitoring() {
    _volumeSubscription?.cancel();
    _volumeSubscription = null;
    print('🔊 Monitoreo de volumen detenido');
  }
  
  /// Maneja eventos del servicio
  void _onServiceEvent(dynamic event) {
    if (event is Map) {
      final String type = event['type'] ?? '';
      
      switch (type) {
        case 'sensor_data':
          _handleSensorData(event);
          break;
        case 'alarm_triggered':
          _handleAlarmTriggered();
          break;
        case 'alarm_stopped':
          _handleAlarmStopped();
          break;
        case 'service_started':
          print('✅ Servicio de detección iniciado en segundo plano');
          break;
        case 'service_stopped':
          print('🛑 Servicio de detección detenido');
          break;
        default:
          print('📨 Evento del servicio: $event');
      }
    }
  }
  
  /// Maneja datos de sensores del servicio
  void _handleSensorData(Map event) {
    if (!_showSensorValues) return;
    
    final String sensorType = event['sensorType'] ?? '';
    final double x = (event['x'] ?? 0.0).toDouble();
    final double y = (event['y'] ?? 0.0).toDouble();
    final double z = (event['z'] ?? 0.0).toDouble();
    final double magnitude = (event['magnitude'] ?? 0.0).toDouble();
    final int eventCount = event['eventCount'] ?? 0;
    
    if (eventCount % 10 == 0) { // Mostrar cada 10 eventos
      String timestamp = DateTime.now().toIso8601String().substring(11, 23);
      String status = magnitude > (sensorType == 'accelerometer' ? 50.0 : 9.0) ? '🚨 ALERTA' : '✅ Normal';
      
      print('📱 [$timestamp] ${sensorType == 'accelerometer' ? 'Acelerómetro' : 'Giroscopio'} (Evento #$eventCount)');
      print('   X: ${x.toStringAsFixed(3)} ${sensorType == 'accelerometer' ? 'm/s²' : 'rad/s'}');
      print('   Y: ${y.toStringAsFixed(3)} ${sensorType == 'accelerometer' ? 'm/s²' : 'rad/s'}');
      print('   Z: ${z.toStringAsFixed(3)} ${sensorType == 'accelerometer' ? 'm/s²' : 'rad/s'}');
      print('   Magnitud: ${magnitude.toStringAsFixed(3)} ${sensorType == 'accelerometer' ? 'm/s²' : 'rad/s'} $status');
      print('');
    }
  }
  
  /// Maneja activación de alarma desde el servicio
  void _handleAlarmTriggered() {
    if (!_isActive) return;
    
    print('🚨🚨🚨 ALARMA ACTIVADA - POSIBLE ROBO DETECTADO 🚨🚨🚨');
    
    // Marcar alarma como activa
    _isAlarmActive = true;
    
    // Llamar al callback de alarma
    _alarmCallbacks?.onAlarmTriggered();
    
    // Bloquear la pantalla del dispositivo
    _lockDevice();
  }
  
  /// Maneja detención de alarma desde el servicio
  void _handleAlarmStopped() {
    // Solo actualizar si no se ha actualizado ya
    if (_isAlarmActive) {
      _isAlarmActive = false;
      _alarmCallbacks?.onAlarmStopped();
      print('🔕 Alarma detenida desde el servicio - Sistema reactivado');
    }
  }
  
  /// Maneja errores del servicio
  void _onServiceError(dynamic error) {
    print('❌ Error en servicio: $error');
    // En caso de error, desactivar el sistema por seguridad
    deactivateSecurity();
  }
  
  /// Bloquea la pantalla del dispositivo usando Platform Channel
  Future<void> _lockDevice() async {
    try {
      // Llamar al método nativo de Android para bloquear la pantalla
      await _platformChannel.invokeMethod('lockDevice');
      print('📱 Pantalla del dispositivo bloqueada');
    } catch (e) {
      print('❌ Error al bloquear la pantalla: $e');
      // Si falla el bloqueo nativo, intentar con el método de callback
      try {
        await _alarmCallbacks?.lockDevice();
      } catch (callbackError) {
        print('❌ Error en callback de bloqueo: $callbackError');
      }
    }
  }
  
  /// Maneja eventos de volumen
  void _onVolumeEvent(dynamic event) {
    if (event is Map) {
      final String type = event['type'] as String? ?? '';
      
      switch (type) {
        case 'volume_monitoring_started':
          print('✅ Monitoreo de volumen iniciado');
          break;
        case 'volume_changed':
          _handleVolumeChange(event);
          break;
        case 'ringer_mode_changed':
          _handleRingerModeChange(event);
          break;
        default:
          print('ℹ️ Evento de volumen desconocido: $event');
      }
    }
  }

  /// Maneja cambios de volumen
  void _handleVolumeChange(Map<dynamic, dynamic> event) {
    final String streamTypeText = event['streamTypeText'] as String? ?? 'DESCONOCIDO';
    final int volume = event['volume'] as int? ?? 0;
    final int previousVolume = event['previousVolume'] as int? ?? 0;
    final bool volumeDecreased = event['volumeDecreased'] as bool? ?? false;
    
    print('🔊 Volumen $streamTypeText: $previousVolume -> $volume');
    
    // Si la alarma está activa y el volumen disminuyó, restaurar volumen máximo
    if (_isAlarmActive && volumeDecreased) {
      print('🚨 Volumen disminuido durante alarma - Restaurando volumen máximo');
      _setAlarmVolumeMax();
    }
  }

  /// Maneja cambios de modo de sonido
  void _handleRingerModeChange(Map<dynamic, dynamic> event) {
    final String ringerModeText = event['ringerModeText'] as String? ?? 'DESCONOCIDO';
    final int ringerMode = event['ringerMode'] as int? ?? 0;
    
    print('🔇 Modo de sonido cambió a: $ringerModeText');
    
    // Si la alarma está activa y el modo cambió a silencio, restaurar modo normal
    if (_isAlarmActive && ringerModeText == 'SILENCIO') {
      print('🚨 Modo silencioso activado durante alarma - Restaurando modo normal');
      _setAlarmVolumeMax();
    }
  }

  /// Establece el volumen de alarma al máximo
  Future<void> _setAlarmVolumeMax() async {
    try {
      await _platformChannel.invokeMethod('setAlarmVolumeMax');
      print('🔊 Volumen de alarma restaurado al máximo');
    } catch (e) {
      print('❌ Error al restaurar volumen de alarma: $e');
    }
  }

  /// Maneja errores del monitoreo de volumen
  void _onVolumeError(dynamic error) {
    print('❌ Error en monitoreo de volumen: $error');
  }

  /// Reinicia la detección manualmente
  Future<void> restartDetection() async {
    try {
      await _platformChannel.invokeMethod('restartDetection');
      print('🔄 Detección reiniciada manualmente');
    } catch (e) {
      print('❌ Error al reiniciar detección: $e');
    }
  }
  
  Future<int> getPocketGraceSeconds() async {
    await _ensurePocketGraceSecondsLoaded();
    return _pocketGraceSeconds;
  }
  
  Future<void> setPocketGraceSeconds(int seconds) async {
    final clamped = seconds.clamp(3, 10).toInt();
    _pocketGraceSeconds = clamped;
    _pocketGraceLoaded = true;
    try {
      await _platformChannel.invokeMethod('setPocketGraceSeconds', {
        'seconds': clamped,
      });
      print('🛡️ Temporizador de bolsillo configurado a $clamped segundos');
    } catch (e) {
      print('❌ Error al configurar temporizador de bolsillo: $e');
    }
  }

  Future<void> _ensurePocketGraceSecondsLoaded() async {
    if (_pocketGraceLoaded) return;
    try {
      final result = await _platformChannel.invokeMethod<int>('getPocketGraceSeconds');
      if (result != null) {
        _pocketGraceSeconds = result.clamp(3, 10).toInt();
      }
    } catch (e) {
      print('❌ Error al obtener temporizador de bolsillo almacenado: $e');
    }
    _pocketGraceLoaded = true;
  }

  /// Obtiene el estado actual de los sensores
  Future<Map<String, dynamic>?> getSensorStatus() async {
    try {
      final status = await _platformChannel.invokeMethod('getSensorStatus');
      print('📊 Estado de sensores: $status');
      return Map<String, dynamic>.from(status);
    } catch (e) {
      print('❌ Error al obtener estado de sensores: $e');
      return null;
    }
  }

  /// Libera los recursos del manager
  ///
  /// Debe ser llamado cuando el manager ya no se necesite
  void dispose() {
    deactivateSecurity();
    _serviceSubscription?.cancel();
    _volumeSubscription?.cancel();
    print('🗑️ AntiTheftManager disposed');
  }
}

/// Implementación de ejemplo de AlarmCallbacks
/// 
/// Esta clase puede ser usada como referencia o base para implementar
/// las callbacks de alarma en la UI.
class ExampleAlarmCallbacks implements AlarmCallbacks {
  @override
  void onAlarmTriggered() {
    print('🔔 Alarma activada - Implementar lógica de alarma aquí');
    // Aquí se podría:
    // - Reproducir sonido de alarma
    // - Activar vibración
    // - Mostrar notificación
    // - Enviar ubicación
    // - Tomar foto
  }
  
  @override
  void onAlarmStopped() {
    print('🔕 Alarma detenida - Implementar lógica de detención aquí');
    // Aquí se podría:
    // - Detener sonido de alarma
    // - Detener vibración
    // - Ocultar notificación
    // - Guardar evento en historial
  }
  
  @override
  Future<void> lockDevice() async {
    print('🔒 Bloqueo de dispositivo - Implementar lógica de bloqueo aquí');
    // Aquí se podría:
    // - Llamar a Platform Channel
    // - Usar APIs nativas
    // - Implementar bloqueo personalizado
  }
}