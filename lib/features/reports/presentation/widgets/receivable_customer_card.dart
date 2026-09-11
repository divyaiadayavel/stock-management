import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/receivable_customer.dart';
import 'report_shared_widgets.dart';

class ReceivableCustomerCard extends StatelessWidget {
  final ReceivableCustomer customer;
  final VoidCallback? onTap;

  const ReceivableCustomerCard({super.key, required this.customer, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateStr = customer.dueDate.toString().split(' ')[0];
    final hasDue = customer.amount > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),

      // App card color
      color: AppColors.card,

      // Clean card without default shadow
      elevation: 0,

      // App border
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border, width: 1),
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),

          title: Text(customer.customerName, style: AppTextStyles.cardValue),

          subtitle: Text('Due Date: $dateStr', style: AppTextStyles.small),

          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${customer.amount.toStringAsFixed(2)}',
                style: AppTextStyles.cardValue.copyWith(
                  color: hasDue ? AppColors.orange : AppColors.green,
                ),
              ),
              const SizedBox(height: 4),
              ReportBadge.auto(hasDue ? 'Due' : 'Settled'),
            ],
          ),
        ),
      ),
    );
  }
}
