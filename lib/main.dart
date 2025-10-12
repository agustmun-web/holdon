import 'package:flutter/material.dart';
import 'screens/security_screen.dart';
import 'screens/map_screen.dart';
import 'services/optimized_geofence_service.dart';
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
  final OptimizedGeofenceService _optimizedGeofenceService = OptimizedGeofenceService();

  final List<Widget> _screens = [
    const SecurityScreen(),
    const MapScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeOptimizedGeofenceService();
  }

  /// Inicializa el servicio de geofencing optimizado
  Future<void> _initializeOptimizedGeofenceService() async {
    try {
      debugPrint('🚀 Inicializando servicio de geofencing optimizado...');
      
      // Inicializar el servicio optimizado
      final success = await _optimizedGeofenceService.initialize();
      
      if (success) {
        debugPrint('✅ Servicio de geofencing optimizado inicializado correctamente');
        
        // Iniciar monitoreo automáticamente
        final monitoringStarted = await _optimizedGeofenceService.startMonitoring();
        
        if (monitoringStarted) {
          debugPrint('🎯 Monitoreo de geofencing optimizado iniciado');
        } else {
          debugPrint('⚠️ Error al iniciar monitoreo de geofencing');
        }
      } else {
        debugPrint('❌ Error al inicializar servicio de geofencing optimizado');
      }
    } catch (e) {
      debugPrint('❌ Excepción al inicializar geofencing optimizado: $e');
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