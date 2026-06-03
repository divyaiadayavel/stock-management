import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import '../../../../core/storage/db_helper.dart';// ✅ SQLite added
import 'auth_state.dart';

/// ✅ PROVIDER
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController();
  },
);

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(AuthState());

  // =========================
  // 🔐 LOGIN USER (SQLite)
  // =========================
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    final user = await DBHelper.login(email, password);

    if (user != null) {
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: "Invalid email or password",
      );
      return false;
    }
  }

  // ==============================
  // 📩 SEND OTP (UNCHANGED)
  // ==============================
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

  // ==============================
  // 🔢 VERIFY OTP (UNCHANGED)
  // ==============================
  bool verifyOtp(String email, String otp) {
    return state.otp == otp && state.otpEmail == email;
  }

  // ==============================
  // 🔑 RESET PASSWORD (SQLite)
  // ==============================
  Future<bool> resetPassword(String email, String newPassword) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final updated = await DBHelper.updatePassword(email, newPassword);

      if (updated) {
        state = state.copyWith(isLoading: false, otp: null, otpEmail: null);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: "User not found");
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // =========================
  // 📝 REGISTER USER (SQLite)
  // =========================
  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await DBHelper.registerUser(name, email, password);

      if (success) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: "User already exists");
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // =========================
  // 🚪 LOGOUT USER (UNCHANGED)
  // =========================
  void logout() {
    state = AuthState();
  }
}
