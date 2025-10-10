import 'package:flutter/material.dart';
import 'screens/security_screen.dart';
import 'screens/map_screen.dart';
import 'screens/sensor_test_screen.dart';
import 'services/geofence_service.dart';
import 'background/geofence_background_task.dart';

void main() {
  // Configurar tarea en segundo plano para geofencing
  setupBackgroundTask();
  
  // SOLO debe haber una llamada a runApp
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HoldOn! Anti-Theft App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF0E1720),
        fontFamily: 'Roboto',
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GeofenceService _geofenceService = GeofenceService();

  final List<Widget> _screens = [
    const SecurityScreen(),
    const MapScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeGeofenceService();
  }

  /// Inicializa el servicio de geofencing (SIN activar monitoreo automático)
  Future<void> _initializeGeofenceService() async {
    try {
      // Solo inicializar el servicio, NO iniciar el monitoreo automáticamente
      final success = await _geofenceService.initialize();
      
      if (success) {
        debugPrint('✅ Servicio de geofencing inicializado (sin activar monitoreo)');
      } else {
        debugPrint('❌ Error al inicializar servicio de geofencing');
      }
    } catch (e) {
      debugPrint('❌ Excepción al inicializar geofencing: $e');
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Color(0xFF27323A),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF061414),
          selectedItemColor: const Color(0xFF34A853),
          unselectedItemColor: Colors.grey[400],
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.security),
              label: 'Seguridad',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: 'Mapa',
            ),
          ],
        ),
      ),
    );
  }
}