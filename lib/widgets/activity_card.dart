import 'package:flutter/material.dart';

class ActivityCard extends StatelessWidget {
  final String statusText;
  final Color statusColor;
  final String titleText;
  final String subtitleText;

  const ActivityCard({
    super.key,
    this.statusText = 'Media',
    this.statusColor = const Color(0xFFF7B500),
    this.titleText = 'Zona con actividad reciente',
    this.subtitleText = '2 hotspots a 1.2 km • Última alerta hace 30 min',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1413),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF242E37),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: const Color(0xFF242E37).withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 0),
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
                color: statusColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                Text(
                  titleText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitleText,
                  style: const TextStyle(
                    color: Color(0xFFaebab5),
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
              color: Color(0xFF061B17),
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
