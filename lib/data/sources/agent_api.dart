import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/env.dart';
import '../../core/http_client.dart';
import '../../core/metrics.dart';
import '../models/itinerary.dart';

typedef StreamCallback = void Function(String token);
typedef JsonCallback = void Function(Map<String, dynamic> json);
typedef MetricsCallback = void Function(TokenMetrics metrics);

class AgentApi {
  final _client = StreamingHttpClient();

  Uri _endpoint() {
    final base = Env.functionsBaseUrl;
    return Uri.parse('$base/${Env.functionsName}');
  }

  Future<void> generateItineraryStream({
    required String prompt,
    Map<String, dynamic>? previousItinerary,
    List<Map<String, String>>? chatHistory,
    required StreamCallback onToken,
    required JsonCallback onJson,
    required MetricsCallback onMetrics,
  }) async {
    final uri = _endpoint();
    await _client.postStream(
      uri: uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      },
      body: {
        'prompt': prompt,
        'previousItinerary': previousItinerary,
        'chatHistory': chatHistory ?? [],
      },
      onChunk: (chunk) {
        // Accept both SSE style: "data: {...}\n\n" and plain text tokens
        for (final line in const LineSplitter().convert(chunk)) {
          if (line.startsWith('data:')) {
            final data = line.substring(5).trim();
            if (data == '[DONE]') return;
            try {
              final obj = jsonDecode(data) as Map<String, dynamic>;
              final type = obj['type'];
              if (type == 'token') {
                onToken(obj['text'] as String);
              } else if (type == 'json') {
                onJson(obj['payload'] as Map<String, dynamic>);
              } else if (type == 'metrics') {
                onMetrics(
                  TokenMetrics.fromJson(obj['payload'] as Map<String, dynamic>),
                );
              }
            } catch (_) {
              // ignore parse errors
            }
          } else {
            // plain chunked text
            onToken(line);
          }
        }
      },
    );
  }
}
