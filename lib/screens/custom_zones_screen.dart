import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/custom_zone.dart';
import '../services/custom_zone_database.dart';
import '../services/custom_zone_events.dart';
import '../services/geofence_service.dart';
import '../services/optimized_geofence_service.dart';

class CustomZonesScreen extends StatefulWidget {
  const CustomZonesScreen({super.key});

  @override
  State<CustomZonesScreen> createState() => _CustomZonesScreenState();
}

class _CustomZonesScreenState extends State<CustomZonesScreen> {
  final CustomZoneDatabase _zoneDatabase = CustomZoneDatabase.instance;
  final GeofenceService _geofenceService = GeofenceService();
  final OptimizedGeofenceService _optimizedGeofenceService = OptimizedGeofenceService();

  List<CustomZone> _zones = <CustomZone>[];
  bool _isLoading = true;
  String? _errorMessage;
  int? _deletingZoneId;
  bool _reloadScheduled = false;
  late final StreamSubscription<void> _zoneSubscription;

  @override
  void initState() {
    super.initState();
    _zoneSubscription = CustomZoneEvents.instance.stream.listen((_) {
      if (mounted) {
        _scheduleReload();
      }
    });
    _loadZones();
  }

  @override
  void dispose() {
    _zoneSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadZones({bool showLoader = true, bool forceRefresh = false}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final List<CustomZone> zones = await _zoneDatabase.getZones(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _zones = List<CustomZone>.from(zones);
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _scheduleReload() {
    if (!mounted || _reloadScheduled) return;
    _reloadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadScheduled = false;
      if (mounted) {
        _loadZones(showLoader: false, forceRefresh: true);
      }
    });
  }

  Future<void> _onRefresh() async {
    await _loadZones(forceRefresh: true);
  }

  Future<void> _confirmDelete(CustomZone zone) async {
    if (zone.id == null) {
      return;
    }
    final l10n = context.l10n;
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(l10n.translate('zones.delete.confirm.title')),
              content: Text(
                l10n.translate(
                  'zones.delete.confirm.message',
                  params: {'name': zone.name},
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.translate('common.cancel')),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5B5B),
                  ),
                  child: Text(l10n.translate('common.delete')),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _deletingZoneId = zone.id;
    });

    bool deleted = false;
    try {
      await _zoneDatabase.deleteZone(zone.id!);
      deleted = true;
      _scheduleReload();
      final List<CustomZone> zones = await _zoneDatabase.getZones(forceRefresh: true);
      await Future.wait([
        _geofenceService.syncCustomZones(zones),
        _optimizedGeofenceService.syncCustomZones(zones),
      ]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('zones.delete.success'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate(
              'zones.delete.error',
              params: {'error': e.toString()},
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingZoneId = null;
        });
      }
      if (deleted) {
        _scheduleReload();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('zones.title')),
        backgroundColor: const Color(0xFF061414),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : () => _loadZones(forceRefresh: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_outlined,
                color: Color(0xFFFFC107),
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.translate(
                  'zones.load.error',
                  params: {'error': _errorMessage ?? ''},
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => _loadZones(forceRefresh: true),
                child: Text(l10n.translate('common.retry')),
              ),
            ],
          ),
        ),
      );
    }

    if (_zones.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.place_outlined,
                  color: Color(0xFF38B05F),
                  size: 72,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.translate('zones.empty.title'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.translate('zones.empty.subtitle'),
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: _zones.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final CustomZone zone = _zones[index];
          final bool isDeleting = _deletingZoneId == zone.id;
          return Card(
            color: const Color(0xFF0E1B1B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Text(
                zone.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.translate('zones.item.type', params: {'type': zone.zoneType}),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      l10n.translate(
                        'zones.item.radius',
                        params: {'meters': zone.radius.toStringAsFixed(0)},
                      ),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      l10n.translate(
                        'zones.item.coordinates',
                        params: {
                          'lat': zone.latitude.toStringAsFixed(5),
                          'lng': zone.longitude.toStringAsFixed(5),
                        },
                      ),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              trailing: isDeleting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: const Color(0xFFFF5B5B),
                      tooltip: l10n.translate('common.delete'),
                      onPressed: () => _confirmDelete(zone),
                    ),
            ),
          );
        },
      ),
    );
  }
}

