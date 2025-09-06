import '../models/itinerary.dart';
import '../sources/agent_api.dart';
import '../local_db.dart';
import '../../core/metrics.dart';
import '../../core/errors.dart';

class TripRepository {
  final AgentApi agentApi;

  TripRepository({required this.agentApi});

  Future<void> generateStream({
    required String prompt,
    Map<String, dynamic>? previousItinerary,
    required void Function(String token) onToken,
    required void Function(Trip trip) onTrip,
    required void Function(TokenMetrics metrics) onMetrics,
    required void Function(String error) onError,
  }) async {
    try {
      // Check if device is online
      if (!await agentApi.isOnline()) {
        onError(
            'No internet connection. Please check your network and try again.');
        return;
      }

      // Check backend health
      if (!await agentApi.healthCheck()) {
        onError(
            'Backend service is currently unavailable. Please try again later.');
        return;
      }

      await agentApi.generateItineraryStream(
        prompt: prompt,
        previousItinerary: previousItinerary,
        onToken: onToken,
        onJson: (json) => onTrip(Trip.fromJson(json)),
        onMetrics: onMetrics,
        onError: onError,
        chatHistory: [],
      );
    } on NetworkException catch (e) {
      onError(e.message);
    } on UnauthorizedException catch (e) {
      onError(e.message);
    } on RateLimitException catch (e) {
      onError(e.message);
    } catch (e) {
      onError('An unexpected error occurred: $e');
    }
  }

  Future<int> saveTrip(Trip trip) async {
    try {
      return await LocalDb.putTrip(trip);
    } catch (e) {
      throw AppException('Failed to save trip: $e');
    }
  }

  Future<List<Trip>> getTrips() async {
    try {
      return await LocalDb.getTrips();
    } catch (e) {
      throw AppException('Failed to load trips: $e');
    }
  }

  Future<Trip?> getTrip(int id) async {
    try {
      return await LocalDb.getTrip(id);
    } catch (e) {
      throw AppException('Failed to load trip: $e');
    }
  }

  Future<void> deleteTrip(int id) async {
    try {
      await LocalDb.deleteTrip(id);
    } catch (e) {
      throw AppException('Failed to delete trip: $e');
    }
  }

  /// Check if the app can connect to the backend
  Future<bool> isBackendAvailable() async {
    try {
      return await agentApi.isOnline() && await agentApi.healthCheck();
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    agentApi.dispose();
  }
}
