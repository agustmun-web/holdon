import 'package:flutter/material.dart';
import '../widgets/activity_card.dart';
import '../widgets/central_control.dart';
import '../widgets/feature_control_card.dart';
import '../widgets/map_preview.dart';
import '../widgets/deactivated_system_widget.dart';
import '../services/security_service.dart';
import 'sensor_test_screen.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool isActive = true;
  String sirenLevel = 'Medio';
  bool vibrationEnabled = true;
  int sensitivity = 70;
  bool _isMenuOpen = false;
  
  // Servicio de seguridad
  final SecurityService _securityService = SecurityService();
  
  // Callback para activar animaciones del botón central
  VoidCallback? _onCentralButtonAnimation;
  
  // Estado de permisos de administrador
  bool _hasAdminPermissions = false;
  
  // Variables para programación de reactivación
  TimeOfDay? _selectedTime;
  Timer? _reactivationTimer;
  Timer? _uiUpdateTimer;

  @override
  void initState() {
    super.initState();
    _checkAdminPermissions();
    // Activar el sistema de seguridad al inicializar la pantalla
    _securityService.activateSecurity(showSensorValues: true);
    
    // Timer para actualizar la UI cada segundo (para mostrar estado de alarma)
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }
  
  /// Verifica si la aplicación tiene permisos de administrador
  Future<void> _checkAdminPermissions() async {
    final bool hasPermissions = await _securityService.isDeviceAdminActive;
    if (mounted) {
      setState(() {
        _hasAdminPermissions = hasPermissions;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isActive ? const Color(0xFFE1F4ED) : const Color(0xFFFFF5F5),
      body: Stack(
        children: [
          // Contenido principal
          _buildMainContent(),
          // Overlay para cerrar menú al tocar fuera
          if (_isMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isMenuOpen = false;
                  });
                },
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          // Menú popup
          if (_isMenuOpen)
            _buildSirenMenu(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
          // Header personalizado compacto
          Container(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 8),
            child: Stack(
              children: [
                // Título centrado
                const Center(
                  child: Text(
                    'Seguridad',
                    style: TextStyle(
                      color: Color(0xFF202124),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Botón de ajustes alineado a la derecha
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () {
                      _showSettingsMenu();
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE1F4ED),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: Color(0xFF34A853),
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Contenido principal
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card de actividad reciente
                  const ActivityCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Control central
                  Center(
                    child: CentralControl(
                      isActive: isActive,
                      onTap: () {
                        // Callback del botón principal - cambiar estado a Pausado/Inactivo
                        setState(() {
                          isActive = !isActive;
                        });
                        
                        // Activar/desactivar el sistema de seguridad real
                        if (isActive) {
                          _securityService.activateSecurity(showSensorValues: true);
                        } else {
                          _securityService.deactivateSecurity();
                        }
                      },
                      onAnimationCallback: (callback) {
                        _onCentralButtonAnimation = callback;
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Estado del sistema
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFF38B05F) : const Color(0xFFFF5B5B),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isActive ? 'Sistema seguro y monitoreando' : 'Monitoreo pausado',
                              style: TextStyle(
                                color: Color(0xFF202124),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        // Mostrar estado de alarma si está sonando
                        if (_securityService.isAlarmActive) ...[
                          const SizedBox(height: 16),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200, width: 2),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.red.shade600, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ALARMA ACTIVADA',
                                            style: TextStyle(
                                              color: Colors.red.shade800,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Dispositivo posiblemente robado',
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      await _securityService.stopAlarmOnly();
                                      setState(() {}); // Refrescar UI
                                    },
                                    icon: const Icon(Icons.stop, color: Colors.white),
                                    label: const Text(
                                      'DETENER ALARMA',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Widget de sistema desactivado (solo cuando está desactivado)
                  if (!isActive) ...[
                    const SizedBox(height: 24),
                    DeactivatedSystemWidget(
                      onReactivateNow: () {
                        // Activar el sistema
                        setState(() {
                          isActive = true;
                        });
                        
                        // Activar el sistema de seguridad real
                        _securityService.activateSecurity(showSensorValues: true);
                        
                        // Activar las animaciones del botón central
                        _onCentralButtonAnimation?.call();
                        
                        // Feedback háptico para confirmar la activación
                        HapticFeedback.mediumImpact();
                      },
                      onScheduleReactivation: _showSchedulePopup,
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Cards de control de características
                  Row(
                    children: [
                      Expanded(
                        child: FeatureControlCard(
                          title: 'Volumen de sirena',
                          value: sirenLevel,
                          icon: Icons.notifications_outlined,
                          onTap: () {
                            setState(() {
                              _isMenuOpen = true;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FeatureControlCard(
                          title: 'Alertas hápticas',
                          value: vibrationEnabled ? 'On' : 'Off',
                          icon: Icons.vibration,
                          onTap: () async {
                            setState(() {
                              vibrationEnabled = !vibrationEnabled;
                            });
                            
                            // Vibración como notificación usando HapticFeedback
                            try {
                              HapticFeedback.mediumImpact();
                              debugPrint('📳 Vibración ejecutada correctamente - Tipo: mediumImpact');
                            } catch (e) {
                              // Si la vibración no está disponible, continuar sin error
                              debugPrint('❌ Error en vibración: $e');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FeatureControlCard(
                          title: 'Sensibilidad',
                          value: '$sensitivity%',
                          icon: Icons.graphic_eq,
                          onTap: () {
                            _showSensitivityDialog();
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Vista previa del mapa
                  const MapPreview(),
                ],
              ),
            ),
          ),
        ],
      );
  }

  // Método para controlar el volumen real del sistema usando plugin nativo
  Future<void> _setSystemVolume(String level) async {
    double volume;
    switch (level) {
      case 'Bajo':
        volume = 0.8; // 80%
        break;
      case 'Medio':
        volume = 0.5; // 50%
        break;
      case 'Alto':
        volume = 1.0; // 100%
        break;
      default:
        volume = 0.5;
    }
    
    try {
      // Control real del volumen del sistema usando plugin nativo
      const platform = MethodChannel('volume_controller');
      await platform.invokeMethod('setVolume', {'volume': volume});
      
      debugPrint('🔊 Volumen del sistema configurado: $level (${(volume * 100).toInt()}%)');
      debugPrint('✅ Control de volumen nativo implementado correctamente');
      
      // Feedback háptico para confirmar la configuración
      switch (level) {
        case 'Bajo':
          HapticFeedback.lightImpact();
          break;
        case 'Medio':
          HapticFeedback.mediumImpact();
          break;
        case 'Alto':
          HapticFeedback.heavyImpact();
          break;
      }
      
    } catch (e) {
      debugPrint('❌ Error al configurar volumen del sistema: $e');
      debugPrint('🔄 Intentando método alternativo...');
      
      // Fallback: simulación si el plugin nativo falla
      try {
        await Future.delayed(const Duration(milliseconds: 200));
        debugPrint('🔊 Volumen simulado: $level (${(volume * 100).toInt()}%)');
        HapticFeedback.mediumImpact();
      } catch (e2) {
        debugPrint('❌ Error en método alternativo: $e2');
      }
    }
  }

  Widget _buildSirenMenu() {
    return Center(
      child: GestureDetector(
        onTap: () {
          // Prevenir que el tap se propague al overlay
        },
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Volumen de sirena',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
                ),
                const SizedBox(height: 16),
                
                // Indicador de permisos de administrador
                if (!_hasAdminPermissions) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Permisos de Administrador Requeridos',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Para bloquear la pantalla durante la alarma',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            await _securityService.requestAdminPermission();
                            // Verificar permisos después de un breve delay
                            Future.delayed(const Duration(seconds: 2), () {
                              _checkAdminPermissions();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Otorgar', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
            // Opción Bajo
            GestureDetector(
              onTap: () async {
                setState(() {
                  sirenLevel = 'Bajo';
                  _isMenuOpen = false;
                });
                await _setSystemVolume('Bajo');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                margin: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
                decoration: BoxDecoration(
                  color: sirenLevel == 'Bajo' ? Colors.black : Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Bajo',
                  style: TextStyle(
                    color: sirenLevel == 'Bajo' ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Opción Medio
            GestureDetector(
              onTap: () async {
                setState(() {
                  sirenLevel = 'Medio';
                  _isMenuOpen = false;
                });
                await _setSystemVolume('Medio');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                margin: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
                decoration: BoxDecoration(
                  color: sirenLevel == 'Medio' ? Colors.black : Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Medio',
                  style: TextStyle(
                    color: sirenLevel == 'Medio' ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Opción Alto
            GestureDetector(
              onTap: () async {
                setState(() {
                  sirenLevel = 'Alto';
                  _isMenuOpen = false;
                });
                await _setSystemVolume('Alto');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                decoration: BoxDecoration(
                  color: sirenLevel == 'Alto' ? Colors.black : Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Alto',
                  style: TextStyle(
                    color: sirenLevel == 'Alto' ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }


  void _showSensitivityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sensibilidad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              value: sensitivity.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              label: '$sensitivity%',
              onChanged: (value) {
                setState(() {
                  sensitivity = value.round();
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }



  // Método para confirmar la programación
  void _confirmSchedule() {
    if (_selectedTime != null) {
      // Calcular la duración hasta la hora seleccionada
      final now = DateTime.now();
      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      
      // Si la hora ya pasó hoy, programar para mañana
      if (scheduledTime.isBefore(now)) {
        final tomorrow = now.add(const Duration(days: 1));
        final tomorrowScheduled = DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
        _scheduleReactivationFor(tomorrowScheduled);
      } else {
        _scheduleReactivationFor(scheduledTime);
      }
      
      // Cerrar el diálogo
      Navigator.of(context).pop();
      
      // Mostrar confirmación
      _showScheduleConfirmation();
    }
  }

  // Programar la reactivación para una hora específica
  void _scheduleReactivationFor(DateTime scheduledTime) {
    final now = DateTime.now();
    final duration = scheduledTime.difference(now);
    
    if (duration.isNegative) {
      // Si la hora ya pasó, programar para mañana
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowScheduled = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      _scheduleReactivationFor(tomorrowScheduled);
      return;
    }
    
    // Cancelar timer anterior si existe
    _reactivationTimer?.cancel();
    
    // Crear nuevo timer
    _reactivationTimer = Timer(duration, () {
      _executeScheduledReactivation();
    });
    
    debugPrint('🕐 Reactivación programada para: ${scheduledTime.toString()}');
    debugPrint('⏰ Tiempo restante: ${duration.inMinutes} minutos');
  }

  // Ejecutar la reactivación programada
  void _executeScheduledReactivation() {
    if (!isActive) {
      setState(() {
        isActive = true;
      });
      
      // Activar el sistema de seguridad real
      _securityService.activateSecurity(showSensorValues: true);
      
      // Activar animaciones del botón central
      _onCentralButtonAnimation?.call();
      
      // Feedback háptico
      HapticFeedback.mediumImpact();
      
      // Mostrar notificación
      _showReactivationNotification();
      
      debugPrint('✅ Sistema reactivado automáticamente');
    }
    
    // Limpiar timer
    _reactivationTimer = null;
  }

  // Mostrar confirmación de programación
  void _showScheduleConfirmation() {
    final timeString = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reactivación programada para las $timeString'),
        backgroundColor: const Color(0xFF34A853),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Mostrar notificación de reactivación
  void _showReactivationNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sistema reactivado automáticamente'),
        backgroundColor: Color(0xFF34A853),
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Método para mostrar el menú de configuración
  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle del modal
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Configuración',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF202124),
                ),
              ),
              const SizedBox(height: 20),
              // Opción de prueba de sensores
              ListTile(
                leading: const Icon(
                  Icons.science,
                  color: Color(0xFF34A853),
                ),
                title: const Text(
                  'Prueba de Sensores',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF202124),
                  ),
                ),
                subtitle: const Text(
                  'Ver valores de sensores en tiempo real',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context); // Cerrar modal
                  _navigateToSensorTest();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Navegar a la pantalla de prueba de sensores
  void _navigateToSensorTest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SensorTestScreen(),
      ),
    );
  }

  // Método para mostrar el popup de programación
  void _showSchedulePopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildScheduleDialog();
      },
    );
  }

  // Widget del diálogo de programación
  Widget _buildScheduleDialog() {
    TimeOfDay? dialogSelectedTime = _selectedTime;
    
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text(
            'Programar Reactivación',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF202124),
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selecciona la hora para reactivar el sistema:',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF202124),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Selector de hora
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Color(0xFF202124),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: dialogSelectedTime ?? TimeOfDay.now(),
                        );
                        
                        if (picked != null && picked != dialogSelectedTime) {
                          setDialogState(() {
                            dialogSelectedTime = picked;
                          });
                        }
                      },
                      child: Text(
                        dialogSelectedTime != null 
                          ? '${dialogSelectedTime!.hour.toString().padLeft(2, '0')}:${dialogSelectedTime!.minute.toString().padLeft(2, '0')}'
                          : 'Seleccionar hora',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF202124),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: dialogSelectedTime != null ? () {
                setState(() {
                  _selectedTime = dialogSelectedTime;
                });
                _confirmSchedule();
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34A853),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Programar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // Limpiar timers
    _reactivationTimer?.cancel();
    _uiUpdateTimer?.cancel();
    
    // Desactivar el sistema de seguridad
    _securityService.deactivateSecurity();
    
    // Limpiar recursos del widget de seguridad
    super.dispose();
  }
}
