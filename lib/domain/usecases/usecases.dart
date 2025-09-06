import '../entities/entities.dart';
import '../../data/repositories/trip_repository.dart';
import '../../core/metrics.dart';

class GenerateItineraryUseCase {
  final TripRepository repo;
  GenerateItineraryUseCase(this.repo);

  Future<void> call({
    required String prompt,
    Map<String, dynamic>? previousItinerary,
    required void Function(String) onToken,
    required void Function(TripEntity) onTrip,
    required void Function(TokenMetrics) onMetrics,
    required void Function(String) onError,
  }) async {
    await repo.generateStream(
      prompt: prompt,
      previousItinerary: previousItinerary,
      onToken: onToken,
      onTrip: (t) => onTrip(TripEntity.fromModel(t)),
      onMetrics: onMetrics,
      onError: onError,
    );
  }
}

class SaveTripUseCase {
  final TripRepository repo;
  SaveTripUseCase(this.repo);
  Future<int> call(TripEntity trip) => repo.saveTrip(trip.toModel());
}

class GetTripsUseCase {
  final TripRepository repo;
  GetTripsUseCase(this.repo);
  Future<List<TripEntity>> call() async =>
      (await repo.getTrips()).map(TripEntity.fromModel).toList();
}
