import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/metrics.dart';
import '../../data/repositories/trip_repository.dart';
import '../../data/models/itinerary.dart';
import '../widgets/itinerary_view.dart';

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

  Future<void> _send() async {
    // Check backend availability
    if (!await widget.repo.isBackendAvailable()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'You are offline or backend is unavailable. Saved trips are available on Home.'),
          backgroundColor: Colors.orange,
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

    _controller.clear();

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
      onError: (error) {
        setState(() {
          _streaming = false;
          _messages.last = _messages.last.copyWith(
            text: 'Error: $error',
            isError: true,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                _controller.text = prompt;
                _send();
              },
            ),
          ),
        );
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Plan a Trip',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          if (_currentTrip != null)
            IconButton(
              onPressed: _save, 
              icon: const Icon(Icons.save_alt),
              tooltip: 'Save Trip',
            ),
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
                    final isUser = m.role == 'user';
                    final align = isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft;
                    
                    return Align(
                      alignment: align,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.85,
                        ),
                        decoration: BoxDecoration(
                          color: isUser 
                              ? Theme.of(context).primaryColor
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: isUser 
                              ? null 
                              : Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          m.text.isEmpty ? "..." : m.text,
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black87,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.grey.shade400,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _controller,
                              decoration: const InputDecoration(
                                hintText: 'Describe your trip...',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              onSubmitted: (_) => _send(),
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: _streaming 
                                ? Colors.grey.shade400 
                                : Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _streaming ? null : _send,
                            icon: Icon(
                              _streaming ? Icons.hourglass_empty : Icons.send,
                              color: Colors.white,
                              size: 24,
                            ),
                            splashRadius: 25,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
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
            Positioned(
              left: 16, 
              bottom: 100, 
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const _TypingIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class _Msg {
  final String role;
  final String text;
  final bool isError;
  const _Msg({required this.role, required this.text, this.isError = false});
  _Msg copyWith({String? role, String? text, bool? isError}) => _Msg(
      role: role ?? this.role,
      text: text ?? this.text,
      isError: isError ?? this.isError);
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
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smart_toy,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Assistant is typing' + '.' * (t + 1),
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}
