import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trip_planner_flutter/core/metrics.dart';

void main() {
  group('TokenMetrics', () {
    test('should create from JSON correctly', () {
      final json = {
        'promptTokens': 50,
        'completionTokens': 200,
        'totalTokens': 250,
      };

      final metrics = TokenMetrics.fromJson(json);

      expect(metrics.promptTokens, equals(50));
      expect(metrics.completionTokens, equals(200));
      expect(metrics.totalTokens, equals(250));
    });

    test('should handle missing values with defaults', () {
      final json = <String, dynamic>{};

      final metrics = TokenMetrics.fromJson(json);

      expect(metrics.promptTokens, equals(0));
      expect(metrics.completionTokens, equals(0));
      expect(metrics.totalTokens, equals(0));
    });

    test('should calculate total correctly', () {
      final metrics = TokenMetrics(
        promptTokens: 25,
        completionTokens: 75,
        totalTokens: 100,
      );

      expect(metrics.totalTokens, equals(100));
    });
  });
}
