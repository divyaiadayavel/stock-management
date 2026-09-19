import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';

import '../../domain/entities/report_extras.dart';
import '../providers/reports_provider.dart';
import '../providers/report_extras_provider.dart';

import 'sales_reports_screen.dart';
import 'product_performance_screen.dart';
import 'purchases_suppliers_screen.dart';
import 'inventory_stock_report_screen.dart';
import 'services_reports_screen.dart';
import 'provider_reports_screen.dart';
import 'profitability_margins_screen.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  // Single shared date filter for this whole screen: default is "This Month",
  // and it drives both the metrics grid (Total Sales, Purchases, Service
  // Value, Expenses, Receivables, Payables) and the Sales Analysis chart.
  // 'today' | 'this_week' | 'this_month' | 'this_year' | 'custom'
  String _periodKey = 'this_month';
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportsProvider.notifier).fetchReportData();
    });
  }

  String _fmt2(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// The literal date span for the currently selected filter. Used as the
  /// default when opening the custom-range picker.
  DateTimeRange _rangeForPeriod(String key) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (key) {
      case 'today':
        return DateTimeRange(start: today, end: now);
      case 'this_week':
        final monday = today.subtract(Duration(days: today.weekday - 1));
        return DateTimeRange(start: monday, end: now);
      case 'this_year':
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
      case 'this_month':
      default:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
    }
  }

  /// Applies a newly chosen period/custom-range in one setState.
  void _applyPeriod(String key, {DateTimeRange? custom}) {
    setState(() {
      _periodKey = key;
      _customRange = custom;
    });
  }

  /// The value passed to `reportsOverviewProvider`. Custom ranges are encoded
  /// as 'custom:YYYY-MM-DD:YYYY-MM-DD' — the datasource decodes this into the
  /// backend's `period=custom&from=..&to=..` params.
  String get _overviewRangeParam {
    if (_periodKey == 'custom' && _customRange != null) {
      final s = _customRange!.start;
      final e = _customRange!.end;
      String iso(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      return 'custom:${iso(s)}:${iso(e)}';
    }
    return _periodKey;
  }

  String get _periodLabel {
    switch (_periodKey) {
      case 'today':
        return 'Today';
      case 'this_week':
        return 'This Week';
      case 'this_year':
        return 'This Year';
      case 'custom':
        if (_customRange == null) return 'Custom Range';
        return '${_fmt2(_customRange!.start)} - ${_fmt2(_customRange!.end)}';
      case 'this_month':
      default:
        return 'This Month';
    }
  }

  Future<void> _showPeriodSheet() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        Widget option(String value, String label, IconData icon) {
          final selected = _periodKey == value;
          return ListTile(
            leading: Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            title: Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.textPrimaryDark,
                fontSize: 14,
              ),
            ),
            trailing: selected
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 18,
                  )
                : null,
            onTap: () => Navigator.pop(ctx, value),
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Filter By Date',
                    style: AppTextStyles.cardValue.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              option('today', 'Today', Icons.today_rounded),
              option('this_week', 'This Week', Icons.view_week_rounded),
              option(
                'this_month',
                'This Month',
                Icons.calendar_view_month_rounded,
              ),
              option('this_year', 'This Year', Icons.calendar_today_rounded),
              option('custom', 'Custom Date Range', Icons.date_range_rounded),
              SizedBox(height: R.sp(context, 8)),
            ],
          ),
        );
      },
    );

    if (choice == null) return;
    if (!mounted) return;

    if (choice == 'custom') {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: _customRange ?? _rangeForPeriod('this_month'),
      );
      if (picked != null) {
        _applyPeriod('custom', custom: picked);
      }
    } else {
      _applyPeriod(choice);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overviewAsync = ref.watch(
      reportsOverviewProvider(_overviewRangeParam),
    );
    final chartAsync = ref.watch(rangeChartPointsProvider(_overviewRangeParam));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(R.sp(context, 52)),
        child: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: R.sp(context, AppSpacing.screenPadding),
          title: Text('Reports & Statements', style: AppTextStyles.heading),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(reportsOverviewProvider(_overviewRangeParam));
            ref.invalidate(rangeChartPointsProvider(_overviewRangeParam));
            await ref.read(reportsProvider.notifier).fetchReportData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: R.sp(context, AppSpacing.screenPadding),
              vertical: R.sp(context, AppSpacing.sm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Sales Analysis Chart Card (shares the screen's date filter) ──
                _buildChartCard(context, chartAsync),

                SizedBox(height: R.sp(context, AppSpacing.md)),

                // ── 2. Middle Section: Metrics Grid (2 Rows x 3 Columns), scoped to the same filter ──
                overviewAsync.when(
                  data: (ov) => _buildMetricsGrid(context, ov),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) =>
                      _buildMetricsGrid(context, const ReportOverviewSummary()),
                ),

                SizedBox(height: R.sp(context, AppSpacing.lg)),

                // ── 3. Bottom Section: Reports Directory Cards ──────────────────
                Text('Reports Directory', style: AppTextStyles.sectionTitle),
                SizedBox(height: R.sp(context, AppSpacing.sm)),

                _DirectoryCard(
                  title: 'Product Sales Reports',
                  subtitle:
                      'Invoices, billing details & payment settlement status',
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFF3B82F6),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SalesReportsScreen(),
                    ),
                  ),
                ),
                _DirectoryCard(
                  title: 'Product Sales Ranking',
                  subtitle:
                      'Best selling, high profit margin & remaining stock units',
                  icon: Icons.leaderboard_rounded,
                  color: const Color(0xFF10B981),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductPerformanceScreen(),
                    ),
                  ),
                ),
                _DirectoryCard(
                  title: 'Purchases & Suppliers',
                  subtitle:
                      'Vendor sourced products, purchase order logs & balances',
                  icon: Icons.local_shipping_rounded,
                  color: const Color(0xFFF59E0B),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PurchasesSuppliersScreen(),
                    ),
                  ),
                ),
                _DirectoryCard(
                  title: 'Inventory & Stock Report',
                  subtitle:
                      'Complete stock in, out, opening & adjusted movement logs',
                  icon: Icons.inventory_2_rounded,
                  color: const Color(0xFF8B5CF6),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InventoryStockReportScreen(),
                    ),
                  ),
                ),
                _DirectoryCard(
                  title: 'Services Reports',
                  subtitle:
                      'Dynamic forms, customer orders, service charges & reprint bill',
                  icon: Icons.miscellaneous_services_rounded,
                  color: const Color(0xFF00A8D4),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ServicesReportsScreen(),
                    ),
                  ),
                ),
                _DirectoryCard(
                  title: 'Provider Reports',
                  subtitle:
                      'Recharge invoices & provider reload/initial-load amount history',
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xFF0EA5E9),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProviderReportsScreen(),
                    ),
                  ),
                ),
                _DirectoryCard(
                  title: 'Profitability & Expenses',
                  subtitle:
                      'Turnover, total purchases vs selling margin & expense items',
                  icon: Icons.pie_chart_rounded,
                  color: const Color(0xFFEF4444),
                  isLast: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfitabilityMarginsScreen(),
                    ),
                  ),
                ),
                SizedBox(height: R.sp(context, AppSpacing.lg)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, ReportOverviewSummary ov) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Total Sales',
                amount: '₹${_formatCurrency(ov.totalSales)}',
                subtitle: '${ov.totalUnitsSold.toStringAsFixed(0)} Units Sold',
                icon: Icons.bar_chart_rounded,
                color: const Color(0xFF3B82F6),
              ),
            ),
            SizedBox(width: R.sp(context, AppSpacing.xs)),
            Expanded(
              child: _MetricCard(
                title: 'Total Purchases',
                amount: '₹${_formatCurrency(ov.totalPurchases)}',
                subtitle:
                    '${ov.totalUnitsBought.toStringAsFixed(0)} Units Bought',
                icon: Icons.shopping_cart_rounded,
                color: const Color(0xFF10B981),
              ),
            ),
            SizedBox(width: R.sp(context, AppSpacing.xs)),
            Expanded(
              child: _MetricCard(
                title: 'Service Value',
                amount: '₹${_formatCurrency(ov.serviceValue)}',
                subtitle: '${ov.servicesCount} Jobs Logged',
                icon: Icons.build_circle_rounded,
                color: const Color(0xFF00A8D4),
              ),
            ),
          ],
        ),
        SizedBox(height: R.sp(context, AppSpacing.xs)),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Expense Value',
                amount: '₹${_formatCurrency(ov.expenseValue)}',
                subtitle: 'Active Overhead',
                icon: Icons.money_off_rounded,
                color: const Color(0xFF8B5CF6),
              ),
            ),
            SizedBox(width: R.sp(context, AppSpacing.xs)),
            Expanded(
              child: _MetricCard(
                title: 'Receivables',
                amount: '₹${_formatCurrency(ov.totalReceivable)}',
                subtitle: 'From Customers',
                icon: Icons.person_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ),
            SizedBox(width: R.sp(context, AppSpacing.xs)),
            Expanded(
              child: _MetricCard(
                title: 'Payables',
                amount: '₹${_formatCurrency(ov.totalPayable)}',
                subtitle: 'To Suppliers',
                icon: Icons.local_shipping_rounded,
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Updated full-number formatter with comma separators and 2 decimal places
  static String _formatCurrency(double val) {
    final parts = val.toStringAsFixed(2).split('.');
    final re = RegExp(r'\d{1,3}(?=(\d{3})+(?!\d))');
    parts[0] = parts[0].replaceAllMapped(re, (match) => '${match[0]},');
    return parts.join('.');
  }

  // ── Sales Analysis Chart Card (Horizontally scrollable with price on top & date at bottom) ──
  Widget _buildChartCard(
    BuildContext context,
    AsyncValue<List<ReportChartPoint>> chartAsync,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(R.sp(context, AppSpacing.cardPadding)),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(
          R.radius(context, AppSizes.cardRadius),
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sales Analysis',
                style: AppTextStyles.cardValue.copyWith(
                  fontSize: R.fs(context, 15),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _showPeriodSheet,
                icon: const Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                label: Text(
                  _periodLabel,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
            ],
          ),
          SizedBox(height: R.sp(context, AppSpacing.md)),
          chartAsync.when(
            loading: () => SizedBox(
              height: R.sp(context, 190),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, _) => SizedBox(
              height: R.sp(context, 190),
              child: const Center(child: Text('Failed to load chart data')),
            ),
            data: (points) {
              if (points.isEmpty) {
                return SizedBox(
                  height: R.sp(context, 190),
                  child: Center(
                    child: Text(
                      'No sales recorded for this date range',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }

              final maxAmount = points
                  .map((e) => e.amount)
                  .reduce((a, b) => a > b ? a : b);
              final ceiling = maxAmount > 0 ? maxAmount * 1.25 : 1000.0;

              return SizedBox(
                height: R.sp(context, 195),
                child: Row(
                  children: [
                    // Fixed Y-Axis Scale Labels on the Left
                    SizedBox(
                      width: R.sp(context, 38),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatYAxisLabel(ceiling),
                            style: AppTextStyles.small.copyWith(
                              fontSize: R.fs(context, 8.5),
                            ),
                          ),
                          Text(
                            _formatYAxisLabel(ceiling * 0.75),
                            style: AppTextStyles.small.copyWith(
                              fontSize: R.fs(context, 8.5),
                            ),
                          ),
                          Text(
                            _formatYAxisLabel(ceiling * 0.5),
                            style: AppTextStyles.small.copyWith(
                              fontSize: R.fs(context, 8.5),
                            ),
                          ),
                          Text(
                            _formatYAxisLabel(ceiling * 0.25),
                            style: AppTextStyles.small.copyWith(
                              fontSize: R.fs(context, 8.5),
                            ),
                          ),
                          Text(
                            '0',
                            style: AppTextStyles.small.copyWith(
                              fontSize: R.fs(context, 8.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: R.sp(context, AppSpacing.xs)),
                    // Horizontally Scrollable Bars Area
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const itemWidth = 52.0;
                          final totalChartWidth =
                              (points.length * itemWidth) > constraints.maxWidth
                              ? points.length * itemWidth
                              : constraints.maxWidth;

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: totalChartWidth,
                              child: Stack(
                                children: [
                                  // Background Grid Lines spanning the full scroll width
                                  Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: List.generate(
                                      5,
                                      (_) => Container(
                                        height: 1,
                                        color: AppColors.border,
                                      ),
                                    ),
                                  ),
                                  // Scrollable Bars Row
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: points.map((pt) {
                                      final ratio = (pt.amount / ceiling).clamp(
                                        0.0,
                                        1.0,
                                      );
                                      final availableHeight =
                                          constraints.maxHeight - 34;
                                      final barHeight = availableHeight * ratio;

                                      return SizedBox(
                                        width: itemWidth,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            // Price label on top of the bar
                                            Text(
                                              _formatBarPrice(pt.amount),
                                              style: const TextStyle(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            // Bar container
                                            Container(
                                              width: R.sp(context, 16),
                                              height: barHeight < 4
                                                  ? 4
                                                  : barHeight,
                                              decoration: const BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                      top: Radius.circular(4),
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            // Bottom date / time label
                                            SizedBox(
                                              width: itemWidth,
                                              child: Text(
                                                pt.label,
                                                style: const TextStyle(
                                                  fontSize: 8.5,
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatBarPrice(double val) {
    if (val >= 100000) return '${(val / 100000).toStringAsFixed(1)}L';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}k';
    if (val == 0) return '';
    return val.toStringAsFixed(0);
  }

  String _formatYAxisLabel(double val) {
    if (val >= 100000) return '${(val / 100000).toStringAsFixed(1)}L';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(0)}k';
    return val.toStringAsFixed(0);
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String amount;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(R.sp(context, 8)),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(
          R.radius(context, AppSizes.cardRadius),
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: R.icon(context, 14), color: color),
              SizedBox(width: R.sp(context, 4)),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.small.copyWith(
                    fontSize: R.fs(context, 10),
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: R.sp(context, 6)),
          // FittedBox automatically scales down font size if the number has many digits
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: AppTextStyles.cardValue.copyWith(
                fontSize: R.fs(context, 13.5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: R.sp(context, 2)),
          Text(
            subtitle,
            style: AppTextStyles.small.copyWith(
              fontSize: R.fs(context, 9),
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DirectoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isLast;

  const _DirectoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isLast ? 0 : R.sp(context, AppSpacing.sm),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(R.sp(context, AppSpacing.cardPadding)),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(
              R.radius(context, AppSizes.cardRadius),
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: R.sp(context, 38),
                height: R.sp(context, 38),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: R.icon(context, 18)),
              ),
              SizedBox(width: R.sp(context, AppSpacing.sm)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.cardValue.copyWith(
                        fontSize: R.fs(context, 13.5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: R.sp(context, 2)),
                    Text(
                      subtitle,
                      style: AppTextStyles.small.copyWith(
                        fontSize: R.fs(context, 11),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: R.icon(context, 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
