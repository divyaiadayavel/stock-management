import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/payable_supplier.dart';
import 'report_shared_widgets.dart';

class PayableSupplierCard extends StatelessWidget {
  final PayableSupplier supplier;
  final VoidCallback? onTap;

  const PayableSupplierCard({super.key, required this.supplier, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateStr = supplier.dueDate.toString().split(' ')[0];
    final hasDue = supplier.amount > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),

      // Your app card background
      color: AppColors.card,

      // Keep the card clean and flat
      elevation: 0,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border, width: 1),
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),

          title: Text(supplier.supplierName, style: AppTextStyles.cardValue),

          subtitle: Text('Due Date: $dateStr', style: AppTextStyles.small),

          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${supplier.amount.toStringAsFixed(2)}',
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
