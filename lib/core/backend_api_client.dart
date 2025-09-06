import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/constants.dart';
import '../core/metrics.dart';

class BackendApiClient {
  final http.Client _client;
  final Duration _timeout;

  BackendApiClient({
    http.Client? client,
    Duration? timeout,
  })  : _client = client ?? http.Client(),
        _timeout =
            timeout ?? const Duration(seconds: ApiConstants.timeoutSeconds);

  /// Check if device has internet connectivity
  Future<bool> isOnline() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      // In newer versions, checkConnectivity returns List<ConnectivityResult>
      return !connectivityResults.contains(ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  /// Generate itinerary with streaming response
  Future<void> generateItineraryStream({
    required String prompt,
    Map<String, dynamic>? previousItinerary,
    List<Map<String, String>>? chatHistory,
    required void Function(String token) onToken,
    required void Function(Map<String, dynamic> json) onTrip,
    required void Function(TokenMetrics metrics) onMetrics,
    required void Function(String error) onError,
  }) async {
    try {
      // Check connectivity first
      if (!await isOnline()) {
        onError(ApiConstants.networkErrorMessage);
        return;
      }

      final uri = Uri.parse(
          '${ApiConstants.backendBaseUrl}${ApiConstants.generateItineraryEndpoint}');

      final request = http.Request('POST', uri);
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      });

      request.body = jsonEncode({
        'prompt': prompt,
        'previousItinerary': previousItinerary,
        'chatHistory': chatHistory ?? [],
      });

      final streamedResponse = await _client.send(request);

      // Handle HTTP errors
      if (streamedResponse.statusCode >= 400) {
        final errorBody = await streamedResponse.stream.bytesToString();
        _handleHttpError(streamedResponse.statusCode, errorBody, onError);
        return;
      }

      // Process streaming response
      String buffer = '';
      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
        buffer += chunk;

        // Process complete lines
        final lines = buffer.split('\n');
        buffer = lines.removeLast(); // Keep incomplete line in buffer

        for (final line in lines) {
          if (line.trim().isEmpty) continue;

          try {
            // Handle Server-Sent Events format
            if (line.startsWith('data: ')) {
              final data = line.substring(6);
              if (data == '[DONE]') break;

              final json = jsonDecode(data) as Map<String, dynamic>;
              _processStreamData(json, onToken, onTrip, onMetrics);
            } else {
              // Handle raw JSON lines
              final json = jsonDecode(line) as Map<String, dynamic>;
              _processStreamData(json, onToken, onTrip, onMetrics);
            }
          } catch (e) {
            // If it's not JSON, treat as token
            onToken(line);
          }
        }
      }

      // Process any remaining buffer
      if (buffer.isNotEmpty) {
        try {
          final json = jsonDecode(buffer) as Map<String, dynamic>;
          _processStreamData(json, onToken, onTrip, onMetrics);
        } catch (e) {
          onToken(buffer);
        }
      }
    } on SocketException {
      onError(ApiConstants.networkErrorMessage);
    } on TimeoutException {
      onError(ApiConstants.timeoutErrorMessage);
    } on HttpException catch (e) {
      onError('HTTP Error: ${e.message}');
    } catch (e) {
      onError('Unexpected error: $e');
    }
  }

  /// Process individual stream data chunks
  void _processStreamData(
    Map<String, dynamic> json,
    void Function(String token) onToken,
    void Function(Map<String, dynamic> json) onTrip,
    void Function(TokenMetrics metrics) onMetrics,
  ) {
    if (json.containsKey('token')) {
      onToken(json['token'] as String);
    }

    if (json.containsKey('itinerary')) {
      onTrip(json['itinerary'] as Map<String, dynamic>);
    }

    if (json.containsKey('metrics')) {
      final metricsData = json['metrics'] as Map<String, dynamic>;
      onMetrics(TokenMetrics.fromJson(metricsData));
    }
  }

  /// Handle HTTP errors with appropriate messages
  void _handleHttpError(
      int statusCode, String body, void Function(String) onError) {
    switch (statusCode) {
      case ApiConstants.httpUnauthorized:
        onError(ApiConstants.unauthorizedErrorMessage);
        break;
      case ApiConstants.httpRateLimit:
        onError(ApiConstants.rateLimitErrorMessage);
        break;
      case ApiConstants.httpInternalServerError:
        onError(ApiConstants.serverErrorMessage);
        break;
      default:
        onError('HTTP $statusCode: $body');
    }
  }

  /// Check backend health
  Future<bool> healthCheck() async {
    try {
      if (!await isOnline()) return false;

      final uri = Uri.parse(
          '${ApiConstants.backendBaseUrl}${ApiConstants.healthCheckEndpoint}');
      final response = await _client.get(uri).timeout(_timeout);

      return response.statusCode == ApiConstants.httpOk;
    } catch (e) {
      return false;
    }
  }

  /// Generic POST request
  Future<Map<String, dynamic>> post(String endpoint,
      {Map<String, dynamic>? data}) async {
    try {
      if (!await isOnline()) {
        throw Exception(ApiConstants.networkErrorMessage);
      }

      final uri = Uri.parse('${ApiConstants.backendBaseUrl}$endpoint');
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
            },
            body: data != null ? jsonEncode(data) : null,
          )
          .timeout(_timeout);

      if (response.statusCode >= 400) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } on SocketException {
      throw Exception(ApiConstants.networkErrorMessage);
    } on TimeoutException {
      throw Exception(ApiConstants.timeoutErrorMessage);
    } catch (e) {
      rethrow;
    }
  }

  /// Generic GET request
  Future<dynamic> get(String endpoint) async {
    try {
      if (!await isOnline()) {
        throw Exception(ApiConstants.networkErrorMessage);
      }

      final uri = Uri.parse('${ApiConstants.backendBaseUrl}$endpoint');
      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode >= 400) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      return jsonDecode(response.body);
    } on SocketException {
      throw Exception(ApiConstants.networkErrorMessage);
    } on TimeoutException {
      throw Exception(ApiConstants.timeoutErrorMessage);
    } catch (e) {
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}
