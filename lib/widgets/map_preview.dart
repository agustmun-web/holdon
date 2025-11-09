import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../l10n/app_localizations.dart';
import '../services/geofence_service.dart';

class MapPreview extends StatefulWidget {
  const MapPreview({super.key});

  @override
  State<MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<MapPreview> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  bool _isLoading = true;
  String? _errorKey;
  Map<String, String>? _errorParams;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  double _currentZoom = 12.0;
  final GeofenceService _geofenceService = GeofenceService();
  
  // Ubicación por defecto (Madrid, España)
  static const LatLng _defaultLocation = LatLng(40.4168, -3.7038);
  
  // Estilo simplificado para reducir warnings de renderizado
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
      "featureType": "water",
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
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    setState(() {
      _errorKey = null;
      _errorParams = null;
    });
    try {
      // Crear hotspots primero
      _createHotspotCircles();
      
      // Intentar obtener ubicación
      await _getCurrentLocation();
      
      // Si no se pudo obtener ubicación, usar ubicación por defecto
      if (_currentPosition == null) {
        setState(() {
          _currentPosition = _defaultLocation;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentPosition = _defaultLocation;
        _isLoading = false;
        _errorKey = 'map.loading.error';
        _errorParams = {'error': e.toString()};
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Solicitar permisos de ubicación
      final permission = await Permission.location.request();
      if (permission != PermissionStatus.granted) {
        debugPrint('⚠️ Permisos de ubicación denegados en widget');
        return; // No establecer error, usar ubicación por defecto
      }

      // Verificar si los servicios de ubicación están habilitados
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Servicios de ubicación deshabilitados en widget');
        return; // No establecer error, usar ubicación por defecto
      }

      // Obtener la ubicación actual con timeout
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      ).timeout(const Duration(seconds: 5));

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      
      debugPrint('📍 Ubicación obtenida en widget: ${position.latitude}, ${position.longitude}');
      
      // Centrar automáticamente en la ubicación del usuario
      if (_mapController != null && mounted) {
        _goToMyLocation();
      }
    } catch (e) {
      debugPrint('⚠️ Error al obtener ubicación en widget: $e');
      // No establecer error, usar ubicación por defecto
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    debugPrint('🗺️ Mapa creado en widget');
    
    // Aplicar el estilo del mapa de forma segura
    try {
      controller.setMapStyle(_mapStyle);
    } catch (e) {
      debugPrint('⚠️ Error al aplicar estilo del mapa: $e');
    }
    
    // Centrar automáticamente en la ubicación al crear el mapa
    if (_currentPosition != null) {
      // Usar un delay para evitar conflictos con ImageReader
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_mapController != null && mounted) {
          _goToMyLocation();
        }
      });
    } else {
      // Si no hay ubicación, usar ubicación por defecto
      setState(() {
        _currentPosition = _defaultLocation;
        _isLoading = false;
      });
      
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_mapController != null && mounted) {
          _goToMyLocation();
        }
      });
    }
  }

  void _goToMyLocation() async {
    if (_mapController != null && _currentPosition != null && mounted) {
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
        if (mounted) {
          HapticFeedback.lightImpact();
        }
        
        debugPrint('📍 Mapa centrado en ubicación actual: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      } catch (e) {
        debugPrint('❌ Error al centrar el mapa: $e');
      }
    } else {
      debugPrint('⚠️ No se puede centrar el mapa: controlador, ubicación no disponibles o widget no montado');
    }
  }

  /// Crea los círculos de hotspots en el mapa de vista previa
  void _createHotspotCircles() {
    final List<Circle> hotspotCircles = [];
    
    for (final hotspot in _geofenceService.hotspotsList) {
      // Determinar el color según la actividad
      final Color circleColor = hotspot.activity == 'ALTA' 
          ? const Color(0xFFFF2100) // Rojo para ALTA
          : const Color(0xFFFFC700); // Amarillo para MODERADA
      
      // Crear el círculo
      final Circle circle = Circle(
        circleId: CircleId('preview_${hotspot.id}'),
        center: LatLng(hotspot.latitude, hotspot.longitude),
        radius: hotspot.radius,
        fillColor: circleColor.withValues(alpha: 0.2), // Color de relleno semi-transparente
        strokeColor: circleColor, // Color del borde
        strokeWidth: 2, // Borde más delgado para la vista previa
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

  /// Muestra información del hotspot cuando se toca en la vista previa
  void _showHotspotInfo(GeofenceHotspot hotspot) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final l10n = context.l10n;
        final activityLabel = _getHotspotActivityLabel(hotspot.activity);
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
              Text(l10n.translate('map.hotspot.title')),
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
              Text(
                l10n.translate(
                  'map.hotspot.activity',
                  params: {'activity': activityLabel},
                ),
              ),
              Text(
                l10n.translate(
                  'map.hotspot.radius',
                  params: {'meters': hotspot.radius.toStringAsFixed(0)},
                ),
              ),
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
                      ? l10n.translate('map.hotspot.alert.high')
                      : l10n.translate('map.hotspot.alert.medium'),
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
              child: Text(l10n.translate('common.accept')),
            ),
          ],
        );
      },
    );
  }

  /// Obtiene el nombre de visualización del hotspot
  String _getHotspotDisplayName(String id) {
    final key = 'map.default.hotspot.$id';
    final translation = context.l10n.translate(key);
    if (translation == key) {
      return id;
    }
    return translation;
  }

  String _getHotspotActivityLabel(String activity) {
    switch (activity) {
      case 'ALTA':
        return context.l10n.translate('security.status.high');
      case 'MODERADA':
        return context.l10n.translate('security.status.medium');
      default:
        return activity;
    }
  }

  // Método para hacer zoom in
  void _zoomIn() async {
    if (_mapController != null && mounted) {
      try {
        _currentZoom = (_currentZoom + 1).clamp(1.0, 20.0);
        await _mapController!.animateCamera(
          CameraUpdate.zoomTo(_currentZoom),
        );
        
        if (mounted) {
          HapticFeedback.lightImpact();
        }
        debugPrint('🔍 Zoom in: ${_currentZoom.toStringAsFixed(1)}');
      } catch (e) {
        debugPrint('❌ Error al hacer zoom in: $e');
      }
    }
  }

  // Método para hacer zoom out
  void _zoomOut() async {
    if (_mapController != null && mounted) {
      try {
        _currentZoom = (_currentZoom - 1).clamp(1.0, 20.0);
        await _mapController!.animateCamera(
          CameraUpdate.zoomTo(_currentZoom),
        );
        
        if (mounted) {
          HapticFeedback.lightImpact();
        }
        debugPrint('🔍 Zoom out: ${_currentZoom.toStringAsFixed(1)}');
      } catch (e) {
        debugPrint('❌ Error al hacer zoom out: $e');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF27323A),
          width: 1,
        ),
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
            else if (_errorKey != null)
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
                      context.l10n.translate(
                        _errorKey!,
                        params: _errorParams,
                      ),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
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
                buildingsEnabled: false,
                trafficEnabled: false,
              ),
            // Botones de control del mapa (centrados horizontalmente en el lado derecho)
            if (!_isLoading && _errorKey == null)
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
                        width: 32,
                        height: 32,
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
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Botón Zoom In (+)
                    GestureDetector(
                      onTap: _zoomIn,
                      child: Container(
                        width: 32,
                        height: 32,
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
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Botón Zoom Out (-)
                    GestureDetector(
                      onTap: _zoomOut,
                      child: Container(
                        width: 32,
                        height: 32,
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
                          size: 16,
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
    // Limpiar círculos para liberar recursos
    _circles.clear();
    _markers.clear();
    super.dispose();
  }
}