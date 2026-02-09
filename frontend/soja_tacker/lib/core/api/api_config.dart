// lib/core/api/api_config.dart
import 'dart:core';

class ApiConfig {
  /// Exemplo:
  /// - Android emulator: http://10.0.2.2:8000
  /// - iOS simulator: http://localhost:8000
  /// - Web/desktop: http://localhost:8000
  static const String baseUrl = 'http://192.168.3.33:8000';

  static const Duration connectTimeout = Duration(seconds: 12);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
