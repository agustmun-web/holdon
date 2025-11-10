import 'package:flutter/material.dart';
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

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final OptimizedGeofenceService _optimizedGeofenceService =
      OptimizedGeofenceService();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const SecurityScreen(),
      const MapScreen(),
      const CustomZonesScreen(),
    ];
    _initializeOptimizedGeofenceService();
  }

  /// Inicializa el servicio de geofencing optimizado
  Future<void> _initializeOptimizedGeofenceService() async {
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
