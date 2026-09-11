import 'package:flutter/material.dart';
import 'package:stock_management/core/constants/app_colors.dart';

class ExpenseIconInfo {
  final IconData icon;
  final Color color;
  final Color background;
  const ExpenseIconInfo(this.icon, this.color, this.background);
}

/// Picks a relevant icon + colour for an expense based on its typed
/// name — purely cosmetic, used for the Add Expense live-preview icon
/// and the list/detail tiles. Falls back to a generic receipt icon.
ExpenseIconInfo getExpenseIconInfo(String name) {
  final n = name.toLowerCase().trim();

  if (n.isEmpty) {
    return const ExpenseIconInfo(
        Icons.receipt_long_rounded, AppColors.primary, AppColors.surface2);
  }
  if (n.contains('print') || n.contains('paper') || n.contains('xerox')) {
    return const ExpenseIconInfo(
        Icons.print_rounded, Color(0xFF16A34A), Color(0xFFE6F7EC));
  }
  if (n.contains('electric') || n.contains('power') || n.contains('bill')) {
    return const ExpenseIconInfo(
        Icons.bolt_rounded, Color(0xFFF59E0B), Color(0xFFFFF3DC));
  }
  if (n.contains('travel') ||
      n.contains('auto') ||
      n.contains('fuel') ||
      n.contains('petrol') ||
      n.contains('delivery') ||
      n.contains('cab')) {
    return const ExpenseIconInfo(
        Icons.directions_car_filled_rounded, Color(0xFF7C3AED), Color(0xFFF0E9FE));
  }
  if (n.contains('stationery') ||
      n.contains('pen') ||
      n.contains('register') ||
      n.contains('file')) {
    return const ExpenseIconInfo(
        Icons.edit_note_rounded, Color(0xFFEA580C), Color(0xFFFFE9DC));
  }
  if (n.contains('food') ||
      n.contains('lunch') ||
      n.contains('snack') ||
      n.contains('tea')) {
    return const ExpenseIconInfo(
        Icons.restaurant_rounded, Color(0xFFDB2777), Color(0xFFFCE4F1));
  }
  if (n.contains('rent')) {
    return const ExpenseIconInfo(
        Icons.home_work_rounded, Color(0xFF0EA5E9), Color(0xFFE0F5FD));
  }
  if (n.contains('salary') || n.contains('wage') || n.contains('staff')) {
    return const ExpenseIconInfo(
        Icons.groups_rounded, Color(0xFF2563EB), Color(0xFFE3EBFD));
  }
  if (n.contains('internet') || n.contains('wifi') || n.contains('recharge')) {
    return const ExpenseIconInfo(
        Icons.wifi_rounded, Color(0xFF0891B2), Color(0xFFDDF6FA));
  }
  if (n.contains('maintenance') || n.contains('repair')) {
    return const ExpenseIconInfo(
        Icons.build_rounded, Color(0xFF57534E), Color(0xFFEFEEEC));
  }

  return const ExpenseIconInfo(
      Icons.receipt_long_rounded, AppColors.primary, AppColors.surface2);
}
