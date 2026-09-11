import 'dart:math';

/// ===============================================================
/// Audit Session
/// Stock Management System
/// ===============================================================

class AuditSession {
  AuditSession._();

  static String _sessionId = '';
  static int? _userId;
  static String _userName = '';
  static String _userRole = '';
  static String _deviceId = '';
  static String _appVersion = '1.0.0';

  static DateTime? _loginTime;

  /// Generate a new session
  static void start({
    required int? userId,
    required String userName,
    required String userRole,
    String deviceId = '',
    String appVersion = '1.0.0',
  }) {
    _sessionId = _generateSessionId();

    _userId = userId;
    _userName = userName;
    _userRole = userRole;
    _deviceId = deviceId;
    _appVersion = appVersion;

    _loginTime = DateTime.now();
  }

  /// End current session
  static void end() {
    _sessionId = '';
    _userId = null;
    _userName = '';
    _userRole = '';
    _deviceId = '';
    _loginTime = null;
  }

  static String get sessionId => _sessionId;

  static int? get userId => _userId;

  static String get userName => _userName;

  static String get userRole => _userRole;

  static String get deviceId => _deviceId;

  static String get appVersion => _appVersion;

  static DateTime? get loginTime => _loginTime;

  static bool get isLoggedIn => _sessionId.isNotEmpty;

  static String _generateSessionId() {
    final random = Random();

    final millis = DateTime.now().millisecondsSinceEpoch;

    final value = random.nextInt(999999);

    return 'AUDIT_${millis}_$value';
  }
}