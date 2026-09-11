import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../providers/report_extras_provider.dart';
import '../widgets/report_shared_widgets.dart';

class ProfitabilityMarginsScreen extends ConsumerStatefulWidget {
  const ProfitabilityMarginsScreen({super.key});

  @override
  ConsumerState<ProfitabilityMarginsScreen> createState() =>
      _ProfitabilityMarginsScreenState();
}

class _ProfitabilityMarginsScreenState
    extends ConsumerState<ProfitabilityMarginsScreen> {
  String _period = 'this_month';

  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // ---------------------------------------------------------------------------
  // DATE RANGE LABEL
  // ---------------------------------------------------------------------------

  String get _periodLabel {
    switch (_period) {
      case 'today':
        return 'Today';

      case 'this_week':
        return 'This Week';

      case 'this_month':
        return 'This Month';

      case 'this_year':
        return 'This Year';

      case 'custom':
        if (_customStartDate != null && _customEndDate != null) {
          return '${_formatShortDate(_customStartDate!)} - '
              '${_formatShortDate(_customEndDate!)}';
        }
        return 'This Month';

      default:
        return 'This Month';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatShortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _buildRangeKey() {
    if (_period == 'custom' &&
        _customStartDate != null &&
        _customEndDate != null) {
      return 'custom:'
          '${_formatDate(_customStartDate!)}:'
          '${_formatDate(_customEndDate!)}';
    }

    return _period;
  }

  // ---------------------------------------------------------------------------
  // DATE RANGE PICKER
  // ---------------------------------------------------------------------------

  Future<void> _selectDateFilter() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: R.sp(context, 10)),
                Container(
                  width: R.sp(context, 36),
                  height: R.sp(context, 4),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                SizedBox(height: R.sp(context, 8)),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: R.sp(context, AppSpacing.md),
                    vertical: R.sp(context, 8),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Date Range',
                      style: AppTextStyles.cardValue.copyWith(
                        fontSize: R.fs(context, 15),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                _dateOption(
                  sheetContext,
                  value: 'today',
                  label: 'Today',
                  icon: Icons.today_rounded,
                ),

                _dateOption(
                  sheetContext,
                  value: 'this_week',
                  label: 'This Week',
                  icon: Icons.date_range_rounded,
                ),

                _dateOption(
                  sheetContext,
                  value: 'this_month',
                  label: 'This Month',
                  icon: Icons.calendar_month_rounded,
                ),

                _dateOption(
                  sheetContext,
                  value: 'this_year',
                  label: 'This Year',
                  icon: Icons.calendar_today_rounded,
                ),

                _dateOption(
                  sheetContext,
                  value: 'custom',
                  label: 'Custom Date Range',
                  icon: Icons.edit_calendar_rounded,
                ),

                SizedBox(height: R.sp(context, 8)),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    if (selected == 'custom') {
      await _selectCustomDateRange();
      return;
    }

    setState(() {
      _period = selected;
      _customStartDate = null;
      _customEndDate = null;
    });
  }

  Widget _dateOption(
    BuildContext sheetContext, {
    required String value,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _period == value;

    return InkWell(
      onTap: () => Navigator.pop(sheetContext, value),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: R.sp(context, AppSpacing.md),
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              width: R.sp(context, 36),
              height: R.sp(context, 36),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.10)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: R.icon(context, 18),
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            SizedBox(width: R.sp(context, AppSpacing.sm)),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.cardValue.copyWith(
                  fontSize: R.fs(context, 13),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: R.icon(context, 19),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();

    final initialStart = _customStartDate ?? DateTime(now.year, now.month, 1);

    final initialEnd = _customEndDate ?? now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: initialStart.isAfter(now) ? now : initialStart,
        end: initialEnd.isAfter(now) ? now : initialEnd,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimaryDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      _period = 'custom';
      _customStartDate = picked.start;
      _customEndDate = picked.end;
    });
  }

  // ---------------------------------------------------------------------------
  // SAFE VALUE HELPERS
  //
  // Backend expenses are returned as Map<String, dynamic>.
  // These helpers prevent the old:
  // NoSuchMethodError: getter 'name'
  // ---------------------------------------------------------------------------

  String _mapString(
    Map<String, dynamic> map,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = map[key];

      if (value != null) {
        final text = value.toString().trim();

        if (text.isNotEmpty && text.toLowerCase() != 'null') {
          return text;
        }
      }
    }

    return fallback;
  }

  double _mapDouble(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];

      if (value is num) {
        return value.toDouble();
      }

      if (value != null) {
        final parsed = double.tryParse(
          value.toString().replaceAll(',', '').trim(),
        );

        if (parsed != null) {
          return parsed;
        }
      }
    }

    return 0.0;
  }

  DateTime _mapDate(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];

      if (value == null) {
        continue;
      }

      final parsed = DateTime.tryParse(value.toString());

      if (parsed != null) {
        return parsed;
      }
    }

    return DateTime.now();
  }

  // ---------------------------------------------------------------------------
  // EXPENSE CARD
  // ---------------------------------------------------------------------------

  Widget _buildExpenseCard(BuildContext context, dynamic rawExpense) {
    if (rawExpense is! Map) {
      return const SizedBox.shrink();
    }

    final expense = Map<String, dynamic>.from(rawExpense);

    final name = _mapString(expense, [
      'name',
      'expense_name',
      'title',
      'description',
    ], fallback: 'Expense');

    final amount = _mapDouble(expense, [
      'amount',
      'expense_amount',
      'total_amount',
      'value',
    ]);

    final date = _mapDate(expense, [
      'date',
      'expense_date',
      'created_at',
      'createdAt',
    ]);

    final mode = _mapString(expense, [
      'mode',
      'payment_mode',
      'payment_method',
      'paymentMode',
    ], fallback: 'Cash');

    final category = _mapString(expense, [
      'category',
      'category_name',
      'categoryName',
    ]);

    final note = _mapString(expense, ['note', 'notes', 'remark', 'remarks']);

    final status = _mapString(expense, [
      'status',
      'payment_status',
      'paymentStatus',
    ], fallback: 'PAID');

    String subtitle = '${formatReportDate(date)} • $mode';

    if (category.isNotEmpty) {
      subtitle += '\nCategory: $category';
    }

    if (note.isNotEmpty) {
      subtitle += '\n$note';
    }

    return ReportListCard(
      leadingIcon: Icons.receipt_rounded,
      leadingColor: AppColors.red,
      title: name,
      subtitle: subtitle,
      trailingTop: formatRupee(amount),
      trailingBottom: '__badge__$status',
    );
  }

  // ---------------------------------------------------------------------------
  // DATE RANGE CARD
  // ---------------------------------------------------------------------------

  Widget _buildDateRangeCard(BuildContext context) {
    return InkWell(
      onTap: _selectDateFilter,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: R.sp(context, 12),
          vertical: R.sp(context, 11),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: R.sp(context, 34),
              height: R.sp(context, 34),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: AppColors.primary,
                size: R.icon(context, 18),
              ),
            ),
            SizedBox(width: R.sp(context, AppSpacing.sm)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date Range',
                    style: AppTextStyles.small.copyWith(
                      fontSize: R.fs(context, 10.5),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: R.sp(context, 1)),
                  Text(
                    _periodLabel,
                    style: AppTextStyles.cardValue.copyWith(
                      fontSize: R.fs(context, 13),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
              size: R.icon(context, 21),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // NET PROFIT CARD
  // ---------------------------------------------------------------------------

  Widget _buildNetProfitCard(BuildContext context, dynamic report) {
    final netProfit = report.estimatedNetProfit as double;
    final totalSellingPrice = report.grossTurnover as double;
    final totalPurchasePrice = report.costOfGoodsSold as double;
    final margin = report.netMarginRate as double;

    final profitColor = netProfit >= 0 ? AppColors.green : AppColors.red;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(R.sp(context, AppSpacing.cardPadding)),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(R.radius(context, 14)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NET PROFIT + TREND ICON
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NET PROFIT',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: R.fs(context, 11),
                        letterSpacing: 0.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: R.sp(context, 8)),
                    Text(
                      formatRupee(netProfit),
                      style: AppTextStyles.cardValue.copyWith(
                        color: profitColor,
                        fontSize: R.fs(context, 27),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: R.sp(context, 4)),
                    Text(
                      '${margin.toStringAsFixed(1)}%',
                      style: AppTextStyles.cardValue.copyWith(
                        color: profitColor,
                        fontSize: R.fs(context, 16),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Profit Margin',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: R.fs(context, 11),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: R.sp(context, 64),
                height: R.sp(context, 64),
                decoration: BoxDecoration(
                  color: profitColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  netProfit >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: profitColor,
                  size: R.icon(context, 31),
                ),
              ),
            ],
          ),

          SizedBox(height: R.sp(context, AppSpacing.md)),

          Divider(height: 1, color: AppColors.border),

          SizedBox(height: R.sp(context, AppSpacing.md)),

          // TOTAL SELLING + TOTAL PURCHASE
          Row(
            children: [
              Expanded(
                child: _buildAmountSummary(
                  context,
                  icon: Icons.shopping_cart_outlined,
                  iconColor: AppColors.green,
                  title: 'Total Selling Price',
                  amount: totalSellingPrice,
                ),
              ),

              Container(
                width: 1,
                height: R.sp(context, 48),
                color: AppColors.border,
              ),

              Expanded(
                child: _buildAmountSummary(
                  context,
                  icon: Icons.shopping_basket_outlined,
                  iconColor: AppColors.orange,
                  title: 'Total Purchase Price',
                  amount: totalPurchasePrice,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSummary(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required double amount,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: R.sp(context, 4)),
      child: Row(
        children: [
          Container(
            width: R.sp(context, 34),
            height: R.sp(context, 34),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: R.icon(context, 18)),
          ),
          SizedBox(width: R.sp(context, 7)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.small.copyWith(
                    fontSize: R.fs(context, 9.5),
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: R.sp(context, 2)),
                Text(
                  formatRupee(amount),
                  style: AppTextStyles.cardValue.copyWith(
                    fontSize: R.fs(context, 13),
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PROFIT BREAKDOWN
  // ---------------------------------------------------------------------------

  Widget _buildProfitBreakdown(BuildContext context, dynamic report) {
    final totalSellingPrice = report.grossTurnover as double;
    final totalPurchasePrice = report.costOfGoodsSold as double;

    final grossProfit = totalSellingPrice - totalPurchasePrice;

    final totalExpenses = report.activeLedgerExpense as double;

    final netProfit = report.estimatedNetProfit as double;
    final margin = report.netMarginRate as double;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(R.sp(context, AppSpacing.cardPadding)),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(R.radius(context, 14)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROFIT BREAKDOWN',
            style: AppTextStyles.small.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              fontSize: R.fs(context, 11),
            ),
          ),

          SizedBox(height: R.sp(context, AppSpacing.sm)),

          Divider(height: 1, color: AppColors.border),

          SizedBox(height: R.sp(context, AppSpacing.xs)),

          ReportKeyValueRow(
            label: 'Total Selling Price',
            value: formatRupee(totalSellingPrice),
          ),

          ReportKeyValueRow(
            label: 'Total Purchase Price',
            value: '- ${formatRupee(totalPurchasePrice)}',
            valueColor: AppColors.red,
          ),

          Padding(
            padding: EdgeInsets.symmetric(vertical: R.sp(context, 4)),
            child: Divider(color: AppColors.border),
          ),

          ReportKeyValueRow(
            label: 'Gross Profit',
            value: formatRupee(grossProfit),
            valueColor: grossProfit >= 0 ? AppColors.green : AppColors.red,
            bold: true,
          ),

          ReportKeyValueRow(
            label: 'Total Expenses',
            value: '- ${formatRupee(totalExpenses)}',
            valueColor: AppColors.red,
          ),

          Padding(
            padding: EdgeInsets.symmetric(vertical: R.sp(context, 4)),
            child: Divider(color: AppColors.border),
          ),

          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: R.sp(context, 10),
              vertical: R.sp(context, 10),
            ),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.green.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Net Profit',
                      style: AppTextStyles.cardValue.copyWith(
                        color: netProfit >= 0 ? AppColors.green : AppColors.red,
                        fontSize: R.fs(context, 14),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      formatRupee(netProfit),
                      style: AppTextStyles.cardValue.copyWith(
                        color: netProfit >= 0 ? AppColors.green : AppColors.red,
                        fontSize: R.fs(context, 15),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: R.sp(context, 4)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profit Margin',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: R.fs(context, 11),
                      ),
                    ),
                    Text(
                      '${margin.toStringAsFixed(1)}%',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: R.fs(context, 11),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EXPENSES
  // ---------------------------------------------------------------------------

  Widget _buildExpensesSection(BuildContext context, dynamic report) {
    final rawExpenses = report.activeExpenses;

    final expenses = rawExpenses is List ? rawExpenses : <dynamic>[];

    final totalExpenses = report.activeLedgerExpense as double;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: R.sp(context, 4),
            vertical: R.sp(context, 4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'EXPENSES',
                  style: AppTextStyles.cardValue.copyWith(
                    fontSize: R.fs(context, 13),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Total Expenses',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: R.fs(context, 10.5),
                ),
              ),
              SizedBox(width: R.sp(context, 7)),
              Text(
                formatRupee(totalExpenses),
                style: AppTextStyles.cardValue.copyWith(
                  fontSize: R.fs(context, 13),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: R.sp(context, 4)),

        if (expenses.isEmpty)
          ReportSectionCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: R.sp(context, 18)),
                child: Text(
                  'No expenses found for this date range.',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: R.fs(context, 11),
                  ),
                ),
              ),
            ),
          )
        else
          ...expenses.map((expense) => _buildExpenseCard(context, expense)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final rangeKey = _buildRangeKey();

    final reportAsync = ref.watch(profitabilityReportProvider(rangeKey));

    return ReportScaffold(
      // IMPORTANT:
      // No rangeLabel here.
      // This completely removes the "All Time (Live)" / "This Month"
      // button from the app bar.
      title: 'Profitability & Expenses',
      rangeLabel: null,
      onRefresh: () async {
        ref.invalidate(profitabilityReportProvider(rangeKey));
      },
      child: ReportAsyncView(
        value: reportAsync,
        isEmpty: (_) => false,
        emptyMessage: 'No profitability data found for this date range.',
        builder: (context, report) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------------------
              // DATE RANGE UNDER APP BAR
              // ----------------------------------------------------------------
              _buildDateRangeCard(context),

              SizedBox(height: R.sp(context, AppSpacing.sm)),

              // ----------------------------------------------------------------
              // NET PROFIT CARD
              // ----------------------------------------------------------------
              _buildNetProfitCard(context, report),

              SizedBox(height: R.sp(context, AppSpacing.sm)),

              // ----------------------------------------------------------------
              // PROFIT BREAKDOWN
              // ----------------------------------------------------------------
              _buildProfitBreakdown(context, report),

              SizedBox(height: R.sp(context, AppSpacing.sm)),

              // ----------------------------------------------------------------
              // EXPENSES
              // ----------------------------------------------------------------
              _buildExpensesSection(context, report),
            ],
          );
        },
      ),
    );
  }
}
