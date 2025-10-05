import 'package:flutter/material.dart';
import '../widgets/activity_card.dart';
import '../widgets/central_control.dart';
import '../widgets/feature_control_card.dart';
import '../widgets/map_preview.dart';
import '../widgets/deactivated_system_widget.dart';
import 'package:flutter/services.dart';

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
                      // TODO: Implementar configuración
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
                        setState(() {
                          isActive = !isActive;
                        });
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Estado del sistema
                  Center(
                    child: Row(
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
                  ),
                  
                  // Widget de sistema desactivado (solo cuando está desactivado)
                  if (!isActive) ...[
                    const SizedBox(height: 24),
                    const DeactivatedSystemWidget(
                      onReactivateNow: _reactivateNow,
                      onScheduleReactivation: _scheduleReactivation,
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

  static void _reactivateNow() {
    // TODO: Implementar reactivación inmediata
    // print('Reactivar ahora');
  }

  static void _scheduleReactivation() {
    // TODO: Implementar programación de reactivación
    // print('Programar reactivación');
  }
}
