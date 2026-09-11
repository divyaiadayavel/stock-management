import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/models/notification_event.dart';

class NotificationCard extends StatelessWidget {
  final AppNotification item;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = _getEventStyle(item.event);

    return Material(
      color: item.isRead ? AppColors.card : AppColors.surface2,
      borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            border: Border.all(
              color: item.isRead
                  ? AppColors.borderStrong.withValues(alpha: 0.4)
                  : style.color.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, color: style.color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTextStyles.cardValue.copyWith(
                              fontSize: 14.5,
                              fontWeight:
                                  item.isRead ? FontWeight.w600 : FontWeight.w700,
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: AppTextStyles.small.copyWith(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTimestamp(item.createdAt),
                          style: AppTextStyles.small.copyWith(
                            fontSize: 11,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                        if (item.event == NotificationEvent.outOfStock)
                          GestureDetector(
                            onTap: () {},
                            child: const Text(
                              "Quick Restock +",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _EventStyle _getEventStyle(NotificationEvent event) {
    switch (event) {
      case NotificationEvent.lowStock:
        return _EventStyle(Icons.warning_amber_rounded, AppColors.orange);
      case NotificationEvent.outOfStock:
        return _EventStyle(Icons.error_outline_rounded, AppColors.red);
      case NotificationEvent.inStock:
      case NotificationEvent.productAdded:
        return _EventStyle(Icons.add_shopping_cart_rounded, AppColors.green);
      case NotificationEvent.supplierAdded:
      case NotificationEvent.supplierUpdated:
        return _EventStyle(Icons.local_shipping_outlined, Colors.purple);
case NotificationEvent.customerAdded:
case NotificationEvent.customerUpdated:
case NotificationEvent.customerDeleted:
  return _EventStyle(
    Icons.people_outline_rounded,
    Colors.teal,
  );
      case NotificationEvent.printerConnected:
      case NotificationEvent.printSuccess:
        return _EventStyle(Icons.print_outlined, AppColors.cyan);
case NotificationEvent.purchaseOrderCreated:
  return _EventStyle(
    Icons.note_add_outlined,
    AppColors.primary,
  );

case NotificationEvent.purchaseOrderPlaced:
  return _EventStyle(
    Icons.local_shipping_outlined,
    AppColors.primary,
  );

case NotificationEvent.purchaseOrderPartiallyReceived:
  return _EventStyle(
    Icons.inventory_2_outlined,
    AppColors.orange,
  );

case NotificationEvent.purchaseOrderPending:
  return _EventStyle(
    Icons.hourglass_empty_rounded,
    AppColors.orange,
  );

case NotificationEvent.purchaseOrderReceived:
  return _EventStyle(
    Icons.assignment_turned_in_outlined,
    AppColors.green,
  );
      default:
        return _EventStyle(Icons.notifications_outlined, AppColors.primary);
    }
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${dt.day}/${dt.month}/${dt.year}";
  }
}

class _EventStyle {
  final IconData icon;
  final Color color;
  _EventStyle(this.icon, this.color);
}