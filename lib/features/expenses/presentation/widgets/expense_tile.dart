import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stock_management/core/constants/app_colors.dart';
import 'package:stock_management/core/constants/app_sizes.dart';
import 'package:stock_management/core/constants/app_spacing.dart';
import 'package:stock_management/core/constants/app_text_styles.dart';
import 'package:stock_management/features/expenses/data/models/expense_model.dart';
import 'package:stock_management/features/expenses/presentation/utils/expense_icon_helper.dart';

class ExpenseTile extends StatelessWidget {
  final ExpenseModel expense;
  final String searchQuery;
  final VoidCallback onTap;

  const ExpenseTile({
    super.key,
    required this.expense,
    this.searchQuery = '',
    required this.onTap,
  });

  String _capitalizeFirstLetter(String text) {
    if (text.trim().isEmpty) return text;
    final clean = text.trim();
    return clean[0].toUpperCase() + clean.substring(1);
  }

  List<TextSpan> _buildHighlightedSpans({
    required String text,
    required String query,
    required TextStyle defaultStyle,
  }) {
    if (query.trim().isEmpty) {
      return [TextSpan(text: text, style: defaultStyle)];
    }

    final List<TextSpan> spans = [];
    final lowerText = text.toLowerCase();
    final cleanQuery = query.trim().toLowerCase();
    int start = 0;

    while (true) {
      final found = lowerText.indexOf(cleanQuery, start);
      if (found == -1) break;

      if (found > start) {
        spans.add(
          TextSpan(text: text.substring(start, found), style: defaultStyle),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(found, found + cleanQuery.length),
          style: defaultStyle.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      );

      start = found + cleanQuery.length;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: defaultStyle));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final iconInfo = getExpenseIconInfo(expense.name);
    final isCash = expense.paymentMethod == PaymentMethod.cash;
    final rawTitle = expense.name.isEmpty ? 'Untitled expense' : expense.name;
    final titleText = _capitalizeFirstLetter(rawTitle);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconInfo.background,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(
                iconInfo.icon,
                color: iconInfo.color,
                size: AppSizes.iconLg,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: _buildHighlightedSpans(
                        text: titleText,
                        query: searchQuery,
                        defaultStyle: AppTextStyles.cardValue.copyWith(
                          fontSize: 14,
                        ),
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isCash
                              ? AppColors.green.withValues(alpha: 0.12)
                              : AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSm,
                          ),
                        ),
                        child: Text(
                          expense.paymentMethod.label,
                          style: AppTextStyles.small.copyWith(
                            fontSize: 10,
                            color: isCash ? AppColors.green : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          DateFormat('hh:mm a').format(expense.date),
                          style: AppTextStyles.small,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${expense.amount.toStringAsFixed(2)}',
                  style: AppTextStyles.cardValue.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: AppSizes.iconMd,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
