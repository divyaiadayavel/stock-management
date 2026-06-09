import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import '../../../../core/network/api_config.dart';
import '../../../../core/storage/db_helper.dart';
import 'auth_state.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(),
);

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(AuthState());

  Future<bool> login(String email, String password) async {
    final normalizedEmail = email.trim();
    final normalizedPassword = password.trim();

    state = state.copyWith(isLoading: true, error: null, user: null);

    try {
      final localUser = await DBHelper.login(
        normalizedEmail,
        normalizedPassword,
      );

      if (localUser != null) {
        state = state.copyWith(
          isLoading: false,
          user: {
            ...localUser,
            'source': 'local',
            'role': localUser['role'] ?? 'admin',
          },
        );
        return true;
      }

      final staffUser = await _loginStaffUser(
        normalizedEmail,
        normalizedPassword,
      );

      if (staffUser != null) {
        state = state.copyWith(isLoading: false, user: staffUser);
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        error: 'Invalid email or password',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _cleanError(e));
      return false;
    }
  }

  Future<Map<String, dynamic>?> _loginStaffUser(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConfig.staffLogin),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode({'email': email, 'password': password}),
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
      throw Exception(json['message'] ?? 'Staff login failed');
    }

    if (!_readSuccess(json)) {
      return null;
    }

    final data = _readData(json);
    final rawUser = data['user'] ?? data['staff'] ?? data;

    if (rawUser is! Map) {
      throw Exception('Staff login response missing user data');
    }

    final user = Map<String, dynamic>.from(rawUser)
      ..remove('password')
      ..remove('password_hash');

    return {
      'id': user['id'],
      'name': user['name'] ?? user['full_name'] ?? 'Staff User',
      'email': user['email'] ?? email,
      'phone': user['phone'] ?? user['phone_number'] ?? '',
      'role': user['role'] ?? 'staff',
      'isActive': user['isActive'] ?? user['is_active'] ?? true,
      'source': 'staff',
    };
  }

  Map<String, dynamic> _readData(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  bool _readSuccess(Map<String, dynamic> json) {
    final value = json['success'] ?? json['status'];
    if (value is bool) return value;
    if (value is num) return value == 1;
    return value?.toString().toLowerCase() == 'true';
  }

  String _cleanError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.contains('SocketException') ||
        message.contains('ClientException')) {
      return 'Unable to connect to staff login service';
    }
    return message;
  }

  Future<bool> sendOtp(String email) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final otp = (100000 + Random().nextInt(900000)).toString();

      const username = 'divyaidayavel2001@gmail.com';
      const password = 'dobt wzzc ugli xlum';

      final smtpServer = gmail(username, password);

      final message = Message()
        ..from = Address(username, 'Stock Management')
        ..recipients.add(email)
        ..subject = 'OTP Verification'
        ..text = 'Your OTP is: $otp';

      await send(message, smtpServer);

      state = state.copyWith(isLoading: false, otp: otp, otpEmail: email);

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  bool verifyOtp(String email, String otp) {
    return state.otp == otp && state.otpEmail == email;
  }

  Future<bool> resetPassword(String email, String newPassword) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final updated = await DBHelper.updatePassword(email, newPassword);

      if (updated) {
        state = state.copyWith(isLoading: false, otp: null, otpEmail: null);
        return true;
      }

      state = state.copyWith(isLoading: false, error: 'User not found');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await DBHelper.registerUser(name, email, password);

      if (success) {
        state = state.copyWith(isLoading: false);
        return true;
      }

      state = state.copyWith(isLoading: false, error: 'User already exists');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void logout() {
    state = AuthState();
  }
}
