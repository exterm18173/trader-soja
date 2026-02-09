import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _kAccessToken = 'access_token';

  Future<void> saveAccessToken(String token) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kAccessToken, token);
  }

  Future<String?> getAccessToken() async {
    final sp = await SharedPreferences.getInstance();
    final t = sp.getString(_kAccessToken);
    if (t == null || t.trim().isEmpty) return null;
    return t;
  }

  Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kAccessToken);
  }

  /// true = existe token e (aparentemente) ainda não expirou.
  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    if (token == null) return false;
    return !_isJwtExpired(token);
  }

  bool _isJwtExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payloadJson = _decodeBase64Url(parts[1]);
      final payload = json.decode(payloadJson) as Map<String, dynamic>;

      final exp = payload['exp'];
      if (exp is! num) return true;

      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      // margem de 30s
      return nowSec >= (exp.toInt() - 30);
    } catch (_) {
      return true;
    }
  }

  String _decodeBase64Url(String str) {
    var output = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw const FormatException('Invalid base64url');
    }
    return utf8.decode(base64.decode(output));
  }
}
