import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/geofence_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  bool _isLoading = true;
  String _errorMessage = '';
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  final GeofenceService _geofenceService = GeofenceService();
  
  // Ubicación por defecto (Madrid, España)
  static const LatLng _defaultLocation = LatLng(40.4168, -3.7038);

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      await _getCurrentLocation();
      _createHotspotCircles();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al inicializar el mapa: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Solicitar permisos de ubicación
      final permission = await Permission.location.request();
      if (permission != PermissionStatus.granted) {
        setState(() {
          _currentPosition = _defaultLocation;
        });
        return;
      }

      // Verificar si los servicios de ubicación están habilitados
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentPosition = _defaultLocation;
        });
        return;
      }

      // Obtener la ubicación actual
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      ).timeout(const Duration(seconds: 10));

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      
      // Centrar automáticamente en la ubicación del usuario
      if (_mapController != null && mounted) {
        _goToMyLocation();
      }
    } catch (e) {
      setState(() {
        _currentPosition = _defaultLocation;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    // Centrar automáticamente en la ubicación del usuario al crear el mapa
    if (_currentPosition != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _goToMyLocation();
        }
      });
    }
  }

  void _goToMyLocation() async {
    if (_mapController != null && _currentPosition != null && mounted) {
      try {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentPosition!,
              zoom: 15.0,
            ),
          ),
        );
        
        if (mounted) {
          HapticFeedback.lightImpact();
        }
      } catch (e) {
        debugPrint('Error al centrar el mapa: $e');
      }
    }
  }

  // Función _createDangerZones() eliminada - hotspots removidos

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapa de Google Maps ocupando toda la pantalla
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF34A853),
              ),
            )
          else if (_errorMessage.isNotEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFFF5B5B),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Color(0xFF5F6368),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = '';
                      });
                      _initializeMap();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34A853),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          else
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition ?? _defaultLocation,
                zoom: 14.0,
              ),
              onMapCreated: _onMapCreated,
              markers: _markers,
              circles: _circles,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              mapType: MapType.normal,
              compassEnabled: true,
              buildingsEnabled: true,
              trafficEnabled: false,
            ),
          
          // Botón flotante para centrar en mi ubicación
          if (!_isLoading && _errorMessage.isEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: _goToMyLocation,
                backgroundColor: const Color(0xFF34A853),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Crea los círculos de hotspots en el mapa
  void _createHotspotCircles() {
    final List<Circle> hotspotCircles = [];
    
    for (final hotspot in _geofenceService.hotspotsList) {
      // Determinar el color según la actividad
      final Color circleColor = hotspot.activity == 'ALTA' 
          ? const Color(0xFFFF2100) // Rojo para ALTA
          : const Color(0xFFFFC700); // Amarillo para MODERADA
      
      // Crear el círculo
      final Circle circle = Circle(
        circleId: CircleId(hotspot.id),
        center: LatLng(hotspot.latitude, hotspot.longitude),
        radius: hotspot.radius,
        fillColor: circleColor.withValues(alpha: 0.2), // Color de relleno semi-transparente
        strokeColor: circleColor, // Color del borde
        strokeWidth: 3,
        consumeTapEvents: true,
        onTap: () => _showHotspotInfo(hotspot),
      );
      
      hotspotCircles.add(circle);
    }
    
    setState(() {
      _circles.clear();
      _circles.addAll(hotspotCircles);
    });
  }

  /// Muestra información del hotspot cuando se toca
  void _showHotspotInfo(GeofenceHotspot hotspot) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning,
                color: hotspot.activity == 'ALTA' 
                    ? const Color(0xFFFF2100) 
                    : const Color(0xFFFFC700),
              ),
              const SizedBox(width: 8),
              const Text('Zona de Hotspot'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getHotspotDisplayName(hotspot.id),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Nivel de Actividad: ${hotspot.activity}'),
              Text('Radio: ${hotspot.radius.toStringAsFixed(0)} metros'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hotspot.activity == 'ALTA' 
                      ? const Color(0xFFFF2100).withValues(alpha: 0.1)
                      : const Color(0xFFFFC700).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hotspot.activity == 'ALTA' 
                        ? const Color(0xFFFF2100)
                        : const Color(0xFFFFC700),
                    width: 1,
                  ),
                ),
                child: Text(
                  hotspot.activity == 'ALTA' 
                      ? '⚠️ Zona de alta actividad - Ten precaución'
                      : '⚠️ Zona de actividad moderada - Mantente alerta',
                  style: TextStyle(
                    color: hotspot.activity == 'ALTA' 
                        ? const Color(0xFFFF2100)
                        : const Color(0xFFFFC700),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  /// Obtiene el nombre de visualización del hotspot
  String _getHotspotDisplayName(String id) {
    switch (id) {
      case 'guardia_civil':
        return 'Edificio Guardia Civil';
      case 'hermanitas_pobres':
        return 'Hermanitas de los Pobres';
      case 'claret':
        return 'Claret';
      case 'camino_ie':
        return 'Camino IE';
      default:
        return id;
    }
  }

  @override
  void dispose() {
    // Limpiar recursos del mapa para evitar warnings
    _mapController?.dispose();
    _mapController = null;
    // Limpiar círculos y marcadores para liberar recursos
    _circles.clear();
    _markers.clear();
    super.dispose();
  }
}
