import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trip_planner_flutter/core/constants.dart';

void main() {
  group('API Constants', () {
    test('should have valid backend URL', () {
      expect(ApiConstants.backendBaseUrl, isNotEmpty);
      expect(ApiConstants.backendBaseUrl, contains('http'));
    });

    test('should have valid endpoints', () {
      expect(ApiConstants.generateItineraryEndpoint,
          equals('/generate-itinerary'));
      expect(ApiConstants.healthCheckEndpoint, equals('/health'));
    });

    test('should have reasonable timeout values', () {
      expect(ApiConstants.timeoutSeconds, greaterThan(0));
      expect(ApiConstants.timeoutSeconds, lessThan(120));
    });

    test('should have valid error messages', () {
      expect(ApiConstants.networkErrorMessage, isNotEmpty);
      expect(ApiConstants.serverErrorMessage, isNotEmpty);
      expect(ApiConstants.unauthorizedErrorMessage, isNotEmpty);
    });
  });
}
