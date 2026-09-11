import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../../../../core/auth/auth_session_storage.dart';

import 'auth_state.dart';

import '../../../../core/audit/audit_constants.dart';
import '../../../../core/audit/audit_logger.dart';
import '../../../../core/audit/audit_session.dart';
import '../../../../core/services/notification_service.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(),
);

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(AuthState());

  // ============================================================
  // LOGIN
  // ============================================================

  Future<bool> login(String email, String password) async {
    final normalizedEmail = email.trim();
    final normalizedPassword = password.trim();

    state = state.copyWith(
      isLoading: true,
      error: null,
      user: null,
    );

    try {
      final loginResult = await _loginStaffUser(
        normalizedEmail,
        normalizedPassword,
      );

      if (loginResult == null) {
        AuditLogger.log(
          module: AuditConstants.auth,
          event: AuditConstants.login,
          action: 'Login Failed',
          description: 'Invalid email or password.',
          status: AuditConstants.failed,
        );

        state = state.copyWith(
          isLoading: false,
          error: 'Invalid email or password',
        );

        return false;
      }

      final staffUser = loginResult.user;
      final sessionId = loginResult.sessionId;

      // ----------------------------------------------------------
      // SAVE BACKEND SESSION
      // ----------------------------------------------------------

      await AuthSessionStorage.saveSessionId(sessionId);

      // ----------------------------------------------------------
      // NORMALIZE USER ID
      // ----------------------------------------------------------

      final dynamic rawUserId = staffUser['id'];

      final int? userId = rawUserId is int
          ? rawUserId
          : int.tryParse(
              rawUserId?.toString() ?? '',
            );

      // ----------------------------------------------------------
      // START AUDIT SESSION
      // ----------------------------------------------------------

      AuditSession.start(
        userId: userId,
        userName: staffUser['name']?.toString() ?? '',
        userRole: staffUser['role']?.toString() ?? 'staff',
      );

      // ----------------------------------------------------------
      // REGISTER FCM TOKEN
      // ----------------------------------------------------------

      if (userId != null && userId > 0) {
        try {
          await NotificationService.registerFcmToken(userId);

          debugPrint(
            'FCM token registered successfully for user: $userId',
          );
        } catch (e) {
          debugPrint(
            'FCM token registration failed for user $userId: $e',
          );
        }
      }

      // ----------------------------------------------------------
      // AUDIT LOGIN
      // ----------------------------------------------------------

      AuditLogger.log(
        module: AuditConstants.auth,
        event: AuditConstants.login,
        action: 'User Login',
        description:
            '${staffUser['name']} logged into the application.',
        status: AuditConstants.success,
      );

      // ----------------------------------------------------------
      // UPDATE STATE
      // ----------------------------------------------------------

      state = state.copyWith(
        isLoading: false,
        user: staffUser,
      );

      return true;
    } catch (e) {
      AuditLogger.log(
        module: AuditConstants.auth,
        event: AuditConstants.error,
        action: 'Login Exception',
        description: e.toString(),
        status: AuditConstants.failed,
      );

      state = state.copyWith(
        isLoading: false,
        error: _cleanError(e),
      );

      return false;
    }
  }

  // ============================================================
  // BACKEND LOGIN
  // ============================================================

  Future<_LoginResult?> _loginStaffUser(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConfig.staffLogin),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final Object? decoded;

    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw Exception('Invalid staff login response');
    }

    if (decoded is! Map) {
      throw Exception('Invalid staff login response');
    }

    final json = Map<String, dynamic>.from(decoded);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        json['message'] ?? 'Staff login failed',
      );
    }

    if (!_readSuccess(json)) {
      return null;
    }

    final data = _readData(json);

    // ----------------------------------------------------------
    // READ SESSION ID
    // ----------------------------------------------------------

    final sessionId = data['session_id']?.toString().trim();

    if (sessionId == null || sessionId.isEmpty) {
      throw Exception(
        'Login response missing session ID',
      );
    }

    // ----------------------------------------------------------
    // READ USER
    // ----------------------------------------------------------

    final rawUser =
        data['user'] ??
        data['staff'] ??
        data;

    if (rawUser is! Map) {
      throw Exception(
        'Staff login response missing user data',
      );
    }

    final user = Map<String, dynamic>.from(rawUser)
      ..remove('password')
      ..remove('password_hash');

    final staffUser = <String, dynamic>{
      'id': user['id'],
      'name':
          user['name'] ??
          user['full_name'] ??
          'Staff User',
      'email':
          user['email'] ??
          email,
      'phone':
          user['phone'] ??
          user['phone_number'] ??
          '',
      'role':
          user['role'] ??
          'staff',
      'isActive':
          user['isActive'] ??
          user['is_active'] ??
          true,
      'source': 'staff',
    };

    return _LoginResult(
      sessionId: sessionId,
      user: staffUser,
    );
  }

  // ============================================================
  // RESTORE SESSION
  // ============================================================

  Future<bool> restoreSession() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final sessionId =
          await AuthSessionStorage.getSessionId();

      if (sessionId == null) {
        state = state.copyWith(
          isLoading: false,
          user: null,
        );

        return false;
      }

      final response = await http.post(
        Uri.parse(ApiConfig.validateSession),
        headers: {
          ...ApiConfig.jsonHeaders,
          'X-Session-ID': sessionId,
        },
      );

      final Object? decoded;

      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw Exception(
          'Invalid session validation response',
        );
      }

      if (decoded is! Map) {
        throw Exception(
          'Invalid session validation response',
        );
      }

      final json = Map<String, dynamic>.from(decoded);

      if (response.statusCode != 200 ||
          !_readSuccess(json)) {
        await AuthSessionStorage.clearSessionId();

        AuditSession.end();

        state = state.copyWith(
          isLoading: false,
          user: null,
        );

        return false;
      }

      final data = _readData(json);

      final rawUser =
          data['user'] ??
          data['staff'] ??
          data;

      if (rawUser is! Map) {
        throw Exception(
          'Session validation response missing user',
        );
      }

      final user = Map<String, dynamic>.from(rawUser)
        ..remove('password')
        ..remove('password_hash');

      final restoredUser = <String, dynamic>{
        'id': user['id'],
        'name':
            user['name'] ??
            user['full_name'] ??
            'Staff User',
        'email':
            user['email'] ?? '',
        'phone':
            user['phone'] ??
            user['phone_number'] ??
            '',
        'role':
            user['role'] ??
            'staff',
        'isActive':
            user['isActive'] ??
            user['is_active'] ??
            true,
        'source': 'staff',
      };

      final dynamic rawUserId =
          restoredUser['id'];

      final int? userId = rawUserId is int
          ? rawUserId
          : int.tryParse(
              rawUserId?.toString() ?? '',
            );

      // Restore audit session.
      AuditSession.start(
        userId: userId,
        userName:
            restoredUser['name']?.toString() ?? '',
        userRole:
            restoredUser['role']?.toString() ?? 'staff',
      );

      // Re-register FCM token after app restart.
      if (userId != null && userId > 0) {
        try {
          await NotificationService.registerFcmToken(
            userId,
          );
        } catch (e) {
          debugPrint(
            'FCM registration during session restore failed: $e',
          );
        }
      }

      state = state.copyWith(
        isLoading: false,
        user: restoredUser,
      );

      return true;
    } catch (e) {
      debugPrint(
        'Session restore failed: $e',
      );

      await AuthSessionStorage.clearSessionId();

      AuditSession.end();

      state = state.copyWith(
        isLoading: false,
        user: null,
        error: null,
      );

      return false;
    }
  }

  // ============================================================
  // MANUAL LOGOUT ONLY
  // ============================================================

  Future<void> logout() async {
    final sessionId =
        await AuthSessionStorage.getSessionId();

    try {
      if (sessionId != null) {
        await http.post(
          Uri.parse(ApiConfig.staffLogout),
          headers: {
            ...ApiConfig.jsonHeaders,
            'X-Session-ID': sessionId,
          },
        );
      }
    } catch (e) {
      debugPrint(
        'Backend logout failed: $e',
      );
    } finally {
      await AuthSessionStorage.clearSessionId();

      AuditLogger.log(
        module: AuditConstants.auth,
        event: AuditConstants.logout,
        action: 'User Logout',
        description:
            '${AuditSession.userName} logged out.',
        status: AuditConstants.success,
      );

      AuditSession.end();

      state = AuthState();
    }
  }

  // ============================================================
  // OTP
  // ============================================================

  Future<bool> sendOtp(String email) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.sendOtp),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({
          'email': email,
        }),
      );

      final data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      if (response.statusCode == 200 &&
          data['success'] == true) {
        state = state.copyWith(
          isLoading: false,
        );

        return true;
      }

      throw Exception(
        data['message'] ??
            'Failed to send OTP',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _cleanError(e),
      );

      return false;
    }
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<bool> verifyOtp(
    String email,
    String otp,
  ) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.verifyOtp),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      final data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      if (response.statusCode == 200 &&
          data['success'] == true) {
        state = state.copyWith(
          isLoading: false,
        );

        return true;
      }

      throw Exception(
        data['message'] ??
            'Invalid OTP',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _cleanError(e),
      );

      return false;
    }
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================

  Future<bool> resetPassword(
    String email,
    String newPassword,
  ) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.resetPassword),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({
          'email': email,
          'password': newPassword,
        }),
      );

      final data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      if (response.statusCode == 200 &&
          data['success'] == true) {
        state = state.copyWith(
          isLoading: false,
        );

        return true;
      }

      throw Exception(
        data['message'] ??
            'Password reset failed',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _cleanError(e),
      );

      return false;
    }
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<bool> register(
    String name,
    String email,
    String password,
  ) async {
    return false;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Map<String, dynamic> _readData(
    Map<String, dynamic> json,
  ) {
    final data = json['data'];

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return <String, dynamic>{};
  }

  bool _readSuccess(
    Map<String, dynamic> json,
  ) {
    final value =
        json['success'] ??
        json['status'];

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value == 1;
    }

    return value
            ?.toString()
            .toLowerCase() ==
        'true';
  }

  String _cleanError(Object error) {
    final message = error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        );

    if (message.contains('SocketException') ||
        message.contains('ClientException')) {
      return 'Unable to connect to staff login service';
    }

    return message;
  }
}

// ============================================================
// LOGIN RESULT
// ============================================================

class _LoginResult {
  const _LoginResult({
    required this.sessionId,
    required this.user,
  });

  final String sessionId;
  final Map<String, dynamic> user;
}