import 'package:flutter/material.dart';
import '../core/app_keys.dart';
import '../l10n/app_localizations.dart';
import '../widgets/activity_card.dart';
import '../widgets/central_control.dart';
import '../widgets/feature_control_card.dart';
import '../widgets/map_preview.dart';
import '../widgets/deactivated_system_widget.dart';
import '../services/security_service.dart';
import '../services/optimized_geofence_service.dart';
import 'settings_screen.dart';
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
  final OptimizedGeofenceService _optimizedGeofenceService =
      OptimizedGeofenceService();

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
      final String? activity = await _optimizedGeofenceService
          .getUserHotspotActivity();
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
    final l10n = context.l10n;
    if (_hotspotActivity == null) {
      // Estado seguro - no está en ningún hotspot
      return ActivityCard(
        statusText: l10n.translate('security.status.safe'),
        statusColor: const Color(0xFF34A853), // Verde
        titleText: l10n.translate('security.status.safe.title'),
        subtitleText: l10n.translate('security.status.safe.subtitle'),
      );
    } else if (_hotspotActivity == 'ALTA') {
      // Estado de alta actividad - hotspot rojo
      return ActivityCard(
        statusText: l10n.translate('security.status.high'),
        statusColor: const Color(0xFFFF2100), // Rojo
        titleText: l10n.translate('security.status.high.title'),
        subtitleText: l10n.translate('security.status.high.subtitle'),
      );
    } else {
      // Estado de media actividad - hotspot ámbar (MODERADA)
      return ActivityCard(
        statusText: l10n.translate('security.status.medium'),
        statusColor: const Color(0xFFFF8C00), // Ámbar
        titleText: l10n.translate('security.status.medium.title'),
        subtitleText: l10n.translate('security.status.medium.subtitle'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1720),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isCompactHeight = constraints.maxHeight < 720;
            return _buildMainContent(isCompactHeight: isCompactHeight);
          },
        ),
      ),
    );
  }

  Widget _buildMainContent({required bool isCompactHeight}) {
    final l10n = context.l10n;
    return Column(
      children: [
        // Header personalizado compacto
        Container(
          padding: EdgeInsets.fromLTRB(
            16,
            isCompactHeight ? 16 : 40,
            16,
            isCompactHeight ? 4 : 8,
          ),
          child: Stack(
            children: [
              // Título centrado
              Center(
                child: Text(
                  l10n.translate('security.title'),
                  style: const TextStyle(
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
                  onTap: _openSettings,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF061B17),
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        const BorderSide(color: Color(0xFF0C1E1C), width: 2),
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
            padding: EdgeInsets.fromLTRB(
              8.0,
              0,
              8.0,
              isCompactHeight ? 12.0 : 24.0,
            ),
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
                          _securityService.activateSecurity(
                            showSensorValues: true,
                          );
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _securityService.isAlarmActive
                              ? const Color(
                                  0xFF2A1A0A,
                                ) // Naranja oscuro para alarma
                              : isActive
                              ? const Color(
                                  0xFF061B17,
                                ) // Verde oscuro para activo
                              : const Color(
                                  0xFF2A1A1A,
                                ), // Rojo oscuro para inactivo
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
                                    ? const Color(
                                        0xFFFF8C00,
                                      ) // Naranja para alarma
                                    : isActive
                                    ? const Color(
                                        0xFF21C55E,
                                      ) // Verde para activo
                                    : const Color(
                                        0xFFFF5B5B,
                                      ), // Rojo para inactivo
                                border: Border.all(
                                  color: _securityService.isAlarmActive
                                      ? const Color(
                                          0xFF4A1A0A,
                                        ) // Naranja muy oscuro para alarma
                                      : isActive
                                      ? const Color(
                                          0xFF0B3622,
                                        ) // Verde muy oscuro para activo
                                      : const Color(
                                          0xFF4A1A1A,
                                        ), // Rojo muy oscuro para inactivo
                                  width: 2,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _securityService.isAlarmActive
                                  ? l10n.translate('security.system.alarm')
                                  : isActive
                                  ? l10n.translate('security.system.active')
                                  : l10n.translate('security.system.paused'),
                              style: TextStyle(
                                color: _securityService.isAlarmActive
                                    ? const Color(
                                        0xFFFFB366,
                                      ) // Naranja claro para alarma
                                    : isActive
                                    ? const Color(
                                        0xFF9BE7C8,
                                      ) // Verde claro para activo
                                    : const Color(
                                        0xFFFFB3B3,
                                      ), // Rojo claro para inactivo
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
                        _securityService.activateSecurity(
                          showSensorValues: true,
                        );

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
                    title: l10n.translate('security.sensitivity.title'),
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

                if (isActive) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: const MapPreview(),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSensitivityDialog() {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('security.sensitivity.title')),
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
            child: Text(l10n.translate('common.accept')),
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
    final timeString =
        '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.translate(
            'security.schedule.confirmation',
            params: {'time': timeString},
          ),
        ),
        backgroundColor: const Color(0xFF34A853),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Mostrar notificación de reactivación
  void _showReactivationNotification() {
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(context.l10n.translate('security.schedule.notification')),
        backgroundColor: const Color(0xFF34A853),
        duration: const Duration(seconds: 3),
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
    final l10n = context.l10n;

    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: Text(
            l10n.translate('security.schedule.dialog.title'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF202124),
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.translate('security.schedule.dialog.description'),
                style: const TextStyle(fontSize: 16, color: Color(0xFF202124)),
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
                            : l10n.translate('security.schedule.dialog.pick'),
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
              child: Text(
                l10n.translate('common.cancel'),
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: dialogSelectedTime != null
                  ? () {
                      setState(() {
                        _selectedTime = dialogSelectedTime;
                      });
                      _confirmSchedule();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34A853),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                l10n.translate('common.schedule'),
                style: const TextStyle(
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

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
