import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'background/geofence_background_task.dart';
import 'core/app_keys.dart';
import 'l10n/app_localizations.dart';
import 'screens/map_screen.dart';
import 'screens/security_screen.dart';
import 'screens/custom_zones_screen.dart';
import 'services/custom_zone_service.dart';
import 'services/geofence_service.dart';
import 'services/optimized_geofence_service.dart';
import 'services/notification_manager.dart';
import 'services/risk_status_manager.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Configurar tarea en segundo plano para geofencing
  setupBackgroundTask();

  // Inicializar zonas personalizadas y sincronizar con servicios de geofencing
  final customZoneService = CustomZoneService.instance;
  await customZoneService.ensureInitialized();

  final geofenceService = GeofenceService();
  final optimizedGeofenceService = OptimizedGeofenceService();

  void syncCustomZones() {
    final zones = customZoneService.zones;
    geofenceService.updateCustomZones(zones);
    optimizedGeofenceService.updateCustomZones(zones);
  }

  syncCustomZones();
  customZoneService.zonesNotifier.addListener(syncCustomZones);

  await NotificationManager.instance.ensureInitialized();

  final appState = AppState();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: appState),
        ChangeNotifierProvider<RiskStatusManager>(
          create: (_) => RiskStatusManager(),
        ),
      ],
      child: const HoldOnApp(),
    ),
  );
}

class HoldOnApp extends StatelessWidget {
  const HoldOnApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return MaterialApp(
      locale: appState.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) {
          return supportedLocales.first;
        }
        for (final supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
      onGenerateTitle: (context) => context.l10n.translate('app.title'),
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
  final OptimizedGeofenceService _optimizedGeofenceService =
      OptimizedGeofenceService();
  static const MethodChannel _locationServiceChannel =
      MethodChannel('holdon/location_service');

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _screens = [
      const SecurityScreen(),
      const MapScreen(),
      const CustomZonesScreen(),
    ];
    _initializeServices();
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
        debugPrint('🔄 App resumed - verificando servicio de ubicación');
        _ensureForegroundServiceRunning();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        debugPrint('💤 App en segundo plano - servicio de ubicación permanece activo');
        break;
      case AppLifecycleState.detached:
        debugPrint('🔌 App detached - el servicio permanece activo');
        break;
    }
  }

  /// Inicializa geofencing y garantiza que el servicio de ubicación nativo corra en primer plano
  Future<void> _initializeServices() async {
    try {
      debugPrint('🚀 Inicializando servicio de geofencing optimizado...');

      // Inicializar el servicio optimizado
      final success = await _optimizedGeofenceService.initialize();

      if (success) {
        debugPrint(
          '✅ Servicio de geofencing optimizado inicializado correctamente',
        );

        // Iniciar monitoreo automáticamente
        final monitoringStarted = await _optimizedGeofenceService
            .startMonitoring();

        if (monitoringStarted) {
          debugPrint('🎯 Monitoreo de geofencing optimizado iniciado');
          await _startNativeLocationService();
        } else {
          debugPrint('⚠️ Error al iniciar monitoreo de geofencing');
        }
      } else {
        debugPrint('❌ Error al inicializar servicio de geofencing optimizado');
      }

      await _requestLocationUpdate();
    } catch (e) {
      debugPrint('❌ Excepción al inicializar geofencing optimizado: $e');
    }
  }

  /// Inicia el servicio nativo de ubicación en primer plano
  Future<void> _startNativeLocationService() async {
    try {
      debugPrint('📱 Iniciando servicio nativo de ubicación...');
      final result =
          await _locationServiceChannel.invokeMethod('startLocationService');
      if (result == true) {
        debugPrint('✅ Servicio nativo de ubicación iniciado');
      } else {
        debugPrint('⚠️ No se pudo iniciar el servicio nativo de ubicación');
      }
    } catch (e) {
      debugPrint('❌ Error al iniciar servicio nativo de ubicación: $e');
    }
  }

  /// Asegura que el servicio de ubicación en primer plano siga ejecutándose
  Future<void> _ensureForegroundServiceRunning() async {
    try {
      final isRunning =
          await _locationServiceChannel.invokeMethod('isLocationServiceRunning');
      if (isRunning != true) {
        debugPrint('🔄 Reiniciando servicio de ubicación en primer plano');
        await _startNativeLocationService();
      } else {
        debugPrint('✅ Servicio de ubicación continúa activo');
      }
    } catch (e) {
      debugPrint('❌ Error al verificar servicio nativo de ubicación: $e');
    }
  }

  /// Solicita una actualización manual de ubicación
  Future<void> _requestLocationUpdate() async {
    try {
      await _locationServiceChannel.invokeMethod('requestLocationUpdate');
      debugPrint('📍 Actualización manual de ubicación solicitada');
    } catch (e) {
      debugPrint('❌ Error al solicitar actualización manual: $e');
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF27323A), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF061414),
          selectedItemColor: const Color(0xFF34A853),
          unselectedItemColor: Colors.grey[400],
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.security),
              label: l10n.translate('tab.security'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.map),
              label: l10n.translate('tab.map'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.layers),
              label: l10n.translate('tab.customZones'),
            ),
          ],
        ),
      ),
    );
  }
}
