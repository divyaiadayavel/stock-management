import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/report_bill.dart';

class SaleBillCardWidget extends StatelessWidget {
  final ReportBill bill;
  final Function(String billId) onReprint;

  const SaleBillCardWidget({
    super.key,
    required this.bill,
    required this.onReprint,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = bill.date.toString().split(' ')[0];

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  bill.billId,
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                Text(dateStr, style: AppTextStyles.small),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Customer: ${bill.customerName}',
              style: AppTextStyles.subHeading,
            ),
            const Divider(color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Items Purchased',
                    style: AppTextStyles.cardTitle,
                  ),
                  Text(
                    '${bill.items} Qty',
                    style: AppTextStyles.cardValue,
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ₹${bill.totalAmount.toStringAsFixed(2)}',
                  style: AppTextStyles.cardValue.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextButton.icon(
                    onPressed: () => onReprint(bill.billId),
                    icon: const Icon(
                      Icons.print,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Reprint Bill',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}