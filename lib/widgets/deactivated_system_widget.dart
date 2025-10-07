import 'package:flutter/material.dart';

class DeactivatedSystemWidget extends StatelessWidget {
  final VoidCallback onReactivateNow;
  final VoidCallback onScheduleReactivation;

  const DeactivatedSystemWidget({
    super.key,
    required this.onReactivateNow,
    required this.onScheduleReactivation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D131C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF27323A),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título centrado
          Center(
            child:               Text(
                'Sistema Desactivado',
                style: const TextStyle(
                  color: Color(0xFF9BE7C8),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ),
          
          const SizedBox(height: 12),
          
          // Texto descriptivo
          Text(
            'Todos los sensores han sido desactivados, no recibirás alertas hasta reactivar el sistema',
            style: const TextStyle(
              color: Color(0xFF9BE7C8),
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          // Botones
          Row(
            children: [
              // Botón "Programar reactivación"
              Expanded(
                child: GestureDetector(
                  onTap: onScheduleReactivation,
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF27323A),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Color(0xFF9BE7C8),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Programar',
                              style: TextStyle(
                                color: Color(0xFF9BE7C8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'reactivación',
                              style: TextStyle(
                                color: Color(0xFF9BE7C8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Botón "Reactivar ahora"
              Expanded(
                child: GestureDetector(
                  onTap: onReactivateNow,
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF23C55E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.security,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Reactivar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
