import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class MockHttpClient extends http.BaseClient {
  final List<MockResponse> _responses = [];
  int _callCount = 0;

  void mockResponse(int statusCode, String body) {
    _responses.add(MockResponse(statusCode, body, false));
  }

  void mockStreamResponse(int statusCode, String body) {
    _responses.add(MockResponse(statusCode, body, true));
  }

  void mockNetworkError() {
    _responses.add(MockResponse(0, '', false, networkError: true));
  }

  void mockTimeoutError() {
    _responses.add(MockResponse(0, '', false, timeoutError: true));
  }

  void reset() {
    _responses.clear();
    _callCount = 0;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (_callCount >= _responses.length) {
      throw Exception('No more mock responses available');
    }

    final mockResponse = _responses[_callCount++];

    if (mockResponse.networkError) {
      throw const SocketException('Network error');
    }

    if (mockResponse.timeoutError) {
      throw TimeoutException('Request timeout', const Duration(seconds: 30));
    }

    if (mockResponse.isStream) {
      final controller = StreamController<List<int>>();

      // Simulate streaming by sending chunks
      final chunks = mockResponse.body.split('\n');
      for (final chunk in chunks) {
        if (chunk.isNotEmpty) {
          controller.add(utf8.encode(chunk + '\n'));
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }
      controller.close();

      return http.StreamedResponse(
        controller.stream,
        mockResponse.statusCode,
        headers: {'content-type': 'text/event-stream'},
      );
    } else {
      final bytes = utf8.encode(mockResponse.body);
      final stream = Stream.fromIterable([bytes]);

      return http.StreamedResponse(
        stream,
        mockResponse.statusCode,
        headers: {'content-type': 'application/json'},
      );
    }
  }
}

class MockResponse {
  final int statusCode;
  final String body;
  final bool isStream;
  final bool networkError;
  final bool timeoutError;

  MockResponse(
    this.statusCode,
    this.body,
    this.isStream, {
    this.networkError = false,
    this.timeoutError = false,
  });
}
