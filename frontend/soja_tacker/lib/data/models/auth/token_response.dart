// lib/data/models/auth/token_response.dart
class TokenResponse {
  final String accessToken;
  final String tokenType;

  const TokenResponse({
    required this.accessToken,
    this.tokenType = 'bearer',
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: (json['access_token'] ?? '').toString(),
      tokenType: (json['token_type'] ?? 'bearer').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'token_type': tokenType,
      };
}
