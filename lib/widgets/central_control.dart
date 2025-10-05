import 'package:flutter/material.dart';

class CentralControl extends StatefulWidget {
  final bool isActive;
  final VoidCallback onTap;

  const CentralControl({
    super.key,
    required this.isActive,
    required this.onTap,
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
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Iniciar animaciones
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
    
    _glowController.forward().then((_) {
      _glowController.reverse();
    });

    // Llamar al callback después de un breve delay
    Future.delayed(const Duration(milliseconds: 100), () {
      widget.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _handleTap,
          child: AnimatedBuilder(
            animation: Listenable.merge([_scaleAnimation, _glowAnimation]),
            builder: (context, child) {
              final currentColor = widget.isActive 
                ? const Color(0xFF38B05F) 
                : const Color(0xFFFF5B5B);
              
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Resplandor
                    if (_glowAnimation.value > 0)
                      Container(
                        width: 144 + (40 * _glowAnimation.value),
                        height: 144 + (40 * _glowAnimation.value),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentColor.withValues(
                            alpha: 0.3 * _glowAnimation.value,
                          ),
                        ),
                      ),
                    // Botón principal
                    Container(
                      width: 144,
                      height: 144,
                      decoration: BoxDecoration(
                        color: currentColor,
                        shape: BoxShape.circle,
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
                              widget.isActive 
                                ? Icons.security 
                                : Icons.power_settings_new,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ],
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
          widget.isActive ? 'Activo' : 'Monitoreo pausado',
          style: TextStyle(
            color: widget.isActive ? const Color(0xFF38B05F) : const Color(0xFFFF5B5B),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.isActive ? 'Toque para desactivar' : 'Toque para activar',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

