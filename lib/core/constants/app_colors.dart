import 'package:flutter/material.dart';

class AppColors {
  // ── Core Backgrounds ──
  static const background = Colors.white;
  static const card = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFEEF0F4);

  // ── Borders ──
  static const border = Color(0xFFDDE1EA);
  static const borderStrong = Color(0xFFC4CBDA);

  // ── Text ──
  static const textPrimaryLight = Colors.black;
  static const textPrimaryDark = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7A99);

  // ✅ Added this back so your LoginScreen and other files stop throwing errors!
  static const textWhite = Color(0xFFFFFFFF);

  // ── Brand Colors ──
  static const primary = Color.fromARGB(255, 29, 77, 207);
  static const primaryHover = Color(0xFF2451B8);
  static const cyan = Color(0xFF00C8F8);
  static const cyanDim = Color(0xFF00A8D4);

  // ── Semantic (Alerts/Badges) ──
  static const green = Color(0xFF22C55E);
  static const orange = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);

  // ── Brand Gradient ──
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B3A8C), Color(0xFF00C8F8)],
  );
}
