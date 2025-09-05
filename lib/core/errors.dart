class AppException implements Exception {
  final String message;
  final int? code;
  AppException(this.message, {this.code});
  @override
  String toString() => 'AppException($code): $message';
}

class NetworkException extends AppException {
  NetworkException(super.message, {super.code});
}

class SchemaException extends AppException {
  SchemaException(super.message, {super.code});
}

class UnauthorizedException extends AppException {
  UnauthorizedException(super.message, {super.code});
}

class RateLimitException extends AppException {
  RateLimitException(super.message, {super.code});
}
