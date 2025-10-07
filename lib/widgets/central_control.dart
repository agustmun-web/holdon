import 'package:flutter/material.dart';

class CentralControl extends StatefulWidget {
  final bool isActive;
  final bool isAlarmActive;
  final VoidCallback onTap;
  final Function(VoidCallback)? onAnimationCallback;

  const CentralControl({
    super.key,
    required this.isActive,
    required this.isAlarmActive,
    required this.onTap,
    this.onAnimationCallback,
  });

  @override
  State<CentralControl> createState() => _CentralControlState();
}

class _CentralControlState extends State<CentralControl>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeOut,
    ));

    // Registrar el callback de animación
    widget.onAnimationCallback?.call(triggerAnimations);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Llamar al callback inmediatamente para evitar delays
    widget.onTap();
    
    // Iniciar animaciones
    _triggerAnimations();
  }

  // Método público para activar las animaciones desde fuera
  void triggerAnimations() {
    _triggerAnimations();
  }

  void _triggerAnimations() {
    // Iniciar animaciones de forma más eficiente con debounce
    if (!_scaleController.isAnimating) {
      _scaleController.forward().then((_) {
        _scaleController.reverse();
      });
    }
    
    if (!_glowController.isAnimating) {
      _glowController.forward().then((_) {
        _glowController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _handleTap,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              final currentColor = widget.isAlarmActive
                ? const Color(0xFFFF8C00) // Naranja para alarma
                : widget.isActive 
                  ? const Color(0xFF23C25D) // Verde para activo
                  : const Color(0xFFFF5B5B); // Rojo para inactivo
              
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Resplandor con AnimatedBuilder separado
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        if (_glowAnimation.value > 0) {
                          return Container(
                            width: 144 + (40 * _glowAnimation.value),
                            height: 144 + (40 * _glowAnimation.value),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: currentColor.withValues(
                                alpha: 0.3 * _glowAnimation.value,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    // Botón principal con triple borde
                    Container(
                      width: 176,
                      height: 176,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: widget.isActive ? Border.all(
                          color: const Color(0xFF0E1720),
                          width: 4,
                        ) : null,
                      ),
                      child: Center(
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: widget.isActive ? Border.all(
                              color: const Color(0xFF162028),
                              width: 4,
                            ) : null,
                          ),
                          child: Center(
                            child: Container(
                              width: 144,
                              height: 144,
                              decoration: BoxDecoration(
                                color: currentColor,
                                shape: BoxShape.circle,
                                border: widget.isActive ? Border.all(
                                  color: const Color(0xFF122421),
                                  width: 4,
                                ) : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: currentColor.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // Círculos concéntricos de fondo
                                  ...List.generate(3, (index) {
                                    return Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: currentColor.withValues(alpha: 0.1),
                                            width: 1,
                                          ),
                                        ),
                                        margin: EdgeInsets.all(20.0 * (index + 1)),
                                      ),
                                    );
                                  }),
                          // Icono central
                          Center(
                            child: Icon(
                              widget.isAlarmActive
                                ? Icons.warning_amber_rounded
                                : widget.isActive 
                                  ? Icons.security 
                                  : Icons.power_settings_new,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.isAlarmActive 
            ? 'ALARMA ACTIVADA' 
            : widget.isActive 
              ? 'Activo' 
              : 'Monitoreo pausado',
          style: TextStyle(
            color: widget.isAlarmActive
              ? const Color(0xFFFF8C00)
              : widget.isActive 
                ? const Color(0xFF23C25D) 
                : const Color(0xFFFF5B5B),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.isAlarmActive 
            ? 'Toque para detener alarma'
            : widget.isActive 
              ? 'Toque para desactivar' 
              : 'Toque para activar',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

