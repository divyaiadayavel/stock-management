import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../providers/report_extras_provider.dart';
import 'supplier_details_screen.dart';

/// Card 3 — Purchases & Suppliers Report.
///
/// Shows ONLY the suppliers list (no separate Suppliers / Purchase Orders
/// tabs — tapping "View Orders" on a supplier opens Supplier Details,
/// which has its own Products / All / Pending / Complete filter for that
/// supplier's purchase history).
///
/// Date Range: Today | This Week | This Month (default) | This Year |
/// Custom Date Range — every selection re-queries the live `purchases`
/// PHP report action (`view=suppliers`), so nothing here is mocked.
class PurchasesSuppliersScreen extends ConsumerStatefulWidget {
  const PurchasesSuppliersScreen({super.key});

  @override
  ConsumerState<PurchasesSuppliersScreen> createState() =>
      _PurchasesSuppliersScreenState();
}

class _PurchasesSuppliersScreenState
    extends ConsumerState<PurchasesSuppliersScreen> {
  // 'today' | 'this_week' | 'this_month' | 'this_year' | 'custom'
  String _periodKey = 'this_month';
  DateTimeRange? _customRange;

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Value sent to the backend. Custom ranges are encoded as
  /// 'custom:YYYY-MM-DD:YYYY-MM-DD' so the remote data source can decode
  /// it into `period=custom&from=...&to=...` query params.
  String get _periodParam {
    if (_periodKey == 'custom' && _customRange != null) {
      return 'custom:${_fmtDate(_customRange!.start)}:'
          '${_fmtDate(_customRange!.end)}';
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
        final s = _customRange!.start;
        final e = _customRange!.end;
        return '${s.day}/${s.month} - ${e.day}/${e.month}/${e.year}';
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

    if (choice == 'custom') {
      final now = DateTime.now();

      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: now,
        initialDateRange:
            _customRange ??
            DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
      );

      if (picked != null) {
        setState(() {
          _periodKey = 'custom';
          _customRange = picked;
        });
      }
    } else {
      setState(() => _periodKey = choice);
    }
  }

  String _formatCurrency(double val) {
    final parts = val.toStringAsFixed(2).split('.');
    final re = RegExp(r'\d{1,3}(?=(\d{3})+(?!\d))');

    parts[0] = parts[0].replaceAllMapped(re, (match) => '${match[0]},');

    return parts.join('.');
  }

  @override
  Widget build(BuildContext context) {
    final query = SupplierSummariesQuery(period: _periodParam);

    final suppliersAsync = ref.watch(supplierSummariesProvider(query));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(R.sp(context, 52)),
        child: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          titleSpacing: R.sp(context, AppSpacing.screenPadding),
          title: Text('Purchases & Suppliers', style: AppTextStyles.heading),

          // No This Month button here.
          //
          // The date filter has been moved below the app bar,
          // matching the Services Reports screen.
        ),
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(supplierSummariesProvider(query)),

          child: suppliersAsync.when(
            data: (suppliers) {
              if (suppliers.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(
                    R.sp(context, AppSpacing.screenPadding),
                  ),
                  children: [
                    // ----------------------------------------------------
                    // DATE RANGE
                    // ----------------------------------------------------
                    _buildDateRangeCard(context),

                    SizedBox(height: R.sp(context, 120)),

                    Center(
                      child: Text(
                        'No suppliers found for this period',
                        style: AppTextStyles.small,
                      ),
                    ),
                  ],
                );
              }

              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(
                  R.sp(context, AppSpacing.screenPadding),
                ),

                itemCount: suppliers.length + 1,

                itemBuilder: (context, index) {
                  // ------------------------------------------------------
                  // DATE RANGE CARD
                  // ------------------------------------------------------
                  if (index == 0) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: R.sp(context, AppSpacing.sm),
                      ),
                      child: _buildDateRangeCard(context),
                    );
                  }

                  final sup = suppliers[index - 1];

                  final productsSourced = sup.sourcedProducts.isNotEmpty
                      ? sup.sourcedProducts.join(', ')
                      : 'General Procurement';

                  return Container(
                    margin: EdgeInsets.only(
                      bottom: R.sp(context, AppSpacing.sm),
                    ),
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SupplierDetailsScreen(
                            supplierId: sup.id.toString(),
                            supplierName: sup.supplierName,
                          ),
                        ),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(
                          R.sp(context, AppSpacing.cardPadding),
                        ),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    sup.companyName.isNotEmpty
                                        ? '${sup.supplierName} '
                                              '(${sup.companyName})'
                                        : sup.supplierName,
                                    style: AppTextStyles.cardValue.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '₹${_formatCurrency(sup.totalPurchaseValue)}',
                                  style: AppTextStyles.cardValue.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: R.sp(context, 4)),

                            Text(
                              'Sourced: $productsSourced',
                              style: AppTextStyles.small.copyWith(fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            SizedBox(height: R.sp(context, 8)),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${sup.purchaseOrderCount} '
                                  'Purchase Order'
                                  '${sup.purchaseOrderCount == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const Text(
                                  'View Orders →',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },

            loading: () => const Center(child: CircularProgressIndicator()),

            error: (e, __) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(R.sp(context, AppSpacing.screenPadding)),
              children: [
                // --------------------------------------------------------
                // DATE RANGE
                // --------------------------------------------------------
                _buildDateRangeCard(context),

                SizedBox(height: R.sp(context, 120)),

                Center(
                  child: Text(
                    'Failed to load suppliers',
                    style: AppTextStyles.small,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // DATE RANGE CARD
  // ----------------------------------------------------------------------

  Widget _buildDateRangeCard(BuildContext context) {
    return InkWell(
      onTap: _showPeriodSheet,
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
}
