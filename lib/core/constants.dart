// ignore_for_file: constant_identifier_names

class ApiConstants {
  // Backend API Configuration
  static const String backendBaseUrl =
      'http://10.0.2.2:8080'; // Android emulator localhost mapping

  // API Endpoints
  static const String generateItineraryEndpoint = '/generate-itinerary';
  static const String healthCheckEndpoint = '/health';

  // Request Configuration
  static const int timeoutSeconds = 30;
  static const int maxRetries = 3;

  // Error Messages
  static const String networkErrorMessage =
      'Network connection failed. Please check your internet connection.';
  static const String serverErrorMessage =
      'Server error occurred. Please try again later.';
  static const String unauthorizedErrorMessage =
      'Unauthorized access. Please check your API key.';
  static const String rateLimitErrorMessage =
      'Rate limit exceeded. Please wait a moment and try again.';
  static const String timeoutErrorMessage =
      'Request timed out. Please try again.';

  // HTTP Status Codes
  static const int httpOk = 200;
  static const int httpUnauthorized = 401;
  static const int httpForbidden = 403;
  static const int httpNotFound = 404;
  static const int httpRateLimit = 429;
  static const int httpInternalServerError = 500;
}
