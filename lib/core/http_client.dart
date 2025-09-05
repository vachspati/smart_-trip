import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

typedef ChunkHandler = void Function(String chunk);

class StreamingHttpClient {
  final http.Client _client = http.Client();

  Future<void> postStream({
    required Uri uri,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
    required ChunkHandler onChunk,
  }) async {
    final req = http.Request('POST', uri);
    req.headers.addAll(headers);
    req.body = jsonEncode(body);

    final resp = await _client.send(req);
    if (resp.statusCode >= 400) {
      final text = await resp.stream.bytesToString();
      throw HttpException('HTTP ${resp.statusCode}: $text');
    }

    // Stream chunks line-by-line (supports SSE-like responses or newline-delimited JSON)
    await for (final bytes in resp.stream) {
      final chunk = utf8.decode(bytes);
      onChunk(chunk);
    }
  }

  void close() => _client.close();
}
