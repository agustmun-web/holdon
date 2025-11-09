import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/optimized_geofence_service.dart';

/// Widget reactivo que se actualiza automáticamente cuando cambia el estado de riesgo
class ReactiveActivityCard extends StatelessWidget {
  const ReactiveActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Usar la instancia singleton del servicio
    final geofenceService = OptimizedGeofenceService();
    
    return StreamBuilder<String>(
      stream: geofenceService.riskStatusStream,
      initialData: geofenceService.currentRiskLevel,
      builder: (context, snapshot) {
        // Obtener el estado de riesgo actual
        final String riskLevel = snapshot.data ?? 'SEGURO';
        
        // Configurar el widget según el nivel de riesgo
        final Map<String, dynamic> cardConfig = _getCardConfig(riskLevel, l10n);
        
        return Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2E),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: cardConfig['borderColor'] as Color,
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: (cardConfig['borderColor'] as Color).withOpacity(0.3),
                blurRadius: 8.0,
                spreadRadius: 2.0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estado de riesgo
              Row(
                children: [
                  Icon(
                    cardConfig['icon'] as IconData,
                    color: cardConfig['borderColor'] as Color,
                    size: 24.0,
                  ),
                  const SizedBox(width: 12.0),
                  Text(
                    cardConfig['statusText'] as String,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: cardConfig['borderColor'] as Color,
                    ),
                  ),
                  const Spacer(),
                  // Indicador de actualización en tiempo real
                  Container(
                    width: 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      color: snapshot.hasData ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              
              // Título
              Text(
                cardConfig['titleText'] as String,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8.0),
              
              // Descripción
              Text(
                cardConfig['subtitleText'] as String,
                style: const TextStyle(
                  fontSize: 14.0,
                  color: Color(0xFFaebab5),
                ),
              ),
              
              // Información adicional para debugging
              if (snapshot.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: Colors.red,
                    ),
                  ),
                ),
              
              // Debug info
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Debug: ${snapshot.connectionState} | Data: ${snapshot.data} | HasData: ${snapshot.hasData}',
                  style: const TextStyle(
                    fontSize: 10.0,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Obtiene la configuración del widget según el nivel de riesgo
  Map<String, dynamic> _getCardConfig(String riskLevel, AppLocalizations l10n) {
    switch (riskLevel) {
      case 'ALTA':
        return {
          'statusText': l10n.translate('security.status.high'),
          'borderColor': const Color(0xFFFF2100), // Rojo
          'titleText': l10n.translate('security.status.high.title'),
          'subtitleText': l10n.translate('security.status.high.subtitle'),
          'icon': Icons.warning_rounded,
        };
      case 'MODERADA':
        return {
          'statusText': l10n.translate('security.status.medium'),
          'borderColor': const Color(0xFFFF8C00), // Ámbar
          'titleText': l10n.translate('security.status.medium.title'),
          'subtitleText': l10n.translate('security.status.medium.subtitle'),
          'icon': Icons.info_rounded,
        };
      case 'SEGURO':
      default:
        return {
          'statusText': l10n.translate('security.status.safe'),
          'borderColor': const Color(0xFF00C851), // Verde
          'titleText': l10n.translate('security.status.safe.title'),
          'subtitleText': l10n.translate('security.status.safe.subtitle'),
          'icon': Icons.check_circle_rounded,
        };
    }
  }
}
