import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // ── Font Families ──
  static const String fontDisplay = 'Space Grotesk';
  static const String fontBody = 'Inter';
  static const String fontMono = 'JetBrains Mono';

  // ── Text on Dark Background (App Background) ──

  // 🔹 AppBar Title
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: fontDisplay,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimaryLight, // White for dark background
    letterSpacing: -0.2,
  );

  // 🔹 Main Heading (Dashboard Welcome)
  static const TextStyle heading = TextStyle(
    fontFamily: fontDisplay,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimaryLight, // White for dark background
    letterSpacing: -0.4,
  );

  // 🔹 Section Title (Quick Actions, Sales Overview)
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontDisplay,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimaryLight, // White for dark background
    letterSpacing: -0.2,
  );

  // 🔹 Sub Heading (Dashboard subtitle)
  static const TextStyle subHeading = TextStyle(
    fontFamily: fontBody,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    // Using a 70% opacity white so it looks muted against the dark blue
    color: Colors.black,
    height: 1.6,
  );

  // ── Text inside White Cards ──

  // 🔹 Card Title (Total Products, Sales labels)
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontBody,
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary, // Muted grey/blue looks great on white
  );

  // 🔹 Card Value (Numbers, Amounts, Data)
  static const TextStyle cardValue = TextStyle(
    fontFamily: fontMono,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimaryDark, // Dark text for the white cards
    letterSpacing: -0.5,
  );

  // 🔹 Small Text / Eyebrow (Meta, status, tiny labels)
  static const TextStyle small = TextStyle(
    fontFamily: fontBody,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary, // Muted grey/blue
    letterSpacing: 0.5,
  );

  // ── Buttons ──

  // 🔹 Button Text (Quick Actions)
  static const TextStyle button = TextStyle(
    fontFamily: fontBody,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color:
        AppColors.textPrimaryLight, // White text for colored/gradient buttons
    letterSpacing: 0.2,
  );
}
