import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/itinerary.dart';

class LocalDb {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'trips.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trips(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        days TEXT NOT NULL
      )
    ''');
  }

  static Future<int> putTrip(Trip trip) async {
    final db = await database;
    return await db.insert(
      'trips',
      {
        'title': trip.title,
        'startDate': trip.startDate,
        'endDate': trip.endDate,
        'days': jsonEncode(trip.days.map((day) => day.toJson()).toList()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Trip>> getTrips() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('trips');

    return List.generate(maps.length, (i) {
      final map = maps[i];
      final daysList = jsonDecode(map['days']) as List;
      return Trip()
        ..id = map['id']
        ..title = map['title']
        ..startDate = map['startDate']
        ..endDate = map['endDate']
        ..days = daysList.map((dayJson) => TripDay.fromJson(dayJson)).toList();
    });
  }

  static Future<Trip?> getTrip(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'trips',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final map = maps.first;
      final daysList = jsonDecode(map['days']) as List;
      return Trip()
        ..id = map['id']
        ..title = map['title']
        ..startDate = map['startDate']
        ..endDate = map['endDate']
        ..days = daysList.map((dayJson) => TripDay.fromJson(dayJson)).toList();
    }
    return null;
  }

  static Future<void> deleteTrip(int id) async {
    final db = await database;
    await db.delete(
      'trips',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
