import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trip_planner_flutter/data/models/itinerary.dart';

void main() {
  group('Trip Model Tests', () {
    testWidgets('Trip should serialize to/from JSON correctly',
        (WidgetTester tester) async {
      final trip = Trip()
        ..id = 1
        ..title = 'Test Trip'
        ..startDate = '2024-04-01'
        ..endDate = '2024-04-05'
        ..days = [
          TripDay()
            ..date = '2024-04-01'
            ..summary = 'Day 1'
            ..items = [
              TripItem()
                ..time = '10:00'
                ..activity = 'Test Activity'
                ..location = '48.8566,2.3522'
            ]
        ];

      final json = trip.toJson();
      final fromJson = Trip.fromJson(json);

      expect(fromJson.id, equals(trip.id));
      expect(fromJson.title, equals(trip.title));
      expect(fromJson.startDate, equals(trip.startDate));
      expect(fromJson.endDate, equals(trip.endDate));
      expect(fromJson.days.length, equals(1));
      expect(fromJson.days.first.date, equals('2024-04-01'));
      expect(fromJson.days.first.items.length, equals(1));
      expect(fromJson.days.first.items.first.activity, equals('Test Activity'));
    });

    test('TripDay should handle empty items list', () {
      final day = TripDay()
        ..date = '2024-04-01'
        ..summary = 'Empty day'
        ..items = [];

      final json = day.toJson();
      final fromJson = TripDay.fromJson(json);

      expect(fromJson.date, equals(day.date));
      expect(fromJson.summary, equals(day.summary));
      expect(fromJson.items, isEmpty);
    });

    test('TripItem should handle coordinate location format', () {
      final item = TripItem()
        ..time = '14:30'
        ..activity = 'Visit Eiffel Tower'
        ..location = '48.8584,2.2945';

      final json = item.toJson();
      final fromJson = TripItem.fromJson(json);

      expect(fromJson.time, equals(item.time));
      expect(fromJson.activity, equals(item.activity));
      expect(fromJson.location, equals(item.location));
    });
  });
}
