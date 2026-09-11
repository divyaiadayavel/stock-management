import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
Map<String, bool> settings = {
  "notifLowStock": true,
  "notifOutOfStock": true,
  "notifInStock": true,
  "notifProduct": true,
  "notifSupplier": true,
  "notifCustomer": true,
  "notifPrinter": true,
  "notifInventory": true,
  "notifPurchaseOrder": true,
};

  String lowStockAlertTime = "09:00";
  String outOfStockAlertTime = "09:00";

  String lowStockAlertInterval = "3";
  String outOfStockAlertInterval = "3";

  // Schedule sections start collapsed regardless of saved toggle state.
  // They only open when the user taps the card.
  bool lowStockExpanded = false;
  bool outOfStockExpanded = false;

  bool isLoading = true;
  bool isTestingNotification = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _registerTokenNow();
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
    try {
      final savedSettings =
          await ref.read(settingsRepositoryProvider).getSettings();

      for (String key in settings.keys) {
        final valStr = savedSettings[key];

        if (valStr != null) {
          settings[key] = valStr == "true";
        }
      }

      final savedLowStockTime = savedSettings["low_stock_alert_time"];
      final savedOutOfStockTime = savedSettings["out_of_stock_alert_time"];

      final savedLowStockInterval =
          savedSettings["low_stock_reminder_interval"];
      final savedOutOfStockInterval =
          savedSettings["out_of_stock_reminder_interval"];

      if (savedLowStockTime != null && savedLowStockTime.trim().isNotEmpty) {
        lowStockAlertTime = _normalizeStoredTime(savedLowStockTime);
      }

      if (savedOutOfStockTime != null &&
          savedOutOfStockTime.trim().isNotEmpty) {
        outOfStockAlertTime = _normalizeStoredTime(savedOutOfStockTime);
      }

      if (savedLowStockInterval != null &&
          savedLowStockInterval.trim().isNotEmpty) {
        lowStockAlertInterval = savedLowStockInterval.trim();
      }

      if (savedOutOfStockInterval != null &&
          savedOutOfStockInterval.trim().isNotEmpty) {
        outOfStockAlertInterval = savedOutOfStockInterval.trim();
      }
    } catch (_) {
      // Fallback to default local state.
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _normalizeStoredTime(String value) {
    try {
      final parts = value.trim().split(':');

      if (parts.length < 2) {
        return value;
      }

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        return value;
      }

      return '${hour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value;
    }
  }

  Future<void> _updateToggle(String key, bool value) async {
    setState(() {
      settings[key] = value;
    });

    try {
      await ref
          .read(settingsRepositoryProvider)
          .saveSetting(key, value.toString());
    } catch (_) {
      // Preference saved locally in UI state.
    }
  }

  Future<void> _pickLowStockTime() async {
    final initialTime = _parseTime(
      lowStockAlertTime,
      const TimeOfDay(hour: 9, minute: 0),
    );

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: false,
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) {
      return;
    }

    final value = _formatTimeForDatabase(pickedTime);

    setState(() {
      lowStockAlertTime = value;
    });

    try {
      await ref
          .read(settingsRepositoryProvider)
          .saveSetting("low_stock_alert_time", value);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to save low stock alert time"),
        ),
      );
    }
  }

  Future<void> _pickOutOfStockTime() async {
    final initialTime = _parseTime(
      outOfStockAlertTime,
      const TimeOfDay(hour: 9, minute: 0),
    );

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: false,
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) {
      return;
    }

    final value = _formatTimeForDatabase(pickedTime);

    setState(() {
      outOfStockAlertTime = value;
    });

    try {
      await ref
          .read(settingsRepositoryProvider)
          .saveSetting("out_of_stock_alert_time", value);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to save out of stock alert time"),
        ),
      );
    }
  }

  Future<void> _pickLowStockInterval() async {
    final selected = await _showIntervalPicker(lowStockAlertInterval);

    if (selected == null) {
      return;
    }

    setState(() {
      lowStockAlertInterval = selected;
    });

    try {
      await ref
          .read(settingsRepositoryProvider)
          .saveSetting("low_stock_reminder_interval", selected);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to save low stock repeat interval"),
        ),
      );
    }
  }

  Future<void> _pickOutOfStockInterval() async {
    final selected = await _showIntervalPicker(outOfStockAlertInterval);

    if (selected == null) {
      return;
    }

    setState(() {
      outOfStockAlertInterval = selected;
    });

    try {
      await ref
          .read(settingsRepositoryProvider)
          .saveSetting("out_of_stock_reminder_interval", selected);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to save out of stock repeat interval"),
        ),
      );
    }
  }

  Future<String?> _showIntervalPicker(String currentValue) async {
    const intervals = [
      "0",
      "1",
      "3",
      "5",
      "10",
      "15",
      "30",
      "60",
    ];

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Repeat notification",
                    style: AppTextStyles.cardValue.copyWith(
                      fontSize: 18,
                      fontFamily: AppTextStyles.fontDisplay,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Choose how often the alert should repeat.",
                    style: AppTextStyles.small.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  ...intervals.map(
                    (interval) {
                      final selected = interval == currentValue;

                      final label = interval == "0"
                          ? "Off (don't repeat)"
                          : interval == "1"
                              ? "Every 1 minute"
                              : "Every $interval minutes";

                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          Navigator.of(context).pop(interval);
                        },
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.surface2
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: 20,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  label,
                                  style: AppTextStyles.cardValue.copyWith(
                                    fontSize: 14,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: AppColors.textPrimaryDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  TimeOfDay _parseTime(String value, TimeOfDay fallback) {
    try {
      final parts = value.split(':');

      if (parts.length < 2) {
        return fallback;
      }

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        return fallback;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return fallback;
    }
  }

  String _formatTimeForDatabase(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeForDisplay(String value) {
    final time = _parseTime(value, const TimeOfDay(hour: 9, minute: 0));

    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  String _formatInterval(String value) {
    final minutes = int.tryParse(value) ?? 3;

    if (minutes <= 0) {
      return "Off";
    }

    if (minutes == 1) {
      return "Every 1 minute";
    }

    if (minutes >= 60 && minutes % 60 == 0) {
      final hours = minutes ~/ 60;

      if (hours == 1) {
        return "Every 1 hour";
      }

      return "Every $hours hours";
    }

    return "Every $minutes minutes";
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
      await NotificationService.registerFcmToken(userId);

      final response = await http.post(
        Uri.parse(ApiConfig.sendTestNotification),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Request processed'),
            backgroundColor:
                data['success'] == true ? AppColors.green : AppColors.red,
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

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text("Notifications", style: AppTextStyles.appBarTitle),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader("Stock & Inventory Alerts"),
                    _group([
                      _alertTile(
                        icon: Icons.warning_amber_rounded,
                        iconBg: AppColors.orange,
                        title: "Low Stock Alert",
                        subtitle: "Notify when stock is below minimum level",
                        dbKey: "notifLowStock",
                        alertTime: lowStockAlertTime,
                        interval: lowStockAlertInterval,
                        onTimeTap: _pickLowStockTime,
                        onIntervalTap: _pickLowStockInterval,
                        expanded: lowStockExpanded,
                        onCardTap: () {
                          setState(() {
                            lowStockExpanded = !lowStockExpanded;
                          });
                        },
                        onToggleChanged: (value) {
                          _updateToggle("notifLowStock", value);
                          if (!value) {
                            setState(() {
                              lowStockExpanded = false;
                            });
                          }
                        },
                      ),
                      _alertTile(
                        icon: Icons.error_outline,
                        iconBg: AppColors.red,
                        title: "Out of Stock Alert",
                        subtitle: "Notify when stock reaches zero",
                        dbKey: "notifOutOfStock",
                        alertTime: outOfStockAlertTime,
                        interval: outOfStockAlertInterval,
                        onTimeTap: _pickOutOfStockTime,
                        onIntervalTap: _pickOutOfStockInterval,
                        expanded: outOfStockExpanded,
                        onCardTap: () {
                          setState(() {
                            outOfStockExpanded = !outOfStockExpanded;
                          });
                        },
                        onToggleChanged: (value) {
                          _updateToggle("notifOutOfStock", value);
                          if (!value) {
                            setState(() {
                              outOfStockExpanded = false;
                            });
                          }
                        },
                      ),
                      _toggleTile(
                        icon: Icons.add_shopping_cart,
                        iconBg: AppColors.green,
                        title: "New Inventory Added",
                        subtitle: "Notify when new item is added",
                        dbKey: "notifInStock",
                      ),
                    ]),

                    _sectionHeader("Module Notifications"),
                    _group([
                      _toggleTile(
                        icon: Icons.inventory_2_outlined,
                        iconBg: AppColors.primary,
                        title: "Product Actions",
                        subtitle: "Alerts for product edits and deletions",
                        dbKey: "notifProduct",
                      ),
                      _toggleTile(
                        icon: Icons.local_shipping_outlined,
                        iconBg: Colors.amber,
                        title: "Supplier Alerts",
                        subtitle: "Updates for supplier actions and changes",
                        dbKey: "notifSupplier",
                      ),
                      _toggleTile(
                        icon: Icons.people_outline,
                        iconBg: AppColors.cyan,
                        title: "Customer Alerts",
                        subtitle: "Updates for customer additions",
                        dbKey: "notifCustomer",
                      ),
                      _toggleTile(
                        icon: Icons.print_outlined,
                        iconBg: AppColors.orange,
                        title: "Printer Hardware",
                        subtitle: "Connectivity and printing alerts",
                        dbKey: "notifPrinter",
                      ),
                      _toggleTile(
                        icon: Icons.assignment_outlined,
                        iconBg: AppColors.cyanDim,
                        title: "Purchase Orders",
                        subtitle: "PO creation and receiving alerts",
                        dbKey: "notifPurchaseOrder",
                      ),
                    ]),

                    _sectionHeader("Testing & Debugging"),
                    _group([
                      _actionTile(),
                    ]),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------
  // SHARED LAYOUT PIECES — mirrors SettingsScreen's card/group/divider style
  // ---------------------------------------------------------------------

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTextStyles.cardValue.copyWith(
          fontSize: 15,
          fontFamily: AppTextStyles.fontDisplay,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
        ),
      ),
    );
  }

  Widget _groupCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _group(List<Widget> tiles) {
    final children = <Widget>[];

    for (var i = 0; i < tiles.length; i++) {
      children.add(tiles[i]);

      if (i != tiles.length - 1) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.cardPadding,
            ),
            child: const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.border,
            ),
          ),
        );
      }
    }

    return _groupCard(child: Column(children: children));
  }

  Widget _iconCircle({required IconData icon, required Color bg}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: AppColors.textWhite, size: AppSizes.iconMd),
    );
  }

  // ---------------------------------------------------------------------
  // ALERT TILE — toggle row + tap-to-expand alert time / repeat section
  // ---------------------------------------------------------------------

  Widget _alertTile({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String dbKey,
    required String alertTime,
    required String interval,
    required VoidCallback onTimeTap,
    required VoidCallback onIntervalTap,
    required bool expanded,
    required VoidCallback onCardTap,
    required ValueChanged<bool> onToggleChanged,
  }) {
    final enabled = settings[dbKey] ?? false;
    final showSchedule = enabled && expanded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          // Tapping the card only expands/collapses once the alert is on.
          onTap: enabled ? onCardTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.cardPadding,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                _iconCircle(icon: icon, bg: iconBg),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.cardValue.copyWith(
                          fontSize: 15,
                          fontFamily: AppTextStyles.fontBody,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.small,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Switch(
                  value: enabled,
                  activeThumbColor: AppColors.textWhite,
                  activeTrackColor: AppColors.primary,
                  inactiveThumbColor: AppColors.textWhite,
                  inactiveTrackColor: AppColors.borderStrong,
                  onChanged: onToggleChanged,
                ),
                if (enabled)
                  AnimatedRotation(
                    turns: showSchedule ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: showSchedule
              ? _scheduleRow(
                  alertTime: alertTime,
                  interval: interval,
                  onTimeTap: onTimeTap,
                  onIntervalTap: onIntervalTap,
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }

  Widget _scheduleRow({
    required String alertTime,
    required String interval,
    required VoidCallback onTimeTap,
    required VoidCallback onIntervalTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.cardPadding,
        0,
        AppSpacing.cardPadding,
        AppSpacing.md,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: _miniControl(
                icon: Icons.schedule_outlined,
                label: "Alert time",
                value: _formatTimeForDisplay(alertTime),
                onTap: onTimeTap,
              ),
            ),
            Container(
              width: 1,
              height: 30,
              color: AppColors.borderStrong.withValues(alpha: 0.3),
            ),
            Expanded(
              child: _miniControl(
                icon: Icons.repeat_rounded,
                label: "Repeat",
                value: _formatInterval(interval),
                onTap: onIntervalTap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniControl({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.small.copyWith(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardValue.copyWith(
                      fontSize: 12.5,
                      fontFamily: AppTextStyles.fontDisplay,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // SIMPLE TOGGLE TILE
  // ---------------------------------------------------------------------

  Widget _toggleTile({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String dbKey,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPadding,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          _iconCircle(icon: icon, bg: iconBg),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.cardValue.copyWith(
                    fontSize: 15,
                    fontFamily: AppTextStyles.fontBody,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.small,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Switch(
            value: settings[dbKey] ?? false,
            activeThumbColor: AppColors.textWhite,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: AppColors.textWhite,
            inactiveTrackColor: AppColors.borderStrong,
            onChanged: (v) => _updateToggle(dbKey, v),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // TEST NOTIFICATION ACTION TILE
  // ---------------------------------------------------------------------

  Widget _actionTile() {
    return InkWell(
      onTap: isTestingNotification ? null : _sendTestNotification,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            _iconCircle(
              icon: Icons.notifications_active_outlined,
              bg: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Send Test Notification",
                    style: AppTextStyles.cardValue.copyWith(
                      fontSize: 15,
                      fontFamily: AppTextStyles.fontBody,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Test FCM push notification immediately",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small,
                  ),
                ],
              ),
            ),
            isTestingNotification
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
          ],
        ),
      ),
    );
  }
}