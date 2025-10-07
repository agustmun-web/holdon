import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapPreview extends StatefulWidget {
  const MapPreview({super.key});

  @override
  State<MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<MapPreview> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  bool _isLoading = true;
  String _errorMessage = '';
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  double _currentZoom = 12.0;
  
  // Estilo personalizado para ocultar completamente la marca de agua y texto de Google
  static const String _mapStyle = '''
  [
    {
      "featureType": "poi",
      "elementType": "labels",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "poi.business",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "all",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#000000",
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "all",
      "elementType": "labels.text.stroke",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "labels",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "administrative",
      "elementType": "labels",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    }
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _circles.addAll(_createHotspotCircles());
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Solicitar permisos de ubicación
      final permission = await Permission.location.request();
      if (permission != PermissionStatus.granted) {
        setState(() {
          _errorMessage = 'Permisos de ubicación denegados';
          _isLoading = false;
        });
        return;
      }

      // Verificar si los servicios de ubicación están habilitados
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Servicios de ubicación deshabilitados';
          _isLoading = false;
        });
        return;
      }

      // Obtener la ubicación actual
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      
      // Centrar automáticamente en la ubicación del usuario
      if (_mapController != null) {
        _goToMyLocation();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al obtener la ubicación: $e';
        _isLoading = false;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    // Centrar automáticamente en la ubicación del usuario al crear el mapa
    if (_currentPosition != null) {
      // Usar un delay para evitar conflictos con ImageReader
      Future.delayed(const Duration(milliseconds: 100), () {
        _goToMyLocation();
      });
    }
  }

  void _goToMyLocation() async {
    if (_mapController != null && _currentPosition != null) {
      try {
        // Centrar el mapa en la ubicación actual con animación
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentPosition!,
              zoom: 15.0,
            ),
          ),
        );
        
        // Feedback háptico para confirmar la acción
        HapticFeedback.lightImpact();
        
        debugPrint('📍 Mapa centrado en ubicación actual: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      } catch (e) {
        debugPrint('❌ Error al centrar el mapa: $e');
      }
    } else {
      debugPrint('⚠️ No se puede centrar el mapa: controlador o ubicación no disponibles');
    }
  }

  // Función para crear círculos de zonas de peligro
  Set<Circle> _createHotspotCircles() {
    // Círculo del Puente de Hierro
    final Circle puenteZone = Circle(
      circleId: const CircleId('puente_hierro_zone'),
      center: const LatLng(40.9458, -4.1158), // Puente de Hierro
      radius: 700, // 700 metros
      fillColor: const Color(0x4DFF5B5B), // Rojo Coral con 30% opacidad
      strokeColor: const Color(0xFFFF5B5B), // Rojo Coral sólido
      strokeWidth: 3,
    );
    
    debugPrint('🚨 Zona de peligro Puente de Hierro creada: 40.9458, -4.1158');
    debugPrint('📍 Radio Puente de Hierro: 700 metros');
    debugPrint('🎨 Color: Rojo Coral (#FF5B5B) con 30% opacidad');
    
    return {puenteZone};
  }

  // Método para hacer zoom in
  void _zoomIn() async {
    if (_mapController != null) {
      try {
        _currentZoom = (_currentZoom + 1).clamp(1.0, 20.0);
        await _mapController!.animateCamera(
          CameraUpdate.zoomTo(_currentZoom),
        );
        
        HapticFeedback.lightImpact();
        debugPrint('🔍 Zoom in: ${_currentZoom.toStringAsFixed(1)}');
      } catch (e) {
        debugPrint('❌ Error al hacer zoom in: $e');
      }
    }
  }

  // Método para hacer zoom out
  void _zoomOut() async {
    if (_mapController != null) {
      try {
        _currentZoom = (_currentZoom - 1).clamp(1.0, 20.0);
        await _mapController!.animateCamera(
          CameraUpdate.zoomTo(_currentZoom),
        );
        
        HapticFeedback.lightImpact();
        debugPrint('🔍 Zoom out: ${_currentZoom.toStringAsFixed(1)}');
      } catch (e) {
        debugPrint('❌ Error al hacer zoom out: $e');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Mapa real de Google Maps
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF38B05F),
                ),
              )
            else if (_errorMessage.isNotEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_off,
                      color: Colors.grey,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else if (_currentPosition != null)
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition!,
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
                buildingsEnabled: false,
                trafficEnabled: false,
                style: _mapStyle,
              ),
            // Botones de control del mapa (centrados horizontalmente en el lado derecho)
            if (_currentPosition != null)
              Positioned(
                top: 16,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botón "Mi ubicación"
                    GestureDetector(
                      onTap: _goToMyLocation,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Color(0xFF202124),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Botón Zoom In (+)
                    GestureDetector(
                      onTap: _zoomIn,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Color(0xFF202124),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Botón Zoom Out (-)
                    GestureDetector(
                      onTap: _zoomOut,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.remove,
                          color: Color(0xFF202124),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Limpiar recursos del mapa para evitar warnings de ImageReader
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }
}
