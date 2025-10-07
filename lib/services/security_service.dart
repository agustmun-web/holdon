import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'anti_theft_manager.dart';

/// Servicio de seguridad que integra el AntiTheftManager con la UI
/// 
/// Este servicio maneja la lógica de alarma y proporciona métodos
/// para interactuar con el sistema de detección antirrobo.
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();
  
  final AntiTheftManager _antiTheftManager = AntiTheftManager();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAlarmActive = false;
  
  // Platform Channel para bloqueo de dispositivo
  static const MethodChannel _platformChannel = MethodChannel('holdon.device_lock');
  
  /// Verifica si el sistema de seguridad está activo
  bool get isSecurityActive => _antiTheftManager.isActive;
  
  /// Verifica si la alarma está sonando
  bool get isAlarmActive => _isAlarmActive;
  
  /// Verifica si la aplicación tiene permisos de administrador de dispositivos
  Future<bool> get isDeviceAdminActive async {
    try {
      final bool isActive = await _platformChannel.invokeMethod('isAdminActive');
      return isActive;
    } catch (e) {
      print('❌ Error al verificar permisos de administrador: $e');
      return false;
    }
  }
  
  /// Activa el sistema de seguridad
  /// 
  /// [showSensorValues] - Si mostrar valores de sensores en terminal (default: true)
  void activateSecurity({bool showSensorValues = true}) async {
    if (_antiTheftManager.isActive) {
      print('⚠️ El sistema de seguridad ya está activo');
      return;
    }
    
    // Verificar permisos de administrador antes de activar
    final bool hasAdminPermissions = await isDeviceAdminActive;
    if (!hasAdminPermissions) {
      print('⚠️ Permisos de administrador no otorgados. Solicitando permisos...');
      await _requestAdminPermission();
    }
    
    try {
      _antiTheftManager.activateSecurity(
        callbacks: _SecurityCallbacks(this),
        showSensorValues: showSensorValues,
      );
      print('✅ Sistema de seguridad activado exitosamente');
    } catch (e) {
      print('❌ Error al activar sistema de seguridad: $e');
    }
  }
  
  /// Desactiva el sistema de seguridad
  void deactivateSecurity() {
    _antiTheftManager.deactivateSecurity();
    _isAlarmActive = false;
    print('✅ Sistema de seguridad desactivado');
  }
  
  /// Detiene manualmente la alarma
  void stopAlarm() {
    if (_isAlarmActive) {
      _isAlarmActive = false;
      Vibration.cancel();
      _audioPlayer.stop();
      print('🔕 Alarma detenida manualmente');
    }
  }
  
  /// Detiene la alarma sin desactivar el sistema de seguridad
  Future<void> stopAlarmOnly() async {
    await _antiTheftManager.stopAlarm();
  }

  /// Reinicia la detección manualmente
  Future<void> restartDetection() async {
    await _antiTheftManager.restartDetection();
  }

  /// Obtiene el estado actual de los sensores
  Future<Map<String, dynamic>?> getSensorStatus() async {
    return await _antiTheftManager.getSensorStatus();
  }
  
  /// Solicita permisos de administrador de dispositivos (método público)
  Future<void> requestAdminPermission() async {
    await _requestAdminPermission();
  }
  
  
  /// Solicita permisos de administrador de dispositivos
  Future<void> _requestAdminPermission() async {
    try {
      await _platformChannel.invokeMethod('requestAdminPermission');
      print('📋 Solicitud de permisos de administrador enviada');
    } catch (e) {
      print('❌ Error al solicitar permisos de administrador: $e');
    }
  }
  
  /// Bloquea el dispositivo usando Platform Channel
  Future<void> _lockDeviceNative() async {
    try {
      // Verificar permisos antes de intentar bloquear
      final bool hasPermissions = await isDeviceAdminActive;
      if (!hasPermissions) {
        print('⚠️ No se puede bloquear: permisos de administrador no otorgados');
        return;
      }
      
      // Llamar al método nativo de Android para bloquear la pantalla
      await _platformChannel.invokeMethod('lockDevice');
      print('📱 Dispositivo bloqueado usando Platform Channel');
    } catch (e) {
      print('❌ Error al bloquear dispositivo nativo: $e');
      rethrow;
    }
  }
  
  /// Libera los recursos del servicio
  void dispose() {
    _antiTheftManager.dispose();
    _audioPlayer.dispose();
  }
}

/// Implementación de AlarmCallbacks para el SecurityService
class _SecurityCallbacks implements AlarmCallbacks {
  final SecurityService _service;
  
  _SecurityCallbacks(this._service);
  
  @override
  void onAlarmTriggered() {
    _service._isAlarmActive = true;
    
    // Activar vibración continua
    Vibration.vibrate(duration: 10000); // 10 segundos
    
    // Reproducir sonido de alarma
    _playAlarmSound();
    
    
    // Aquí se podría agregar más lógica:
    // - Mostrar notificación
    // - Enviar ubicación
    // - Tomar foto con la cámara
    // - Enviar SMS de emergencia
    
    print('🚨 ALARMA ACTIVADA - Dispositivo posiblemente robado');
  }
  
  /// Reproduce el sonido de alarma en bucle
  Future<void> _playAlarmSound() async {
    try {
      await _service._audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _service._audioPlayer.play(AssetSource('sounds/alarm.wav'));
      print('🔊 Sonido de alarma iniciado');
    } catch (e) {
      print('❌ Error al reproducir sonido de alarma: $e');
    }
  }
  
  @override
  void onAlarmStopped() {
    _service._isAlarmActive = false;
    Vibration.cancel();
    _service._audioPlayer.stop();
    print('🔕 Alarma detenida - Sistema de seguridad sigue activo');
  }
  
  @override
  Future<void> lockDevice() async {
    try {
      // Intentar bloquear la pantalla usando el método nativo
      await _service._lockDeviceNative();
      print('🔒 Dispositivo bloqueado desde callback');
    } catch (e) {
      print('❌ Error al bloquear dispositivo desde callback: $e');
    }
  }
}
