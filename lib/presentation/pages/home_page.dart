import 'package:flutter/material.dart';
import '../../data/repositories/trip_repository.dart';
import '../../data/sources/agent_api.dart';
import '../../domain/usecases/usecases.dart';
import 'chat_page.dart';
import 'trip_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final repo = TripRepository(agentApi: AgentApi());

  late final GetTripsUseCase _getTrips = GetTripsUseCase(repo);
  List<TripSummary> _trips = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final trips = await _getTrips();
    setState(() {
      _trips = trips
          .map(
            (t) => TripSummary(
              id: t.id,
              title: t.title,
              dates: '${t.startDate} → ${t.endDate}',
            ),
          )
          .toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Trip Planner')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => ChatPage(repo: repo)));
          await _load();
        },
        label: const Text('New Trip'),
        icon: const Icon(Icons.chat),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _trips.isEmpty
          ? const Center(child: Text('No trips saved yet. Tap "New Trip".'))
          : ListView.builder(
              itemCount: _trips.length,
              itemBuilder: (_, i) {
                final t = _trips[i];
                return ListTile(
                  title: Text(t.title),
                  subtitle: Text(t.dates),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TripDetailPage(tripId: t.id!),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class TripSummary {
  final int? id;
  final String title;
  final String dates;
  TripSummary({required this.id, required this.title, required this.dates});
}
