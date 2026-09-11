import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../providers/report_extras_provider.dart';
import '../widgets/report_shared_widgets.dart';
import 'po_details_screen.dart';

/// Card 5 — Inventory & Stock Report.
///
/// Tabs: Stock Movements | Received Orders | Pending / Ordered | Low Stock
/// Alerts. Range selector: Today | This Week | This Month | Custom Date
/// Range — every tab and the summary tiles re-query the PHP `inventory`
/// report action for the selected range, so all data is live from the DB.
class InventoryStockReportScreen extends ConsumerStatefulWidget {
  const InventoryStockReportScreen({super.key});

  @override
  ConsumerState<InventoryStockReportScreen> createState() =>
      _InventoryStockReportScreenState();
}

class _InventoryStockReportScreenState
    extends ConsumerState<InventoryStockReportScreen> {
  String _tab = 'movements';

  // 'today' | 'this_week' | 'this_month' | 'custom'
  String _periodKey = 'this_month';
  DateTimeRange? _customRange;

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// The value passed into every family provider for this screen. Custom
  /// ranges are encoded as 'custom:YYYY-MM-DD:YYYY-MM-DD' so the existing
  /// `FutureProvider.family<T, String>` signatures don't need to change.
  String get _rangeParam {
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

  void _invalidateAll() {
    ref.invalidate(inventoryStockSummaryProvider(_rangeParam));
    ref.invalidate(stockMovementsProvider(_rangeParam));
    ref.invalidate(receivedOrdersProvider(_rangeParam));
    ref.invalidate(pendingOrdersProvider(_rangeParam));
    ref.invalidate(lowStockAlertsProvider);
  }

  /// Maps the DB's `movement_type` values to the labels the report should
  /// show: In-Stock, Out-Stock, Opening Balance, Updated Adjustment — plus
  /// Sale, which the DB also logs as its own type.
  String _movementLabel(String movementType) {
    switch (movementType.toUpperCase()) {
      case 'STOCK_IN':
        return 'In-Stock';
      case 'STOCK_OUT':
        return 'Out-Stock';
      case 'OPENING_STOCK':
        return 'Opening Balance';
      case 'ADJUSTMENT':
        return 'Updated Adjustment';
      case 'SALE':
        return 'Sale';
      default:
        return movementType;
    }
  }

  String _formatTimestamp(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return formatReportDate(dt);
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(inventoryStockSummaryProvider(_rangeParam));

    return ReportScaffold(
      title: 'Inventory & Stock Report',
      onRefresh: () async => _invalidateAll(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary tiles: Stock Valuation / Active Items, Purchase Orders / Pending ──
          ReportAsyncView(
            value: summaryAsync,
            builder: (context, summary) {
              return ReportStatGrid(
                tiles: [
                  ReportStatTile(
                    title: 'Stock Valuation',
                    value: formatRupee(summary.stockValuation),
                    subtitle: '${summary.activeItems} Active Items',
                    icon: Icons.inventory_2_rounded,
                    color: AppColors.primary,
                  ),
                  ReportStatTile(
                    title: 'Purchase Orders',
                    value:
                        '${summary.purchaseOrdersTotal.toStringAsFixed(0)} Total',
                    subtitle:
                        '${summary.pendingOrdered.toStringAsFixed(0)} Pending / Ordered',
                    icon: Icons.receipt_long_rounded,
                    color: AppColors.orange,
                  ),
                ],
              );
            },
          ),
          SizedBox(height: R.sp(context, AppSpacing.sm)),

          // ── Range selector: Today | This Week | This Month | Custom Date Range ──
          Row(
            children: [
              const Expanded(child: ReportSectionTitle('MOVEMENTS LOG')),
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
          SizedBox(height: R.sp(context, AppSpacing.sm)),

          // ── Tabs ──
          ReportSegmentedChips(
            options: const [
              ReportChipOption('movements', 'Stock Movements'),
              ReportChipOption('received', 'Received Orders'),
              ReportChipOption('pending', 'Pending / Ordered'),
              ReportChipOption('low_stock', 'Low Stock Alerts'),
            ],
            selected: _tab,
            onChanged: (v) => setState(() => _tab = v),
          ),
          SizedBox(height: R.sp(context, AppSpacing.sm)),

          if (_tab == 'movements') _buildMovements(context),
          if (_tab == 'received') _buildReceivedOrders(context),
          if (_tab == 'pending') _buildPendingOrders(context),
          if (_tab == 'low_stock') _buildLowStock(context),
        ],
      ),
    );
  }

  // ── Stock Movements: tracks In-Stock / Out-Stock / Opening Balance /
  // Updated Adjustment (+ Sale), with From Qty ➔ To Qty and a timestamp. ──
  Widget _buildMovements(BuildContext context) {
    final movementsAsync = ref.watch(stockMovementsProvider(_rangeParam));

    return ReportAsyncView(
      value: movementsAsync,
      isEmpty: (list) => list.isEmpty,
      emptyMessage: 'No stock movements recorded for this period.',
      builder: (context, movements) {
        return Column(
          children: movements.map((m) {
            final isPositive = m.quantityChange >= 0;
            final delta =
                '${isPositive ? '+' : ''}${m.quantityChange.toStringAsFixed(0)}';

            return ReportListCard(
              title: m.productName,
              subtitle:
                  'Ref: ${m.reference}\n${m.stockBefore.toStringAsFixed(0)} ➔ ${m.stockAfter.toStringAsFixed(0)} units • ${_formatTimestamp(m.createdAt)}',
              trailingTop: '$delta Qty',
              trailingTopColor: isPositive ? AppColors.green : AppColors.red,
              trailingBottom: '__badge__${_movementLabel(m.movementType)}',
            );
          }).toList(),
        );
      },
    );
  }

  // ── Received Orders: purchase orders already inwarded, tap to open PO Details ──
  Widget _buildReceivedOrders(BuildContext context) {
    final receivedAsync = ref.watch(receivedOrdersProvider(_rangeParam));

    return ReportAsyncView(
      value: receivedAsync,
      isEmpty: (list) => list.isEmpty,
      emptyMessage: 'No orders received in this period.',
      builder: (context, orders) {
        return Column(
          children: orders.map((o) {
            return ReportListCard(
              title: '${o.poNumber} (${o.supplierName})',
              subtitle:
                  'Received on ${formatReportDate(o.receivedDate)} • ${o.totalQuantity.toStringAsFixed(0)} Units Inwarded\nItem: ${o.itemsSummary.isEmpty ? '—' : o.itemsSummary}',
              trailingTop: formatRupee(o.grandTotal),
              trailingBottom: '__badge__${o.purchaseStatus}',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PoDetailsScreen(poNumber: o.poNumber),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ── Pending / Ordered: purchase orders awaiting delivery, tap to open PO Details ──
  Widget _buildPendingOrders(BuildContext context) {
    final pendingAsync = ref.watch(pendingOrdersProvider(_rangeParam));

    return ReportAsyncView(
      value: pendingAsync,
      isEmpty: (list) => list.isEmpty,
      emptyMessage: 'No pending or ordered purchase orders in this period.',
      builder: (context, orders) {
        return Column(
          children: orders.map((o) {
            return ReportListCard(
              title: '${o.poNumber} (${o.supplierName})',
              subtitle:
                  'Ordered on ${formatReportDate(o.orderedDate)} • Awaiting Delivery\nItem: ${o.itemsSummary.isEmpty ? '—' : o.itemsSummary}',
              trailingTop: formatRupee(o.grandTotal),
              trailingBottom: '__badge__${o.status}',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PoDetailsScreen(poNumber: o.poNumber),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLowStock(BuildContext context) {
    final lowStockAsync = ref.watch(lowStockAlertsProvider);

    return ReportAsyncView(
      value: lowStockAsync,
      isEmpty: (list) => list.isEmpty,
      emptyMessage: 'All products are currently well stocked.',
      builder: (context, alerts) {
        return Column(
          children: alerts.map((a) {
            final isCritical = a.currentStock <= 0;
            return ReportListCard(
              title: a.productName,
              subtitle:
                  'Supplier: ${a.supplierName}\nMin Level: ${a.reorderLevel.toStringAsFixed(0)} • Cost: ${formatRupee(a.purchasePrice)}',
              trailingTop: '${a.currentStock.toStringAsFixed(0)} Units Left',
              trailingTopColor: isCritical ? AppColors.red : AppColors.orange,
              trailingBottom: '__badge__${a.status}',
            );
          }).toList(),
        );
      },
    );
  }
}
