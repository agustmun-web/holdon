import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/custom_zone.dart';
import '../services/custom_zone_service.dart';

class CustomZonesScreen extends StatefulWidget {
  const CustomZonesScreen({super.key});

  @override
  State<CustomZonesScreen> createState() => _CustomZonesScreenState();
}

class _CustomZonesScreenState extends State<CustomZonesScreen> {
  final CustomZoneService _zoneService = CustomZoneService.instance;
  late final ValueNotifier<List<CustomZone>> _zonesNotifier;

  @override
  void initState() {
    super.initState();
    _zonesNotifier = _zoneService.zonesNotifier;
    _zoneService.ensureInitialized();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          l10n.translate('customZones.title'),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0E1720),
              Color(0xFF0B131C),
            ],
          ),
        ),
        child: SafeArea(
          child: ValueListenableBuilder<List<CustomZone>>(
            valueListenable: _zonesNotifier,
            builder: (context, zones, _) {
              if (zones.isEmpty) {
                return _EmptyState(message: l10n.translate('customZones.empty'));
              }

              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                itemCount: zones.length,
                itemBuilder: (context, index) {
                  final zone = zones[index];
                  return _CustomZoneCard(
                    zone: zone,
                    onDelete: () => _confirmDeleteZone(zone),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteZone(CustomZone zone) async {
    final l10n = context.l10n;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            l10n.translate(
              'customZones.delete.title',
              params: {'name': zone.name},
            ),
          ),
          content: Text(l10n.translate('customZones.delete.message')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.translate('common.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                l10n.translate('customZones.delete.confirm'),
                style: const TextStyle(color: Color(0xFFFF5B5B)),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _zoneService.deleteZone(zone.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.translate(
                'customZones.delete.success',
                params: {'name': zone.name},
              ),
            ),
          ),
        );
      }
    }
  }
}

class _CustomZoneCard extends StatelessWidget {
  const _CustomZoneCard({
    required this.zone,
    required this.onDelete,
  });

  final CustomZone zone;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final Map<String, String> typeLabels = {
      'gym': l10n.translate('map.customZone.type.gym'),
      'home': l10n.translate('map.customZone.type.home'),
      'work': l10n.translate('map.customZone.type.work'),
      'other': l10n.translate('map.customZone.type.other'),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.02),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ZoneTypeBadge(zone: zone),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.translate(
                          'customZones.info.type',
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      Text(
                        typeLabels[zone.zoneType] ?? zone.zoneType,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: const Color(0xFFFF5B5B),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.straighten,
                    label: l10n.translate('customZones.info.radius'),
                    value: l10n.translate(
                      'map.customZone.info.radius',
                      params: {'meters': zone.radius.toStringAsFixed(0)},
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.location_pin,
                    label: l10n.translate('customZones.info.coordinates'),
                    value:
                        '${zone.latitude.toStringAsFixed(5)}, ${zone.longitude.toStringAsFixed(5)}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.white.withOpacity(0.6)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF34A853),
                  Color(0xFF21C55E),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF34A853).withOpacity(0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(
              Icons.layers_clear,
              size: 52,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ZoneTypeBadge extends StatelessWidget {
  const _ZoneTypeBadge({required this.zone});

  final CustomZone zone;

  @override
  Widget build(BuildContext context) {
    final Map<String, Color> colors = {
      'gym': const Color(0xFF2563EB),
      'home': const Color(0xFF22C55E),
      'work': const Color(0xFFF97316),
      'other': const Color(0xFF6B7280),
    };
    final Color baseColor =
        colors[zone.zoneType] ?? colors['other'] ?? Colors.white;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor.withOpacity(0.8),
            baseColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.45),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(
        Icons.layers,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

