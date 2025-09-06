import 'package:flutter/material.dart';
import '../../data/models/itinerary.dart';
import '../../core/maps_integration.dart';

class ItineraryView extends StatelessWidget {
  final Trip trip;
  final Trip? previous;
  const ItineraryView({super.key, required this.trip, this.previous});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(trip.title, style: Theme.of(context).textTheme.titleLarge),
        Text(
          '${trip.startDate} → ${trip.endDate}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        ...trip.days.map((d) {
          final prevDay = previous?.days.firstWhere(
            (pd) => pd.date == d.date,
            orElse: () => TripDay()
              ..date = ''
              ..summary = ''
              ..items = [],
          );
          return _DayCard(day: d, prev: prevDay);
        }),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  final TripDay day;
  final TripDay? prev;
  const _DayCard({required this.day, this.prev});

  bool _changedSummary() => prev != null && prev!.summary != day.summary;

  bool _changedItem(TripItem? it) {
    if (prev == null || it == null) return false;
    try {
      final p = prev!.items.firstWhere((pi) => pi.time == it.time);
      return p.activity != it.activity || p.location != it.location;
    } catch (_) {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(day.date, style: Theme.of(context).textTheme.titleMedium),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: _changedSummary()
                  ? BoxDecoration(
                      color: Colors.yellow.shade100,
                      borderRadius: BorderRadius.circular(6),
                    )
                  : null,
              child: Text(day.summary),
            ),
            const Divider(),
            ...day.items.map((it) {
              return Container(
                decoration: _changedItem(it)
                    ? BoxDecoration(
                        color: Colors.lightGreen.shade50,
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule),
                  title: Text('${it.time}  •  ${it.activity}'),
                  subtitle: Text(it.location),
                  trailing: IconButton(
                    icon: const Icon(Icons.map),
                    onPressed: () => _openMaps(it.location),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _openMaps(String location) async {
    try {
      await MapsIntegration.openLocation(location);
    } catch (e) {
      // Fallback: try to search for the location as text
      try {
        await MapsIntegration.searchLocation(location);
      } catch (e) {
        // Handle error silently or show a snackbar
        debugPrint('Failed to open maps: $e');
      }
    }
  }
}
