import 'package:flutter/material.dart';
import '../services/security_service.dart';

/// Pantalla de prueba para mostrar los valores de los sensores
/// 
/// Esta pantalla permite activar/desactivar el sistema de seguridad
/// y ver los valores de los sensores en tiempo real en el terminal.
class SensorTestScreen extends StatefulWidget {
  const SensorTestScreen({super.key});

  @override
  State<SensorTestScreen> createState() => _SensorTestScreenState();
}

class _SensorTestScreenState extends State<SensorTestScreen> {
  final SecurityService _securityService = SecurityService();
  bool _isSecurityActive = false;
  bool _isAlarmActive = false;

  @override
  void initState() {
    super.initState();
    _updateStatus();
  }

  void _updateStatus() {
    setState(() {
      _isSecurityActive = _securityService.isSecurityActive;
      _isAlarmActive = _securityService.isAlarmActive;
    });
  }

  void _toggleSecurity() {
    if (_isSecurityActive) {
      _securityService.deactivateSecurity();
    } else {
      _securityService.activateSecurity(showSensorValues: true);
    }
    _updateStatus();
  }

  void _stopAlarm() {
    _securityService.stopAlarm();
    _updateStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba de Sensores'),
        backgroundColor: _isAlarmActive 
            ? Colors.red 
            : _isSecurityActive 
                ? Colors.green 
                : Colors.grey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Estado del sistema
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado del Sistema',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          _isSecurityActive ? Icons.security : Icons.security_outlined,
                          color: _isSecurityActive ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Seguridad: ${_isSecurityActive ? "ACTIVA" : "INACTIVA"}',
                          style: TextStyle(
                            color: _isSecurityActive ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _isAlarmActive ? Icons.warning : Icons.warning_outlined,
                          color: _isAlarmActive ? Colors.red : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Alarma: ${_isAlarmActive ? "SONANDO" : "SILENCIOSA"}',
                          style: TextStyle(
                            color: _isAlarmActive ? Colors.red : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Instrucciones
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instrucciones',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '1. Presiona "Activar Seguridad" para iniciar la detección\n'
                      '2. Los valores de los sensores aparecerán en el terminal\n'
                      '3. Mueve el dispositivo bruscamente para probar la detección\n'
                      '4. Los umbrales son: Aceleración > 50 m/s², Giroscopio > 9 rad/s',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botones de control
            ElevatedButton.icon(
              onPressed: _toggleSecurity,
              icon: Icon(_isSecurityActive ? Icons.stop : Icons.play_arrow),
              label: Text(_isSecurityActive ? 'Desactivar Seguridad' : 'Activar Seguridad'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSecurityActive ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            if (_isAlarmActive) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _stopAlarm,
                icon: const Icon(Icons.stop),
                label: const Text('Detener Alarma'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Información adicional
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Información',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Los valores de los sensores se muestran cada 10 eventos en el terminal. '
                      'Observa la consola para ver los datos en tiempo real.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _securityService.dispose();
    super.dispose();
  }
}

