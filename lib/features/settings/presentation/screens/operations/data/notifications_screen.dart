import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_sizes.dart';
import '../../../../../../core/constants/app_spacing.dart';
import '../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../core/services/notification_service.dart';
import '../../../../../auth/presentation/controllers/auth_controller.dart';
import '../../../providers/settings_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  Map<String, bool> notifs = {
    "notifLowStock": true,
    "notifPayment": true,
    "notifDailySales": true,
    "notifNewOrder": true,
    "notifEmail": false,
    "notifSound": true,
  };
  bool isLoading = true;
  bool isTestingNotification = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _registerTokenNow(); // Auto-registers FCM token on screen open
  }

  Future<void> _registerTokenNow() async {
    final authState = ref.read(authControllerProvider);
    int userId = 1;
    if (authState.user != null) {
      final rawId = authState.user!['id'] ?? authState.user!['user_id'];
      if (rawId != null) {
        userId = int.tryParse(rawId.toString()) ?? 1;
      }
    }
    await NotificationService.registerFcmToken(userId);
  }

  Future<void> _loadSettings() async {
    final settings = await ref.read(settingsRepositoryProvider).getSettings();

    for (String key in notifs.keys) {
      String? valStr = settings[key];
      if (valStr != null) {
        notifs[key] = valStr == "true";
      }
    }
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateToggle(String key, bool value) async {
    await ref
        .read(settingsRepositoryProvider)
        .saveSetting(key, value.toString());
    setState(() {
      notifs[key] = value;
    });
  }

  Future<void> _sendTestNotification() async {
    final authState = ref.read(authControllerProvider);

    int userId = 1;
    if (authState.user != null) {
      final rawId = authState.user!['id'] ?? authState.user!['user_id'];
      if (rawId != null) {
        userId = int.tryParse(rawId.toString()) ?? 1;
      }
    }

    setState(() {
      isTestingNotification = true;
    });

    try {
      // Register token first before sending test request
      await NotificationService.registerFcmToken(userId);

      final response = await http.post(
        Uri.parse('https://catalystack.com/catalystock/public_html/api/notifications/dev/send_test_notification.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Request processed'),
            backgroundColor: data['success'] == true ? AppColors.green : AppColors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error triggering notification: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isTestingNotification = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        titleSpacing: 0,
        title: Text(
          "Notifications",
          style: AppTextStyles.cardValue.copyWith(
            fontSize: 22,
            fontFamily: AppTextStyles.fontDisplay,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader("Alert Settings"),
                  _toggleCard(
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppColors.orange,
                    title: "Low Stock Alert",
                    subtitle: "Get notified for low stock",
                    dbKey: "notifLowStock",
                  ),
                  _toggleCard(
                    icon: Icons.monetization_on_outlined,
                    iconColor: Colors.amber,
                    title: "Payment Due Reminder",
                    subtitle: "Remind for pending payments",
                    dbKey: "notifPayment",
                  ),
                  _toggleCard(
                    icon: Icons.pie_chart_outline,
                    iconColor: AppColors.green,
                    title: "Daily Sales Summary",
                    subtitle: "Get daily sales report",
                    dbKey: "notifDailySales",
                  ),
                  _toggleCard(
                    icon: Icons.shopping_bag_outlined,
                    iconColor: AppColors.primary,
                    title: "New Order Notification",
                    subtitle: "Get notified for new orders",
                    dbKey: "notifNewOrder",
                  ),
                  _toggleCard(
                    icon: Icons.email_outlined,
                    iconColor: AppColors.red,
                    title: "Email Notifications",
                    subtitle: "Receive updates on email",
                    dbKey: "notifEmail",
                  ),
                  _toggleCard(
                    icon: Icons.volume_up_outlined,
                    iconColor: AppColors.cyan,
                    title: "Sound",
                    subtitle: "Play sound for notifications",
                    dbKey: "notifSound",
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _sectionHeader("Testing & Debugging"),
                  _actionCard(
                    icon: Icons.notifications_active_outlined,
                    iconColor: AppColors.primary,
                    title: "Send Test Notification",
                    subtitle: "Tap to test FCM push notification immediately",
                    onTap: isTestingNotification ? null : _sendTestNotification,
                    isLoading: isTestingNotification,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm, top: AppSpacing.sm),
      child: Text(
        title,
        style: AppTextStyles.cardValue.copyWith(
          fontSize: 17,
          fontFamily: AppTextStyles.fontDisplay,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
        ),
      ),
    );
  }

  Widget _toggleCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String dbKey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.surface2,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: AppSizes.iconMd),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.cardValue.copyWith(
                      fontSize: 16,
                      fontFamily: AppTextStyles.fontDisplay,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTextStyles.small.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Switch(
              value: notifs[dbKey] ?? false,
              activeThumbColor: AppColors.textWhite,
              activeTrackColor: AppColors.primary,
              inactiveThumbColor: AppColors.textWhite,
              inactiveTrackColor: AppColors.borderStrong,
              onChanged: (v) => _updateToggle(dbKey, v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.cardPadding,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.surface2,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: AppSizes.iconMd),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.cardValue.copyWith(
                          fontSize: 16,
                          fontFamily: AppTextStyles.fontDisplay,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: AppTextStyles.small.copyWith(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}