import 'package:flutter/material.dart';
import '../widgets/activity_card.dart';
import '../widgets/central_control.dart';
import '../widgets/feature_control_card.dart';
import '../widgets/map_preview.dart';
import '../widgets/deactivated_system_widget.dart';
import '../services/security_service.dart';
import '../services/optimized_geofence_service.dart';
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
  double sensitivity = 0.5;
  
  // Servicio de seguridad
  final SecurityService _securityService = SecurityService();
  
  // Servicio de geofencing optimizado
  final OptimizedGeofenceService _optimizedGeofenceService = OptimizedGeofenceService();
  
  // Callback para activar animaciones del botón central
  VoidCallback? _onCentralButtonAnimation;
  
  // Estado de permisos de administrador
  bool _hasAdminPermissions = false;
  
  // Estado de hotspot
  String? _hotspotActivity;
  
  // Variables para programación de reactivación
  TimeOfDay? _selectedTime;
  Timer? _reactivationTimer;
  Timer? _uiUpdateTimer;

  @override
  void initState() {
    super.initState();
    _checkAdminPermissions();
    _checkHotspotStatus();
    // Activar el sistema de seguridad al inicializar la pantalla
    _securityService.activateSecurity(showSensorValues: true);
    // Establecer sensibilidad normal por defecto
    _securityService.setSensitivityLevel("NORMAL");
    
    // Timer para actualizar la UI cada segundo (para mostrar estado de alarma)
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
    
    // Timer para verificar estado de hotspot cada 30 segundos
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _checkHotspotStatus();
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

  /// Verifica si el usuario está dentro de algún hotspot y obtiene el nivel de actividad
  Future<void> _checkHotspotStatus() async {
    try {
      final String? activity = await _optimizedGeofenceService.getUserHotspotActivity();
      if (mounted) {
        setState(() {
          _hotspotActivity = activity;
        });
      }
    } catch (e) {
      debugPrint('❌ Error al verificar estado de hotspot: $e');
    }
  }

  /// Construye el ActivityCard según el estado del hotspot
  Widget _buildActivityCard() {
    if (_hotspotActivity == null) {
      // Estado seguro - no está en ningún hotspot
      return const ActivityCard(
        statusText: 'Seguro',
        statusColor: Color(0xFF34A853), // Verde
        titleText: 'Zona segura',
        subtitleText: 'Sin hotspots cercanos • Todo en orden',
      );
    } else if (_hotspotActivity == 'ALTA') {
      // Estado de alta actividad - hotspot rojo
      return const ActivityCard(
        statusText: 'Alta',
        statusColor: Color(0xFFFF2100), // Rojo
        titleText: 'Zona de alta actividad',
        subtitleText: 'Alerta, zona con alta peligrosidad',
      );
    } else {
      // Estado de media actividad - hotspot ámbar (MODERADA)
      return const ActivityCard(
        statusText: 'Media',
        statusColor: Color(0xFFFF8C00), // Ámbar
        titleText: 'Zona de actividad moderada',
        subtitleText: 'Precaución, zona con peligrosidad moderada',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isActive ? const Color(0xFF0E1720) : const Color(0xFF0E1720),
      body: Stack(
        children: [
          // Contenido principal
          _buildMainContent(),
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
                      color: Colors.white,
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
                      decoration: BoxDecoration(
                        color: const Color(0xFF061B17),
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          const BorderSide(
                            color: Color(0xFF0C1E1C),
                            width: 2,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0C1E1C).withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 0),
                          ),
                        ],
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
              padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card de actividad reciente
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildActivityCard(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Control central
                  Center(
                    child: CentralControl(
                      isActive: isActive,
                      isAlarmActive: _securityService.isAlarmActive,
                      onTap: () async {
                        // Si hay alarma activa, detener la alarma y desactivar el sistema
                        if (_securityService.isAlarmActive) {
                          await _securityService.stopAlarmOnly();
                          // Desactivar el sistema de seguridad (botón rojo)
                          setState(() {
                            isActive = false;
                          });
                          _securityService.deactivateSecurity();
                        } else {
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _securityService.isAlarmActive 
                              ? const Color(0xFF2A1A0A) // Naranja oscuro para alarma
                              : isActive 
                                ? const Color(0xFF061B17) // Verde oscuro para activo
                                : const Color(0xFF2A1A1A), // Rojo oscuro para inactivo
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _securityService.isAlarmActive
                                    ? const Color(0xFFFF8C00) // Naranja para alarma
                                    : isActive 
                                      ? const Color(0xFF21C55E) // Verde para activo
                                      : const Color(0xFFFF5B5B), // Rojo para inactivo
                                  border: Border.all(
                                    color: _securityService.isAlarmActive
                                      ? const Color(0xFF4A1A0A) // Naranja muy oscuro para alarma
                                      : isActive 
                                        ? const Color(0xFF0B3622) // Verde muy oscuro para activo
                                        : const Color(0xFF4A1A1A), // Rojo muy oscuro para inactivo
                                    width: 2,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _securityService.isAlarmActive
                                  ? 'Dispositivo posiblemente robado'
                                  : isActive 
                                    ? 'Sistema seguro y monitoreando' 
                                    : 'Monitoreo pausado',
                                style: TextStyle(
                                  color: _securityService.isAlarmActive
                                    ? const Color(0xFFFFB366) // Naranja claro para alarma
                                    : isActive 
                                      ? const Color(0xFF9BE7C8) // Verde claro para activo
                                      : const Color(0xFFFFB3B3), // Rojo claro para inactivo
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Widget de sistema desactivado (solo cuando está desactivado)
                  if (!isActive) ...[
                    const SizedBox(height: 24),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: DeactivatedSystemWidget(
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
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Card de control de sensibilidad
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D131C),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: FeatureControlCard(
                      title: 'Sensibilidad',
                      value: sensitivity,
                      icon: Icons.graphic_eq,
                      onChanged: (value) {
                        setState(() {
                          sensitivity = value;
                        });
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Vista previa del mapa
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: const MapPreview(),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
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
              value: sensitivity * 100,
              min: 0,
              max: 100,
              divisions: 20,
              label: '${(sensitivity * 100).round()}%',
              onChanged: (value) {
                setState(() {
                  sensitivity = value / 100;
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
