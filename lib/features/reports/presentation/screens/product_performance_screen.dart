import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../providers/report_extras_provider.dart';
import '../widgets/report_shared_widgets.dart';

/// Card 2 — Product Sales Ranking.
///
/// Sort By: Best Selling | Top Profit | Low Performing (drives the `view`
/// param on the PHP `products` report action).
///
/// Date Range: Today | This Week | This Month (default) | This Year |
/// Custom Date Range (drives the `period` / `from` / `to` params on the
/// same action). Every combination re-queries the live DB — nothing here
/// is mocked.
class ProductPerformanceScreen extends ConsumerStatefulWidget {
  const ProductPerformanceScreen({super.key});

  @override
  ConsumerState<ProductPerformanceScreen> createState() =>
      _ProductPerformanceScreenState();
}

class _ProductPerformanceScreenState
    extends ConsumerState<ProductPerformanceScreen> {
  String _segment = 'fast_selling';

  // 'today' | 'this_week' | 'this_month' | 'this_year' | 'custom'
  String _periodKey = 'this_month';
  DateTimeRange? _customRange;

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// The value sent to the backend. Custom ranges are encoded as
  /// 'custom:YYYY-MM-DD:YYYY-MM-DD' so the remote data source can decode
  /// it into `period=custom&from=...&to=...` query params.
  String get _periodParam {
    if (_periodKey == 'custom' && _customRange != null) {
      return 'custom:${_fmtDate(_customRange!.start)}:${_fmtDate(_customRange!.end)}';
    }
    return _periodKey;
  }

  String get _periodDropdownLabel {
    switch (_periodKey) {
      case 'today':
        return 'Today';
      case 'this_week':
        return 'This Week';
      case 'this_year':
        return 'This Year';
      case 'custom':
        return 'Custom Range';
      case 'this_month':
      default:
        return 'This Month';
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange:
          _customRange ??
          DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
      firstDate: DateTime(2020),
      lastDate: now,
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
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _periodKey = 'custom';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ProductPerformanceQuery(
      segment: _segment,
      period: _periodParam,
    );
    final productsAsync = ref.watch(productPerformanceProvider(query));

    return ReportScaffold(
      title: 'Product Sales Ranking',
      // "Live Performance" chip removed from the app bar per request.
      onRefresh: () async => ref.invalidate(productPerformanceProvider(query)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Sort By: Best Selling | Top Profit | Low Performing ──
          const ReportSectionTitle('SORT BY'),
          SizedBox(height: R.sp(context, AppSpacing.xs)),
          ReportSegmentedChips(
            options: const [
              ReportChipOption('fast_selling', 'Best Selling'),
              ReportChipOption('high_margin', 'Top Profit'),
              ReportChipOption('low_performing', 'Low Performing'),
            ],
            selected: _segment,
            onChanged: (v) => setState(() => _segment = v),
          ),
          SizedBox(height: R.sp(context, AppSpacing.md)),

          // ── Date Range: Today | This Week | This Month | This Year | Custom ──
          Row(
            children: [
              const Expanded(child: ReportSectionTitle('DATE RANGE')),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _periodKey,
                    isDense: true,
                    icon: const Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 20,
                      color: Colors.black87,
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    selectedItemBuilder: (context) => [
                      Text(
                        'Today',
                        style: TextStyle(
                          fontSize: R.fs(context, 12),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'This Week',
                        style: TextStyle(
                          fontSize: R.fs(context, 12),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'This Month',
                        style: TextStyle(
                          fontSize: R.fs(context, 12),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'This Year',
                        style: TextStyle(
                          fontSize: R.fs(context, 12),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _periodDropdownLabel,
                        style: TextStyle(
                          fontSize: R.fs(context, 12),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    items: const [
                      DropdownMenuItem(value: 'today', child: Text('Today')),
                      DropdownMenuItem(
                        value: 'this_week',
                        child: Text('This Week'),
                      ),
                      DropdownMenuItem(
                        value: 'this_month',
                        child: Text('This Month'),
                      ),
                      DropdownMenuItem(
                        value: 'this_year',
                        child: Text('This Year'),
                      ),
                      DropdownMenuItem(
                        value: 'custom',
                        child: Text('Custom Date Range'),
                      ),
                    ],
                    onChanged: (val) async {
                      if (val == null) return;
                      if (val == 'custom') {
                        await _pickCustomRange();
                      } else {
                        setState(() => _periodKey = val);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          if (_periodKey == 'custom' && _customRange != null) ...[
            SizedBox(height: R.sp(context, AppSpacing.xs)),
            GestureDetector(
              onTap: _pickCustomRange,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: R.sp(context, AppSpacing.sm),
                  vertical: R.sp(context, 8),
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: R.icon(context, 15),
                      color: AppColors.primary,
                    ),
                    SizedBox(width: R.sp(context, 6)),
                    Text(
                      '${_fmtDate(_customRange!.start)}  to  ${_fmtDate(_customRange!.end)}',
                      style: TextStyle(
                        fontSize: R.fs(context, 12),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.edit_calendar_rounded,
                      size: R.icon(context, 15),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: R.sp(context, AppSpacing.md)),

          // ── Product Summary Table/List: Name, Cost vs Retail, Units Sold &
          // Remaining Stock, Profit Margin % — all live from the DB. ──
          ReportAsyncView(
            value: productsAsync,
            isEmpty: (list) => list.isEmpty,
            emptyMessage: 'No product performance analytics recorded yet.',
            builder: (context, products) {
              return Column(
                children: products.map((p) {
                  return ReportListCard(
                    title: p.productName,
                    subtitle:
                        'Cost: ${formatRupee(p.purchasePrice)} ➔ Retail: ${formatRupee(p.sellingPrice)}\n'
                        'Sold: ${p.unitsSold.toStringAsFixed(0)} Units • Left: ${p.remainingUnits.toStringAsFixed(0)} Units',
                    trailingTop: formatRupee(p.revenue),
                    trailingTopColor: AppColors.primary,
                    trailingBottom:
                        '__badge__${p.profitMarginPercent.toStringAsFixed(1)}% Margin',
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
