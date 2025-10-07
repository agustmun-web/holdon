import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

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
      _createDangerZones();
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
      if (_mapController != null) {
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
        _goToMyLocation();
      });
    }
  }

  void _goToMyLocation() async {
    if (_mapController != null && _currentPosition != null) {
      try {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentPosition!,
              zoom: 15.0,
            ),
          ),
        );
        
        HapticFeedback.lightImpact();
      } catch (e) {
        debugPrint('Error al centrar el mapa: $e');
      }
    }
  }

  void _createDangerZones() {
    // Círculo del Puente de Hierro (Madrid)
    final Circle puenteZone = Circle(
      circleId: const CircleId('puente_hierro_zone'),
      center: const LatLng(40.9458, -4.1158),
      radius: 700,
      fillColor: const Color(0x4DFF5B5B),
      strokeColor: const Color(0xFFFF5B5B),
      strokeWidth: 3,
    );
    
    // Círculo del Centro Histórico (Madrid)
    final Circle centroZone = Circle(
      circleId: const CircleId('centro_historico_zone'),
      center: const LatLng(40.4168, -3.7038),
      radius: 500,
      fillColor: const Color(0x4DFF5B5B),
      strokeColor: const Color(0xFFFF5B5B),
      strokeWidth: 3,
    );
    
    _circles.addAll([puenteZone, centroZone]);
  }

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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
