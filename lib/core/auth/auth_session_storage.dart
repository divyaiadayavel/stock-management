import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthSessionStorage {
  AuthSessionStorage._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _sessionIdKey = 'catalystock_auth_session_id';

  static Future<void> saveSessionId(String sessionId) async {
    final value = sessionId.trim();

    if (value.isEmpty) {
      throw Exception('Cannot save an empty session ID');
    }

    await _storage.write(
      key: _sessionIdKey,
      value: value,
    );
  }

  static Future<String?> getSessionId() async {
    final value = await _storage.read(
      key: _sessionIdKey,
    );

    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return value.trim();
  }

  static Future<void> clearSessionId() async {
    await _storage.delete(
      key: _sessionIdKey,
    );
  }
}