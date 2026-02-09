// lib/data/repositories/auth_repository.dart
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../models/auth/login_request.dart';
import '../models/auth/register_request.dart';
import '../models/auth/token_response.dart';
import '../models/auth/user_read.dart';

class AuthRepository {
  final ApiClient api;

  AuthRepository(this.api);

  Future<UserRead> register(RegisterRequest payload) async {
    try {
      final res = await api.dio.post(
        '/auth/register',
        data: payload.toJson(),
      );
      return UserRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao cadastrar');
    }
  }

  Future<TokenResponse> login(LoginRequest payload) async {
    try {
      final res = await api.dio.post(
        '/auth/login',
        data: payload.toJson(),
      );
      return TokenResponse.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao entrar');
    }
  }

  Future<UserRead> me() async {
    try {
      final res = await api.dio.get('/auth/me');
      return UserRead.fromJson(res.data as Map<String, dynamic>);
    } on Exception catch (e) {
      throw _asApiException(e, fallback: 'Erro ao carregar usuário');
    }
  }

  ApiException _asApiException(Object e, {required String fallback}) {
    // ApiInterceptors já converte DioException.error => ApiException.
    if (e is ApiException) return e;

    final msg = e.toString();
    return ApiException(message: fallback, details: msg);
  }
}
