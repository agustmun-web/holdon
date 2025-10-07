import 'package:flutter/material.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Indicador de intensidad (1/4 del ancho)
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF7B500),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Moderate',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Contenido principal (3/4 del ancho)
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Zona con actividad reciente',
                  style: TextStyle(
                    color: Color(0xFF202124),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '2 hotspots a 1.2 km • Última alerta hace 30 min',
                  style: TextStyle(
                    color: Color(0xFF6E7C7E),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Círculo con flecha
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFE1F4ED),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF34A853),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}
