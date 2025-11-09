import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final OptimizedGeofenceService _optimizedGeofenceService = OptimizedGeofenceService();
  
  // Platform channel para comunicación con el servicio nativo
  static const MethodChannel _locationServiceChannel = MethodChannel('holdon/location_service');

  final List<Widget> _screens = [
    const SecurityScreen(),
    const MapScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeForegroundLocationService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('🔄 App resumed - Manteniendo servicios activos');
        _ensureForegroundServiceRunning();
        break;
      case AppLifecycleState.paused:
        debugPrint('⏸️ App paused - Servicios continúan en segundo plano');
        break;
      case AppLifecycleState.detached:
        debugPrint('🔌 App detached - Servicios persisten');
        break;
      case AppLifecycleState.inactive:
        debugPrint('💤 App inactive - Servicios activos');
        break;
      case AppLifecycleState.hidden:
        debugPrint('👻 App hidden - Servicios en segundo plano');
        break;
    }
  }

  /// Inicializa el servicio de ubicación en primer plano
  Future<void> _initializeForegroundLocationService() async {
    try {
      debugPrint('🚀 Inicializando servicio de ubicación en primer plano...');
      
      // Inicializar el servicio optimizado de geofencing
      final success = await _optimizedGeofenceService.initialize();
      
      if (success) {
        debugPrint('✅ Servicio de geofencing optimizado inicializado correctamente');
        
        // Iniciar el servicio nativo de ubicación en primer plano
        await _startNativeLocationService();
        
        // Iniciar monitoreo de geofencing
        final monitoringStarted = await _optimizedGeofenceService.startMonitoring();
        
        if (monitoringStarted) {
          debugPrint('🎯 Monitoreo de geofencing iniciado con servicio en primer plano');
        } else {
          debugPrint('⚠️ Error al iniciar monitoreo de geofencing');
        }
      } else {
        debugPrint('❌ Error al inicializar servicio de geofencing optimizado');
      }
    } catch (e) {
      debugPrint('❌ Excepción al inicializar servicios: $e');
    }
  }

  /// Inicia el servicio nativo de ubicación en primer plano
  Future<void> _startNativeLocationService() async {
    try {
      debugPrint('📱 Iniciando servicio nativo de ubicación...');
      
      final result = await _locationServiceChannel.invokeMethod('startLocationService');
      
      if (result == true) {
        debugPrint('✅ Servicio nativo de ubicación iniciado correctamente');
      } else {
        debugPrint('⚠️ Servicio nativo de ubicación no pudo iniciarse');
      }
    } catch (e) {
      debugPrint('❌ Error al iniciar servicio nativo de ubicación: $e');
    }
  }

  /// Asegura que el servicio en primer plano esté ejecutándose
  Future<void> _ensureForegroundServiceRunning() async {
    try {
      final isRunning = await _locationServiceChannel.invokeMethod('isLocationServiceRunning');
      
      if (isRunning != true) {
        debugPrint('🔄 Reiniciando servicio de ubicación...');
        await _startNativeLocationService();
      } else {
        debugPrint('✅ Servicio de ubicación ya está ejecutándose');
      }
    } catch (e) {
      debugPrint('❌ Error al verificar servicio de ubicación: $e');
    }
  }

  /// Solicita una actualización de ubicación
  Future<void> _requestLocationUpdate() async {
    try {
      await _locationServiceChannel.invokeMethod('requestLocationUpdate');
      debugPrint('📍 Actualización de ubicación solicitada');
    } catch (e) {
      debugPrint('❌ Error al solicitar actualización de ubicación: $e');
    }
  }

  /// Obtiene la última ubicación conocida
  Future<Map<String, double>?> _getLastKnownLocation() async {
    try {
      final location = await _locationServiceChannel.invokeMethod('getLastKnownLocation');
      return Map<String, double>.from(location ?? {});
    } catch (e) {
      debugPrint('❌ Error al obtener última ubicación: $e');
      return null;
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
      // Botón flotante para debugging (opcional)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showServiceStatusDialog();
        },
        backgroundColor: const Color(0xFF34A853),
        child: const Icon(Icons.info_outline),
      ),
    );
  }

  /// Muestra el estado del servicio (para debugging)
  Future<void> _showServiceStatusDialog() async {
    try {
      final serviceStatus = _optimizedGeofenceService.getServiceStatus();
      final lastLocation = await _getLastKnownLocation();
      final isNativeServiceRunning = await _locationServiceChannel.invokeMethod('isLocationServiceRunning');
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Estado del Servicio'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Geofencing Inicializado: ${serviceStatus['isInitialized']}'),
                Text('Geofencing Monitoreo: ${serviceStatus['isMonitoring']}'),
                Text('Servicio Ubicación Nativo: $isNativeServiceRunning'),
                Text('Servicio Ubicación Activo: ${serviceStatus['locationServiceActive']}'),
                Text('Timer Hotspot Activo: ${serviceStatus['hotspotCheckTimerActive']}'),
                Text('Timer Keep-Alive Activo: ${serviceStatus['keepAliveTimerActive']}'),
                if (lastLocation != null) ...[
                  const SizedBox(height: 8),
                  Text('Última Ubicación:'),
                  Text('  Lat: ${lastLocation['latitude']?.toStringAsFixed(6)}'),
                  Text('  Lng: ${lastLocation['longitude']?.toStringAsFixed(6)}'),
                ],
                if (serviceStatus['hotspotsInZone'].isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Hotspots Activos: ${serviceStatus['hotspotsInZone']}'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _requestLocationUpdate();
                },
                child: const Text('Actualizar Ubicación'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error al mostrar estado del servicio: $e');
    }
  }
}




