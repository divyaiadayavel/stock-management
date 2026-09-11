import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/models/notification_event.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_card.dart';
import '../../../inventory/presentation/screens/receive_order_screen.dart';
import '../../domain/models/notification_module.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  final int userId;
  const NotificationCenterScreen({super.key, this.userId = 1});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  int _selectedFilterIndex = 0; // 0: All Alerts, 1: Low Stock, 2: Out of Stock, 3: Activity & Stock

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationProvider.notifier).fetchNotifications(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        titleSpacing: 0,
        title: Text(
          "Notifications Center",
          style: AppTextStyles.cardValue.copyWith(
            fontSize: 20,
            fontFamily: AppTextStyles.fontDisplay,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              ref
                  .read(notificationProvider.notifier)
                  .markAllAsRead(widget.userId);
            },
            icon: const Icon(Icons.done_all_rounded,
                size: 18, color: AppColors.primary),
            label: const Text(
              "Mark all read",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: notificationState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text("Error: $err")),
        data: (notifications) {
          final unreadCount = notifications.where((n) => !n.isRead).length;
          final filtered = _filterNotifications(notifications);

          return RefreshIndicator(
            onRefresh: () => ref
                .read(notificationProvider.notifier)
                .fetchNotifications(widget.userId),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _summaryBannerCard(unreadCount, notifications.length),
                  const SizedBox(height: AppSpacing.md),
                  _filterChips(),
                  const SizedBox(height: AppSpacing.md),
                  filtered.isEmpty
                      ? _emptyStateView()
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return NotificationCard(
                              item: item,
onTap: () async {
  await ref
      .read(notificationProvider.notifier)
      .markAsRead(item.id);

  if (!mounted) return;

  if (item.module == NotificationModule.purchaseOrder &&
      item.purchaseId != null) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReceiveOrderScreen(
          poId: item.purchaseId,
        ),
      ),
    );
  }
},
                            );
                          },
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── FILTER NOTIFICATIONS ─────────────────────────────────
List<AppNotification> _filterNotifications(List<AppNotification> list) {
  if (_selectedFilterIndex == 1) {
    return list.where((n) => n.event == NotificationEvent.lowStock).toList();
  } else if (_selectedFilterIndex == 2) {
    return list.where((n) => n.event == NotificationEvent.outOfStock).toList();
} else if (_selectedFilterIndex == 3) {
  return list.where((n) =>
      // Product activity
      n.event == NotificationEvent.inStock ||
      n.event == NotificationEvent.productAdded ||
      n.event == NotificationEvent.productUpdated ||
      n.event == NotificationEvent.productDeleted ||

      // Customer activity
      n.event == NotificationEvent.customerAdded ||
      n.event == NotificationEvent.customerUpdated ||
      n.event == NotificationEvent.customerDeleted ||

      // Supplier activity
      n.event == NotificationEvent.supplierAdded ||
      n.event == NotificationEvent.supplierUpdated ||
      n.event == NotificationEvent.supplierDeleted
  ).toList();
}
  return list;
}

  Widget _summaryBannerCard(int unread, int total) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unread > 0 ? "$unread Unread Notifications" : "All Caught Up!",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "You have $total total activity updates logged.",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(0, "All Alerts"),
          const SizedBox(width: AppSpacing.xs),
          _chip(1, "Low Stock ⚠️"),
          const SizedBox(width: AppSpacing.xs),
          _chip(2, "Out of Stock 🚨"),
          const SizedBox(width: AppSpacing.xs),
          _chip(3, "Activity & Stock 📦"),
        ],
      ),
    );
  }

  Widget _chip(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      backgroundColor: AppColors.card,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 13,
      ),
      onSelected: (_) {
        setState(() {
          _selectedFilterIndex = index;
        });
      },
    );
  }

  Widget _emptyStateView() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 56,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "No Notifications Found",
            style: AppTextStyles.cardValue.copyWith(
              fontSize: 16,
              color: AppColors.textPrimaryDark,
            ),
          ),
        ],
      ),
    );
  }
}