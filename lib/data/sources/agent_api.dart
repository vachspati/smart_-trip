import '../../core/backend_api_client.dart';
import '../../core/metrics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef StreamCallback = void Function(String token);
typedef JsonCallback = void Function(Map<String, dynamic> json);
typedef MetricsCallback = void Function(TokenMetrics metrics);
typedef ErrorCallback = void Function(String error);

class AgentApi {
  final BackendApiClient _client;

  AgentApi({BackendApiClient? client}) : _client = client ?? BackendApiClient();

  Future<void> generateItineraryStream({
    required String prompt,
    Map<String, dynamic>? previousItinerary,
    List<Map<String, String>>? chatHistory,
    required StreamCallback onToken,
    required JsonCallback onJson,
    required MetricsCallback onMetrics,
    ErrorCallback? onError,
  }) async {
    await _client.generateItineraryStream(
      prompt: prompt,
      previousItinerary: previousItinerary,
      chatHistory: chatHistory,
      onToken: onToken,
      onTrip: onJson,
      onMetrics: onMetrics,
      onError: onError ?? (error) => throw Exception(error),
    );
  }

  /// Search flights
  Future<Map<String, dynamic>> searchFlights(
      Map<String, dynamic> searchParams) async {
    final response = await _client.post('/search-flights', data: searchParams);
    return response;
  }

  /// Search hotels
  Future<Map<String, dynamic>> searchHotels(
      Map<String, dynamic> searchParams) async {
    final response = await _client.post('/search-hotels', data: searchParams);
    return response;
  }

  /// Search car rentals
  Future<Map<String, dynamic>> searchCars(
      Map<String, dynamic> searchParams) async {
    final response = await _client.post('/search-cars', data: searchParams);
    return response;
  }

  /// Search restaurants
  Future<Map<String, dynamic>> searchRestaurants(
      Map<String, dynamic> searchParams) async {
    final response =
        await _client.post('/search-restaurants', data: searchParams);
    return response;
  }

  /// Get popular destinations
  Future<List<dynamic>> getDestinations() async {
    final response = await _client.get('/destinations');
    return response as List<dynamic>;
  }

  /// Get travel tips
  Future<List<dynamic>> getTips() async {
    final response = await _client.get('/tips');
    return response as List<dynamic>;
  }

  /// Check if backend is healthy and reachable
  Future<bool> healthCheck() => _client.healthCheck();

  /// Check if device is online
  Future<bool> isOnline() => _client.isOnline();

  void dispose() {
    _client.dispose();
  }
}

// Provider for AgentApi
final agentApiProvider = Provider<AgentApi>((ref) {
  return AgentApi();
});
