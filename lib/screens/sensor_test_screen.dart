import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
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
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('sensor.title')),
        backgroundColor: _isAlarmActive 
            ? Colors.red 
            : _isSecurityActive 
                ? Colors.green 
                : Colors.grey,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
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
                              l10n.translate('sensor.section.status'),
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
                                  _isSecurityActive
                                      ? l10n.translate('sensor.security.active')
                                      : l10n.translate('sensor.security.inactive'),
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
                                  _isAlarmActive
                                      ? l10n.translate('sensor.alarm.on')
                                      : l10n.translate('sensor.alarm.off'),
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
                              l10n.translate('sensor.section.instructions'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                            Text(
                              l10n.translate('sensor.instructions.body'),
                              style: const TextStyle(fontSize: 14),
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
                      label: Text(
                        _isSecurityActive
                            ? l10n.translate('sensor.button.toggle.active')
                            : l10n.translate('sensor.button.toggle.inactive'),
                      ),
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
                        label: Text(l10n.translate('sensor.button.stop.alarm')),
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
                                  l10n.translate('sensor.section.info'),
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                              l10n.translate('sensor.info.body'),
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
                    const SizedBox(height: 24),
          ],
                ),
              ),
            );
          },
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

