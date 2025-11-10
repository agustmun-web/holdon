import 'dart:async';
import 'package:flutter/foundation.dart';

/// Manager singleton que gestiona el estado de riesgo del usuario
/// y proporciona un Stream para actualizaciones en tiempo real
class RiskStatusManager extends ChangeNotifier {
  RiskStatusManager();

  // StreamController para emitir cambios de estado de riesgo
  final StreamController<String> _riskStatusController =
      StreamController<String>.broadcast();

  // Estado actual del riesgo
  String _currentRiskLevel = 'SEGURO';

  // Stream público para que los widgets escuchen
  Stream<String> get riskStatusStream => _riskStatusController.stream;

  // Getter para obtener el estado actual
  String get currentRiskLevel => _currentRiskLevel;

  /// Fuerza una emisión del estado actual al Stream (útil para inicialización)
  void emitCurrentState() {
    debugPrint(
      '📡 RiskStatusManager: Emitiendo estado actual: $_currentRiskLevel',
    );
    _riskStatusController.add(_currentRiskLevel);
    notifyListeners();
  }

  /// Actualiza el nivel de riesgo y emite el cambio al Stream
  void updateRiskLevel(String newLevel) {
    // Validar que el nivel sea válido
    if (!_isValidRiskLevel(newLevel)) {
      debugPrint('⚠️ Nivel de riesgo inválido: $newLevel');
      return;
    }

    // Solo actualizar si el nivel ha cambiado
    if (_currentRiskLevel != newLevel) {
      final oldLevel = _currentRiskLevel;
      _currentRiskLevel = newLevel;

      debugPrint(
        '🔄 RiskStatusManager: Estado actualizado $oldLevel → $newLevel',
      );
      debugPrint(
        '📡 RiskStatusManager: Emitiendo al stream. HasListener: ${_riskStatusController.hasListener}',
      );

      // Emitir el nuevo estado al Stream
      _riskStatusController.add(newLevel);
      notifyListeners();
    } else {
      debugPrint('📌 RiskStatusManager: Estado sin cambios: $newLevel');
    }
  }

  /// Verifica si un nivel de riesgo es válido
  bool _isValidRiskLevel(String level) {
    const validLevels = ['SEGURO', 'MODERADA', 'ALTA'];
    return validLevels.contains(level);
  }

  /// Establece el estado como SEGURO (usuario fuera de todos los hotspots)
  void setSafe() {
    updateRiskLevel('SEGURO');
  }

  /// Establece el estado como MODERADA (usuario en hotspot amarillo)
  void setModerate() {
    updateRiskLevel('MODERADA');
  }

  /// Establece el estado como ALTA (usuario en hotspot rojo)
  void setHigh() {
    updateRiskLevel('ALTA');
  }

  /// Obtiene información del estado actual (para debugging)
  Map<String, dynamic> getStatusInfo() {
    return {
      'currentRiskLevel': _currentRiskLevel,
      'streamHasListener': _riskStatusController.hasListener,
      'streamIsClosed': _riskStatusController.isClosed,
    };
  }

  @override
  void dispose() {
    debugPrint('🧹 RiskStatusManager: Liberando recursos...');
    _riskStatusController.close();
    super.dispose();
  }
}
