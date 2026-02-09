// lib/viewmodels/auth/auth_vm.dart
import '../../core/api/api_exception.dart';
import '../../core/auth/auth_storage.dart';
import '../../core/auth/farm_storage.dart';
import '../../data/models/auth/token_response.dart';
import '../../data/models/auth/user_read.dart';
import '../../data/models/auth/login_request.dart';
import '../../data/models/auth/register_request.dart';
import '../../data/repositories/auth_repository.dart';
import '../base_view_model.dart';

class AuthVM extends BaseViewModel {
  final AuthRepository _repo;
  final AuthStorage _authStorage;
  final FarmStorage _farmStorage;

  UserRead? meUser;

  AuthVM(
    this._repo,
    this._authStorage,
    this._farmStorage,
  );

  bool get isLoggedIn => meUser != null;

  Future<void> loadMe() async {
    setLoading(true);
    clearError();
    try {
      meUser = await _repo.me();
    } on ApiException catch (e) {
      setError(e);
      meUser = null;
    } finally {
      setLoading(false);
    }
  }

  Future<TokenResponse?> login({
    required String email,
    required String senha,
  }) async {
    setLoading(true);
    clearError();
    try {
      final token = await _repo.login(LoginRequest(email: email, senha: senha));
      await _authStorage.saveAccessToken(token.accessToken);
      // Opcional: carregar /auth/me já ao logar
      meUser = await _repo.me();
      return token;
    } on ApiException catch (e) {
      setError(e);
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<UserRead?> register({
    required String nome,
    required String email,
    required String senha,
  }) async {
    setLoading(true);
    clearError();
    try {
      final user = await _repo.register(
        RegisterRequest(nome: nome, email: email, senha: senha),
      );
      return user;
    } on ApiException catch (e) {
      setError(e);
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<void> logout() async {
    setLoading(true);
    clearError();
    try {
      meUser = null;
      await _authStorage.clear();
      await _farmStorage.clear(); // ao deslogar, zera fazenda selecionada
    } finally {
      setLoading(false);
    }
  }
  /// Usar ao iniciar o app. Se tiver token válido, tenta carregar /me.
  /// Se /me falhar com 401/ApiException, limpa sessão.
  Future<bool> bootstrap() async {
  clearError();

  final token = await _authStorage.getAccessToken();
  if (token == null || token.trim().isEmpty) {
    meUser = null;
    return false;
  }

  setLoading(true);
  try {
    meUser = await _repo.me();
    return true;
  } on ApiException catch (e) {
    setError(e);
    meUser = null;
    await _authStorage.clear();
    await _farmStorage.clear();
    return false;
  } finally {
    setLoading(false);
  }
}


}
