// ignore_for_file: constant_identifier_names
import 'package:flutter/foundation.dart';
import 'constants.dart';

class Env {
  static const String functionsRegion = 'us-central1';
  static const String functionsName = 'agent';

  // Backend API base URL - configurable for different environments
  static String get functionsBaseUrl {
    if (kDebugMode) {
      // For local development - can be changed to point to your backend
      return ApiConstants.backendBaseUrl;
    }
    // Production URL (https) - update to your deployed project ID
    return 'https://YOUR_PROJECT_ID.cloudfunctions.net';
  }

  // API Keys - in production, these should come from secure storage
  static const String openAiApiKey =
      String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  static const String bingSearchKey =
      String.fromEnvironment('BING_SEARCH_KEY', defaultValue: '');
  static const String serpApiKey =
      String.fromEnvironment('SERPAPI_KEY', defaultValue: '');
}
