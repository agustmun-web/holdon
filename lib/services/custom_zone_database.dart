import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/custom_zone.dart';

class CustomZoneDatabase {
  CustomZoneDatabase._internal();

  static final CustomZoneDatabase instance = CustomZoneDatabase._internal();

  static const String _databaseName = 'custom_zones.db';
  static const int _databaseVersion = 1;
  static const String _tableCustomZones = 'custom_zones';

  Database? _database;
  final List<CustomZone> _cachedZones = [];

  Future<Database> get _db async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableCustomZones (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            radius REAL NOT NULL,
            zone_type TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<CustomZone>> getZones({bool forceRefresh = false}) async {
    if (_cachedZones.isNotEmpty && !forceRefresh) {
      return List.unmodifiable(_cachedZones);
    }

    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableCustomZones,
      orderBy: 'id DESC',
    );

    _cachedZones
      ..clear()
      ..addAll(maps.map(CustomZone.fromMap));
    return List.unmodifiable(_cachedZones);
  }

  Future<CustomZone> insertZone(CustomZone zone) async {
    final db = await _db;
    final id = await db.insert(
      _tableCustomZones,
      zone.toMap()
        ..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final savedZone = zone.copyWith(id: id);
    _cachedZones.insert(0, savedZone);
    return savedZone;
  }

  Future<void> deleteZone(int id) async {
    final db = await _db;
    await db.delete(
      _tableCustomZones,
      where: 'id = ?',
      whereArgs: [id],
    );
    _cachedZones.removeWhere((zone) => zone.id == id);
  }

  Future<void> updateZone(CustomZone zone) async {
    if (zone.id == null) {
      throw ArgumentError('CustomZone.id no puede ser nulo al actualizar');
    }

    final db = await _db;
    await db.update(
      _tableCustomZones,
      zone.toMap()
        ..remove('id'),
      where: 'id = ?',
      whereArgs: [zone.id],
    );

    final index = _cachedZones.indexWhere((element) => element.id == zone.id);
    if (index != -1) {
      _cachedZones[index] = zone;
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
    _cachedZones.clear();
  }
}

