import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/custom_zone.dart';

class CustomZoneDatabase {
  CustomZoneDatabase._();
  static final CustomZoneDatabase instance = CustomZoneDatabase._();

  static const _databaseName = 'custom_zones.db';
  static const _databaseVersion = 1;
  static const _tableName = 'custom_zones';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            radius REAL NOT NULL,
            zone_type TEXT NOT NULL
          )
        ''');
      },
      onOpen: (db) async {
        await _ensureSchema(db);
      },
    );
  }

  Future<void> _ensureSchema(Database db) async {
    final columns =
        await db.rawQuery('PRAGMA table_info($_tableName)');
    final hasCamelCase = columns.any(
      (column) =>
          (column['name'] as String?)?.toLowerCase() == 'zonetype',
    );
    final hasSnakeCase = columns.any(
      (column) =>
          (column['name'] as String?)?.toLowerCase() == 'zone_type',
    );

    if (!hasSnakeCase) {
      await db.execute(
        "ALTER TABLE $_tableName ADD COLUMN zone_type TEXT NOT NULL DEFAULT 'other'",
      );
    }

    if (hasCamelCase) {
      await db.execute(
        "UPDATE $_tableName SET zone_type = zoneType WHERE zoneType IS NOT NULL AND TRIM(zoneType) != ''",
      );
    }

    await db.execute(
      "UPDATE $_tableName SET zone_type = 'other' WHERE zone_type IS NULL OR TRIM(zone_type) = ''",
    );
  }

  Future<List<CustomZone>> getAllZones() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      orderBy: 'id DESC',
    );
    return maps.map(CustomZone.fromMap).toList();
  }

  Future<int> insertZone(CustomZone zone) async {
    final db = await database;
    return db.insert(
      _tableName,
      zone.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteZone(int id) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

