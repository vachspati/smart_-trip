import 'package:flutter/material.dart';
import 'package:smart_trip_planner_flutter/data/local_db.dart';
import 'package:isar/isar.dart';
import '../../data/models/itinerary.dart';
import '../widgets/itinerary_view.dart';

class TripDetailPage extends StatelessWidget {
  final Id tripId;
  const TripDetailPage({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Trip?>(
      future: LocalDb.getTrip(tripId),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final trip = snap.data!;
        return Scaffold(
          appBar: AppBar(title: Text(trip.title)),
          body: Padding(
            padding: const EdgeInsets.all(12.0),
            child: ItineraryView(trip: trip),
          ),
        );
      },
    );
  }
}
