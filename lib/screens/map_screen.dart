import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../l10n/app_localizations.dart';
import '../models/custom_zone.dart';
import '../services/custom_zone_service.dart';
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
  String? _errorKey;
  Map<String, String>? _errorParams;
  final Set<Marker> _markers = {};
  final GeofenceService _geofenceService = GeofenceService();
  final CustomZoneService _customZoneService = CustomZoneService.instance;
  Set<Circle> _customCircles = <Circle>{};
  late final VoidCallback _customZonesListener;

  // Ubicación por defecto (Madrid, España)
  static const LatLng _defaultLocation = LatLng(40.4168, -3.7038);
  static const List<String> _zoneTypeKeys = <String>[
    'gym',
    'home',
    'work',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _customZonesListener = () {
      _renderCustomZones(_customZoneService.zones);
    };
    _customZoneService.ensureInitialized().then((_) {
      if (!mounted) return;
      _renderCustomZones(_customZoneService.zones);
      _customZoneService.zonesNotifier.addListener(_customZonesListener);
    });
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    setState(() {
      _errorKey = null;
      _errorParams = null;
    });
    try {
      await _getCurrentLocation();
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
            CameraPosition(target: _currentPosition!, zoom: 15.0),
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
    final Set<Circle> circles = _buildHotspotCircles();
    return Scaffold(
      body: Stack(
        children: [
          // Mapa de Google Maps ocupando toda la pantalla
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF34A853)),
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
                    l10n.translate(_errorKey!, params: _errorParams),
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
              markers: _markers,
              circles: {...circles, ..._customCircles},
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              mapType: MapType.normal,
              compassEnabled: true,
              buildingsEnabled: true,
              trafficEnabled: false,
              onLongPress: _handleMapLongPress,
            ),

          // Botón flotante para centrar en mi ubicación
          if (!_isLoading && _errorKey == null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: _goToMyLocation,
                backgroundColor: const Color(0xFF34A853),
                child: const Icon(Icons.my_location, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Set<Circle> _buildHotspotCircles() {
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

    return circles;
  }

  void _renderCustomZones(List<CustomZone> zones) {
    final Set<Circle> customCircles = <Circle>{};
    for (final CustomZone zone in zones) {
      if (zone.id == null) continue;
      customCircles.add(_createCustomCircle(zone));
    }
    if (mounted) {
      setState(() {
        _customCircles = customCircles;
      });
    } else {
      _customCircles = customCircles;
    }
  }

  Circle _createCustomCircle(CustomZone zone) {
    final Color circleColor = _colorForZoneType(zone.zoneType);
    return Circle(
      circleId: CircleId('custom_${zone.id}'),
      center: LatLng(zone.latitude, zone.longitude),
      radius: zone.radius,
      fillColor: circleColor.withValues(alpha: 0.12),
      strokeColor: circleColor,
      strokeWidth: 2,
      consumeTapEvents: true,
      onTap: () => _showCustomZoneInfo(zone),
    );
  }

  Color _colorForZoneType(String zoneType) {
    switch (zoneType) {
      case 'gym':
        return const Color(0xFF2563EB); // Azul
      case 'home':
        return const Color(0xFF22C55E); // Verde
      case 'work':
        return const Color(0xFFF97316); // Naranja
      default:
        return const Color(0xFF6B7280); // Gris
    }
  }

  Color _colorForZoneTypeLight(String zoneType) {
    final base = _colorForZoneType(zoneType);
    return Color.lerp(base, Colors.white, 0.4) ?? base;
  }

  Widget _buildZoneTypeDot(String zoneType) {
    return _ZoneTypeDot(
      color: _colorForZoneType(zoneType),
      secondary: _colorForZoneTypeLight(zoneType),
    );
  }

  Future<void> _handleMapLongPress(LatLng position) async {
    if (_isLoading || _errorKey != null) return;
    final CustomZone? createdZone = await _showCreateZoneSheet(position);
    if (createdZone != null && mounted) {
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate(
              'map.customZone.saved',
              params: {'name': createdZone.name},
            ),
          ),
        ),
      );
      _goToLocation(position);
    }
  }

  Future<void> _goToLocation(LatLng target) async {
    if (_mapController == null) return;
    try {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 16.0),
        ),
      );
    } catch (e) {
      debugPrint('Error al mover cámara: $e');
    }
  }

  Future<CustomZone?> _showCreateZoneSheet(LatLng position) {
    final l10n = context.l10n;
    final TextEditingController nameController = TextEditingController();
    double radiusValue = 150;
    String selectedType = _zoneTypeKeys.first;
    String? errorText;
    bool isSaving = false;

    Map<String, String> _zoneTypeLabels(AppLocalizations loc) {
      return {
        'gym': loc.translate('map.customZone.type.gym'),
        'home': loc.translate('map.customZone.type.home'),
        'work': loc.translate('map.customZone.type.work'),
        'other': loc.translate('map.customZone.type.other'),
      };
    }

    return showModalBottomSheet<CustomZone>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        final labels = _zoneTypeLabels(l10n);
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.decelerate,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF121E2C),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 48,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.translate('map.customZone.title'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: nameController,
                          enabled: !isSaving,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: l10n.translate('map.customZone.nameLabel'),
                            hintText: l10n.translate('map.customZone.nameHint'),
                            errorText: errorText,
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            labelStyle: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.15),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF34A853),
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFFF5B5B),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.translate(
                            'map.customZone.radiusLabel',
                            params: {'meters': radiusValue.toStringAsFixed(0)},
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF34A853),
                            inactiveTrackColor:
                                Colors.white.withOpacity(0.1),
                            thumbColor: const Color(0xFF34A853),
                            overlayColor:
                                const Color(0xFF34A853).withOpacity(0.2),
                            valueIndicatorColor: const Color(0xFF34A853),
                          ),
                          child: Slider(
                            value: radiusValue,
                            min: 50,
                            max: 1000,
                            divisions: 19,
                            label: '${radiusValue.toStringAsFixed(0)} m',
                            onChanged: isSaving
                                ? null
                                : (value) {
                                    setModalState(() {
                                      radiusValue = value;
                                    });
                                  },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.translate('map.customZone.typeLabel'),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: selectedType,
                          dropdownColor: const Color(0xFF121E2C),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.15),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF34A853),
                              ),
                            ),
                          ),
                          items: _zoneTypeKeys
                              .map(
                                (key) => DropdownMenuItem<String>(
                                  value: key,
                                  child: Row(
                                    children: [
                                      _buildZoneTypeDot(key),
                                      const SizedBox(width: 8),
                                      Text(labels[key] ?? key),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setModalState(() {
                                    selectedType = value;
                                  });
                                },
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: isSaving
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                child: Text(l10n.translate('common.cancel')),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF34A853),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        final name = nameController.text.trim();
                                        if (name.isEmpty) {
                                          setModalState(() {
                                            errorText = l10n.translate(
                                              'map.customZone.validation.name',
                                            );
                                          });
                                          return;
                                        }
                                        setModalState(() {
                                          isSaving = true;
                                          errorText = null;
                                        });
                                        final CustomZone newZone = CustomZone(
                                          name: name,
                                          latitude: position.latitude,
                                          longitude: position.longitude,
                                          radius: radiusValue,
                                          zoneType: selectedType,
                                        );
                                        try {
                                          final savedZone =
                                              await _customZoneService.addZone(
                                            newZone,
                                          );
                                          if (context.mounted) {
                                            Navigator.of(context)
                                                .pop(savedZone);
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  l10n.translate(
                                                    'map.customZone.error',
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                          setModalState(() {
                                            isSaving = false;
                                          });
                                        }
                                      },
                                child: isSaving
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        l10n.translate('map.customZone.save'),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showCustomZoneInfo(CustomZone zone) {
    final l10n = context.l10n;
    final labels = {
      'gym': l10n.translate('map.customZone.type.gym'),
      'home': l10n.translate('map.customZone.type.home'),
      'work': l10n.translate('map.customZone.type.work'),
      'other': l10n.translate('map.customZone.type.other'),
    };

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            l10n.translate(
              'map.customZone.info.title',
              params: {'name': zone.name},
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.translate(
                  'map.customZone.info.type',
                  params: {'type': labels[zone.zoneType] ?? zone.zoneType},
                ),
              ),
              Text(
                l10n.translate(
                  'map.customZone.info.radius',
                  params: {'meters': zone.radius.toStringAsFixed(0)},
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
    _mapController?.dispose();
    _mapController = null;
    _markers.clear();
    _customZoneService.zonesNotifier.removeListener(_customZonesListener);
    super.dispose();
  }
}

class _ZoneTypeDot extends StatelessWidget {
  const _ZoneTypeDot({
    required this.color,
    required this.secondary,
  });

  final Color color;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color, secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
