import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/metrics.dart';
import '../../data/repositories/trip_repository.dart';
import '../../data/models/itinerary.dart';
import '../widgets/itinerary_view.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ChatPage extends StatefulWidget {
  final TripRepository repo;
  const ChatPage({super.key, required this.repo});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController(
    text: '5 days in Kyoto next April, solo, mid-range budget',
  );
  final ScrollController _scroll = ScrollController();
  final List<_Msg> _messages = [];
  Trip? _currentTrip;
  Trip? _lastTrip;
  bool _streaming = false;
  TokenMetrics? _metrics;

  Future<bool> _isOffline() async {
    final conn = await Connectivity().checkConnectivity();
    return conn == ConnectivityResult.none;
  }

  Future<void> _send() async {
    if (await _isOffline()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are offline. Saved trips are available on Home.'),
        ),
      );
      return;
    }
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;
    setState(() {
      _messages.add(_Msg(role: 'user', text: prompt));
      _messages.add(_Msg(role: 'assistant', text: '')); // streaming container
      _streaming = true;
      _metrics = null;
    });

    await widget.repo.generateStream(
      prompt: prompt,
      previousItinerary: _currentTrip?.toJson(),
      onToken: (t) {
        setState(() {
          _messages.last = _messages.last.copyWith(
            text: _messages.last.text + t,
          );
        });
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      },
      onTrip: (trip) {
        setState(() {
          _lastTrip = _currentTrip;
          _currentTrip = trip;
        });
      },
      onMetrics: (m) {
        setState(() {
          _metrics = m;
          _streaming = false;
        });
      },
    );
  }

  Future<void> _save() async {
    if (_currentTrip == null) return;
    final id = await widget.repo.saveTrip(_currentTrip!);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Trip saved (#$id)')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan a Trip'),
        actions: [
          if (_currentTrip != null)
            IconButton(onPressed: _save, icon: const Icon(Icons.save_alt)),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_currentTrip == null ? 0 : 1),
                  itemBuilder: (_, i) {
                    if (_currentTrip != null && i == _messages.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: ItineraryView(
                          trip: _currentTrip!,
                          previous: _lastTrip,
                        ),
                      );
                    }
                    final m = _messages[i];
                    final align = m.role == 'user'
                        ? Alignment.centerRight
                        : Alignment.centerLeft;
                    final color = m.role == 'user'
                        ? Colors.teal.shade100
                        : Colors.grey.shade200;
                    return Align(
                      alignment: align,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(m.text),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: 'Describe your trip...',
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _send,
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_metrics != null)
            Positioned(
              right: 12,
              top: 12,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Token Usage',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Prompt: ${_metrics!.promptTokens}'),
                      Text('Completion: ${_metrics!.completionTokens}'),
                      Text('Total: ${_metrics!.totalTokens}'),
                    ],
                  ),
                ),
              ),
            ),
          if (_streaming)
            const Positioned(left: 12, bottom: 86, child: _TypingIndicator()),
        ],
      ),
    );
  }
}

class _Msg {
  final String role;
  final String text;
  const _Msg({required this.role, required this.text});
  _Msg copyWith({String? role, String? text}) =>
      _Msg(role: role ?? this.role, text: text ?? this.text);
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = (_c.value * 3).floor() % 3;
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text('Assistant is typing' + '.' * (t + 1)),
          ),
        );
      },
    );
  }
}
