import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'models/itinerary.dart';

class LocalDb {
  static Isar? _isar;

  static Future<Isar> get isar async {
    if (_isar != null) return _isar!;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [TripSchema],
      directory: dir.path,
      inspector: false,
    );
    return _isar!;
  }

  static Future<int> putTrip(Trip trip) async {
    final isar = await LocalDb.isar;
    return await isar.writeTxn(() async {
      return await isar.trips.put(trip);
    });
  }

  static Future<List<Trip>> getTrips() async {
    final isar = await LocalDb.isar;
    return await isar.trips.where().findAll();
  }

  static Future<Trip?> getTrip(Id id) async {
    final isar = await LocalDb.isar;
    return await isar.trips.get(id);
  }

  static Future<void> deleteTrip(Id id) async {
    final isar = await LocalDb.isar;
    await isar.writeTxn(() async {
      await isar.trips.delete(id);
    });
  }
}
