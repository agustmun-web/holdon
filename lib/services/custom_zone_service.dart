import 'package:flutter/foundation.dart';

import '../data/custom_zone_database.dart';
import '../models/custom_zone.dart';

class CustomZoneService {
  CustomZoneService._();
  static final CustomZoneService instance = CustomZoneService._();

  final ValueNotifier<List<CustomZone>> zonesNotifier =
      ValueNotifier<List<CustomZone>>(<CustomZone>[]);

  bool _initialized = false;
  final CustomZoneDatabase _database = CustomZoneDatabase.instance;

  List<CustomZone> get zones => zonesNotifier.value;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    final storedZones = await _database.getAllZones();
    zonesNotifier.value = List<CustomZone>.unmodifiable(storedZones);
    _initialized = true;
  }

  Future<CustomZone> addZone(CustomZone zone) async {
    await ensureInitialized();
    try {
      final id = await _database.insertZone(zone);
      final savedZone = zone.copyWith(id: id);
      zonesNotifier.value = List<CustomZone>.unmodifiable(
        [...zonesNotifier.value, savedZone],
      );
      return savedZone;
    } catch (e, stackTrace) {
      debugPrint('❌ Error insertando zona personalizada: $e');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  Future<void> deleteZone(int id) async {
    await ensureInitialized();
    await _database.deleteZone(id);
    zonesNotifier.value = List<CustomZone>.unmodifiable(
      zonesNotifier.value.where((zone) => zone.id != id),
    );
  }
}

