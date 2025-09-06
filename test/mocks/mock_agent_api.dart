import 'package:smart_trip_planner_flutter/data/sources/agent_api.dart';
import 'package:smart_trip_planner_flutter/core/metrics.dart';

class MockAgentApi extends AgentApi {
  bool _isOnline = true;
  bool _isHealthy = true;
  String? _errorToThrow;
  bool _shouldSucceed = true;

  void mockSuccessfulGeneration() {
    _isOnline = true;
    _isHealthy = true;
    _shouldSucceed = true;
    _errorToThrow = null;
  }

  void mockOffline() {
    _isOnline = false;
  }

  void mockBackendUnavailable() {
    _isOnline = true;
    _isHealthy = false;
  }

  void mockOnlineAndHealthy() {
    _isOnline = true;
    _isHealthy = true;
  }

  void mockApiError(String error) {
    _isOnline = true;
    _isHealthy = true;
    _shouldSucceed = false;
    _errorToThrow = error;
  }

  @override
  Future<void> generateItineraryStream({
    required String prompt,
    Map<String, dynamic>? previousItinerary,
    List<Map<String, String>>? chatHistory,
    required StreamCallback onToken,
    required JsonCallback onJson,
    required MetricsCallback onMetrics,
    ErrorCallback? onError,
  }) async {
    if (!_shouldSucceed && _errorToThrow != null) {
      onError?.call(_errorToThrow!);
      return;
    }

    // Simulate streaming tokens
    await Future.delayed(const Duration(milliseconds: 10));
    onToken('Planning');
    await Future.delayed(const Duration(milliseconds: 10));
    onToken(' your');
    await Future.delayed(const Duration(milliseconds: 10));
    onToken(' trip...');

    // Simulate trip generation
    await Future.delayed(const Duration(milliseconds: 50));
    onJson({
      'title': 'Paris Adventure',
      'startDate': '2024-04-01',
      'endDate': '2024-04-05',
      'days': [
        {
          'date': '2024-04-01',
          'summary': 'Arrival and exploration',
          'items': [
            {
              'time': '10:00',
              'activity': 'Arrive at Charles de Gaulle Airport',
              'location': '48.8566,2.3522'
            }
          ]
        }
      ]
    });

    // Simulate metrics
    await Future.delayed(const Duration(milliseconds: 10));
    onMetrics(TokenMetrics(
      promptTokens: 50,
      completionTokens: 200,
      totalTokens: 250,
    ));
  }

  @override
  Future<bool> isOnline() async {
    return _isOnline;
  }

  @override
  Future<bool> healthCheck() async {
    return _isHealthy;
  }

  @override
  void dispose() {
    // Mock implementation - nothing to dispose
  }
}
