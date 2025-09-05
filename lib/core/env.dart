// ignore_for_file: constant_identifier_names
import 'package:flutter/foundation.dart';

class Env {
  static const String functionsRegion = 'us-central1';
  static const String functionsName = 'agent';

  // When debugging, we default to local emulator. Change as needed.
  static String get functionsBaseUrl {
    if (kDebugMode) {
      // Replace YOUR_PROJECT_ID if you want to hardcode; otherwise set at runtime via Settings.
      return 'http://127.0.0.1:5001/YOUR_PROJECT_ID/us-central1';
    }
    // Production URL (https) - update to your deployed project ID
    return 'https://YOUR_PROJECT_ID.cloudfunctions.net';
  }
}
