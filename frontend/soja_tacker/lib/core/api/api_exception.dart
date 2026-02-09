// lib/core/api/api_exception.dart
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic details;

  ApiException({
    required this.message,
    this.statusCode,
    this.details,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
