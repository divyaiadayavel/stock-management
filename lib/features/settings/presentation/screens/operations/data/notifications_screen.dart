import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/constants/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSettings();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Notifications",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      "Alert Settings",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildToggleItem(
                          icon: Icons.warning_amber_rounded,
                          iconColor: Colors.orange,
                          title: "Low Stock Alert",
                          subtitle: "Get notified for low stock",
                          dbKey: "notifLowStock",
                        ),
                        _buildDivider(),
                        _buildToggleItem(
                          icon: Icons.monetization_on_outlined,
                          iconColor: Colors.amber,
                          title: "Payment Due Reminder",
                          subtitle: "Remind for pending payments",
                          dbKey: "notifPayment",
                        ),
                        _buildDivider(),
                        _buildToggleItem(
                          icon: Icons.pie_chart_outline,
                          iconColor: Colors.green,
                          title: "Daily Sales Summary",
                          subtitle: "Get daily sales report",
                          dbKey: "notifDailySales",
                        ),
                        _buildDivider(),
                        _buildToggleItem(
                          icon: Icons.shopping_bag_outlined,
                          iconColor: Colors.purple,
                          title: "New Order Notification",
                          subtitle: "Get notified for new orders",
                          dbKey: "notifNewOrder",
                        ),
                        _buildDivider(),
                        _buildToggleItem(
                          icon: Icons.email_outlined,
                          iconColor: Colors.redAccent,
                          title: "Email Notifications",
                          subtitle: "Receive updates on email",
                          dbKey: "notifEmail",
                        ),
                        _buildDivider(),
                        _buildToggleItem(
                          icon: Icons.volume_up_outlined,
                          iconColor: Colors.teal,
                          title: "Sound",
                          subtitle: "Play sound for notifications",
                          dbKey: "notifSound",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDivider() =>
      Divider(height: 1, thickness: 1, indent: 60, color: Colors.grey.shade100);

  Widget _buildToggleItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String dbKey,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: notifs[dbKey]!,
            activeThumbColor: Colors.blue,
            onChanged: (v) => _updateToggle(dbKey, v),
          ),
        ],
      ),
    );
  }
}
