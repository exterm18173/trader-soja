// lib/core/api/api_interceptors.dart
import 'dart:convert';

import 'package:dio/dio.dart';

import '../auth/auth_storage.dart';
import 'api_exception.dart';

class ApiInterceptors {
  static InterceptorsWrapper authAndErrors({
    required AuthStorage authStorage,
  }) {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await authStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        } else {
          options.headers.remove('Authorization');
        }
        options.headers['Accept'] = 'application/json';
        options.headers['Content-Type'] = 'application/json';
        handler.next(options);
      },
      onError: (DioException e, handler) {
        handler.reject(_mapDioError(e));
      },
    );
  }

  static DioException _mapDioError(DioException e) {
    // Se já veio ApiException por algum motivo, mantem.
    if (e.error is ApiException) return e;

    final status = e.response?.statusCode;
    final data = e.response?.data;

    String msg = 'Falha na requisição';
    dynamic details = data;

    if (data is Map<String, dynamic>) {
      // FastAPI costuma retornar {"detail": "..."} ou {"detail": [...]}
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) msg = detail;
      if (detail != null) details = detail;
    } else if (data is String) {
      // Pode vir html/texto em erro
      msg = data.length > 200 ? data.substring(0, 200) : data;
      details = data;
    } else if (data != null) {
      try {
        msg = jsonEncode(data);
      } catch (_) {}
    } else {
      // Sem response: timeout, conexão, etc
      msg = _networkMessage(e);
      details = e.message;
    }

    final apiEx = ApiException(statusCode: status, message: msg, details: details);

    return e.copyWith(error: apiEx);
  }

  static String _networkMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Tempo de conexão esgotado';
      case DioExceptionType.sendTimeout:
        return 'Tempo de envio esgotado';
      case DioExceptionType.receiveTimeout:
        return 'Tempo de resposta esgotado';
      case DioExceptionType.badCertificate:
        return 'Certificado inválido';
      case DioExceptionType.connectionError:
        return 'Sem conexão com o servidor';
      case DioExceptionType.cancel:
        return 'Requisição cancelada';
      case DioExceptionType.badResponse:
        return 'Erro no servidor';
      case DioExceptionType.unknown:
        return 'Erro inesperado de rede';
    }
  }
}
