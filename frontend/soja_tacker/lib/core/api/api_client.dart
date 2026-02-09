// lib/core/api/api_client.dart
import 'package:dio/dio.dart';

import '../auth/auth_storage.dart';
import 'api_config.dart';
import 'api_interceptors.dart';

class ApiClient {
  final AuthStorage authStorage;
  late final Dio dio;

  ApiClient({required this.authStorage}) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
      ),
    );

    dio.interceptors.add(
      ApiInterceptors.authAndErrors(authStorage: authStorage),
    );
  }
}
