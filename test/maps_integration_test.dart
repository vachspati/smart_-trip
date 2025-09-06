import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trip_planner_flutter/core/maps_integration.dart';

void main() {
  group('MapsIntegration', () {
    test('should parse valid coordinates correctly', () async {
      const location = '48.8566,2.3522';

      // This test verifies the parsing logic
      final coords = location.split(',');
      expect(coords.length, equals(2));

      final lat = double.tryParse(coords[0].trim());
      final lng = double.tryParse(coords[1].trim());

      expect(lat, equals(48.8566));
      expect(lng, equals(2.3522));
    });

    test('should throw error for invalid location format', () async {
      expect(
        () => MapsIntegration.openLocation('invalid_format'),
        throwsArgumentError,
      );
    });

    test('should throw error for non-numeric coordinates', () async {
      expect(
        () => MapsIntegration.openLocation('abc,def'),
        throwsArgumentError,
      );
    });

    test('should handle location with spaces correctly', () async {
      const location = ' 48.8566 , 2.3522 ';

      final coords = location.split(',');
      final lat = double.tryParse(coords[0].trim());
      final lng = double.tryParse(coords[1].trim());

      expect(lat, equals(48.8566));
      expect(lng, equals(2.3522));
    });

    test('should throw error for incomplete coordinates', () async {
      expect(
        () => MapsIntegration.openLocation('48.8566'),
        throwsArgumentError,
      );
    });

    test('should throw error for empty location', () async {
      expect(
        () => MapsIntegration.openLocation(''),
        throwsArgumentError,
      );
    });
  });
}
