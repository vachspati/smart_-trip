import '../models/itinerary.dart';
import '../sources/agent_api.dart';
import '../local_db.dart';
import '../../core/metrics.dart';

class TripRepository {
  final AgentApi agentApi;

  TripRepository({required this.agentApi});

  Future<void> generateStream({
    required String prompt,
    Map<String, dynamic>? previousItinerary,
    required void Function(String token) onToken,
    required void Function(Trip trip) onTrip,
    required void Function(TokenMetrics metrics) onMetrics,
  }) async {
    await agentApi.generateItineraryStream(
      prompt: prompt,
      previousItinerary: previousItinerary,
      onToken: onToken,
      onJson: (json) => onTrip(Trip.fromJson(json)),
      onMetrics: onMetrics,
      chatHistory: [],
    );
  }

  Future<int> saveTrip(Trip trip) => LocalDb.putTrip(trip);
  Future<List<Trip>> getTrips() => LocalDb.getTrips();
}
