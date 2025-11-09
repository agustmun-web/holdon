import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../l10n/app_localizations.dart';
import '../services/geofence_service.dart';
import '../models/custom_zone.dart';
import '../services/custom_zone_database.dart';
import '../services/optimized_geofence_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.zoneRevision});

  final ValueNotifier<int>? zoneRevision;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  bool _isLoading = true;
  String? _errorKey;
  Map<String, String>? _errorParams;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  final GeofenceService _geofenceService = GeofenceService();
  final OptimizedGeofenceService _optimizedGeofenceService = OptimizedGeofenceService();
  final CustomZoneDatabase _zoneDatabase = CustomZoneDatabase.instance;
  List<CustomZone> _customZones = <CustomZone>[];
  bool _zoneReloadScheduled = false;

  static const List<String> _zoneTypeOptions = <String>[
    'Casa',
    'Trabajo',
    'Gimnasio',
    'Otro',
  ];
  
  // Ubicación por defecto (Madrid, España)
  static const LatLng _defaultLocation = LatLng(40.4168, -3.7038);

  @override
  void initState() {
    super.initState();
    widget.zoneRevision?.addListener(_onZoneRevisionChanged);
    _initializeMap();
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zoneRevision != widget.zoneRevision) {
      oldWidget.zoneRevision?.removeListener(_onZoneRevisionChanged);
      widget.zoneRevision?.addListener(_onZoneRevisionChanged);
    }
  }

  Future<void> _initializeMap() async {
    setState(() {
      _errorKey = null;
      _errorParams = null;
    });
    try {
      await _getCurrentLocation();
      await _loadCustomZones();
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorKey = 'map.loading.error';
        _errorParams = {'error': e.toString()};
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
    final l10n = context.l10n;
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
          else if (_errorKey != null)
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
                    l10n.translate(
                      _errorKey!,
                      params: _errorParams,
                    ),
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
                        _errorKey = null;
                        _errorParams = null;
                      });
                      _initializeMap();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34A853),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(l10n.translate('map.retry')),
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
              onLongPress: _onMapLongPress,
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
          if (!_isLoading && _errorKey == null)
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

  Future<void> _loadCustomZones({bool forceRefresh = false}) async {
    try {
      final List<CustomZone> zones = List<CustomZone>.from(
        await _zoneDatabase.getZones(forceRefresh: forceRefresh),
      );
      _applyCustomZones(zones);
      try {
        await Future.wait([
          _geofenceService.syncCustomZones(zones),
          _optimizedGeofenceService.syncCustomZones(zones),
        ]);
      } catch (e) {
        debugPrint('❌ Error al sincronizar geofencing con zonas personalizadas: $e');
      }
    } catch (e) {
      debugPrint('❌ Error al cargar zonas personalizadas: $e');
      if (_customZones.isEmpty) {
        _applyCustomZones(const <CustomZone>[]);
      }
    }
  }

  void _onZoneRevisionChanged() {
    if (!mounted || _zoneReloadScheduled) return;
    _zoneReloadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _zoneReloadScheduled = false;
      if (mounted) {
        _loadCustomZones(forceRefresh: true);
      }
    });
  }

  void _applyCustomZones(List<CustomZone> zones) {
    if (!mounted) return;
    final Set<Circle> circles = _buildMapCircles(zones);
    setState(() {
      _customZones = zones;
      _circles
        ..clear()
        ..addAll(circles);
    });
  }

  Set<Circle> _buildMapCircles(List<CustomZone> customZones) {
    final Set<Circle> circles = <Circle>{};

    for (final hotspot in _geofenceService.hotspotsList) {
      final Color circleColor = hotspot.activity == 'ALTA' 
          ? const Color(0xFFFF2100)
          : const Color(0xFFFFC700);

      circles.add(
        Circle(
          circleId: CircleId(hotspot.id),
          center: LatLng(hotspot.latitude, hotspot.longitude),
          radius: hotspot.radius,
          fillColor: circleColor.withValues(alpha: 0.2),
          strokeColor: circleColor,
          strokeWidth: 3,
          consumeTapEvents: true,
          onTap: () => _showHotspotInfo(hotspot),
        ),
      );
    }

    const Color customStrokeColor = Color(0xFF1E88E5);

    for (final CustomZone zone in customZones) {
      if (zone.id == null) continue;
      circles.add(
        Circle(
          circleId: CircleId('custom_${zone.id}'),
          center: LatLng(zone.latitude, zone.longitude),
          radius: zone.radius,
          fillColor: customStrokeColor.withValues(alpha: 0.18),
          strokeColor: customStrokeColor,
          strokeWidth: 2,
        ),
      );
    }

    return circles;
  }

  Future<void> _onMapLongPress(LatLng position) async {
    HapticFeedback.mediumImpact();
    final CustomZone? draftZone = await _showCreateZoneSheet(position);
    if (draftZone == null) return;

    try {
      final CustomZone savedZone = await _zoneDatabase.insertZone(draftZone);

      if (mounted) {
        setState(() {
          _customZones.removeWhere((zone) => zone.id == savedZone.id);
          _customZones = <CustomZone>[savedZone, ..._customZones];
          _circles
            ..clear()
            ..addAll(_buildMapCircles(_customZones));
        });
      }

      bool registrationSuccessful = true;
      try {
        await Future.wait([
          _geofenceService.registerCustomZone(savedZone),
          _optimizedGeofenceService.registerCustomZone(savedZone),
        ]);
      } catch (e) {
        registrationSuccessful = false;
        debugPrint('❌ Error al registrar zona personalizada en geofencing: $e');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            registrationSuccessful
                ? 'Zona personalizada guardada'
                : 'Zona guardada, pero no se pudo activar el geofencing de inmediato',
          ),
        ),
      );

      final revision = widget.zoneRevision;
      if (revision != null) {
        revision.value = revision.value + 1;
      }
    } catch (e) {
      debugPrint('❌ Error al guardar zona personalizada: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la zona: $e')),
      );
    }
  }

  Future<CustomZone?> _showCreateZoneSheet(LatLng position) async {
    final TextEditingController nameController = TextEditingController();
    double radius = 150;
    String zoneType = _zoneTypeOptions.first;
    String? nameError;

    final CustomZone? createdZone = await showModalBottomSheet<CustomZone>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext modalContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: StatefulBuilder(
              builder: (BuildContext context, void Function(void Function()) setModalState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Crear zona personalizada',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Nombre de la zona',
                          hintText: 'Ej. Gimnasio',
                          errorText: nameError,
                        ),
                        onChanged: (_) {
                          if (nameError != null) {
                            setModalState(() {
                              nameError = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Radio: ${radius.toStringAsFixed(0)} m',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Slider(
                        value: radius,
                        min: 50,
                        max: 1000,
                        divisions: 19,
                        label: '${radius.toStringAsFixed(0)} m',
                        onChanged: (double value) {
                          setModalState(() {
                            radius = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: zoneType,
                        items: _zoneTypeOptions
                            .map(
                              (String type) => DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (String? value) {
                          if (value == null) return;
                          setModalState(() {
                            zoneType = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Tipo de zona',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(modalContext).pop(),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: () {
                              final String name = nameController.text.trim();
                              if (name.isEmpty) {
                                setModalState(() {
                                  nameError = 'Introduce un nombre';
                                });
                                return;
                              }
                              Navigator.of(modalContext).pop(
                                CustomZone(
                                  name: name,
                                  latitude: position.latitude,
                                  longitude: position.longitude,
                                  radius: radius,
                                  zoneType: zoneType,
                                ),
                              );
                            },
                            child: const Text('Guardar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    nameController.dispose();
    return createdZone;
  }

  /// Muestra información del hotspot cuando se toca
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

  @override
  void dispose() {
    widget.zoneRevision?.removeListener(_onZoneRevisionChanged);
    // Limpiar recursos del mapa para evitar warnings
    _mapController?.dispose();
    _mapController = null;
    // Limpiar círculos y marcadores para liberar recursos
    _circles.clear();
    _markers.clear();
    super.dispose();
  }
}
