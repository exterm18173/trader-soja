// lib/data/models/auth/login_request.dart
class LoginRequest {
  final String email;
  final String senha;

  const LoginRequest({
    required this.email,
    required this.senha,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'senha': senha,
      };
}
