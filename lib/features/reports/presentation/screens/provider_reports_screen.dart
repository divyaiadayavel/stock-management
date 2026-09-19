// lib/features/reports/presentation/screens/provider_reports_screen.dart
//
// Updated to match the SalesReportsScreen filter and date dropdown pattern.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../services/data/models/provider_recharge_model.dart';
import 'provider_invoice_details_screen.dart';
import '../../../services/presentation/screens/provider_recharge_form_screen.dart';
import '../../../services/presentation/providers/provider_recharge_provider.dart';
import '../../../settings/service_management/data/models/provider_reload_log_model.dart';
import '../widgets/report_shared_widgets.dart';
import '../providers/provider_reports_data_provider.dart';

class ProviderReportsScreen extends ConsumerStatefulWidget {
  const ProviderReportsScreen({super.key});

  @override
  ConsumerState<ProviderReportsScreen> createState() =>
      _ProviderReportsScreenState();
}

class _ProviderReportsScreenState extends ConsumerState<ProviderReportsScreen> {
  // 'invoices' | 'reload'
  String _reportType = 'invoices';

  // Provider name filter ('all' or specific provider name)
  String _providerFilter = 'all';

  // Supported:
  // this_month
  // today
  // this_week
  // this_year
  // custom:YYYY-MM-DD:YYYY-MM-DD
  String _period = 'this_month';

  // ─────────────────────────────────────────────────────────────
  // DROPDOWN VALUE
  // ─────────────────────────────────────────────────────────────

  String get _dropdownPeriodValue {
    if (_period.startsWith('custom:')) {
      return 'custom';
    }
    return _period;
  }

  // ─────────────────────────────────────────────────────────────
  // DATE HELPERS
  // ─────────────────────────────────────────────────────────────

  String _formatApiDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatDisplayDate(String date) {
    final parts = date.split('-');
    if (parts.length != 3) {
      return date;
    }
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  String _periodLabel() {
    switch (_period) {
      case 'today':
        return 'Today';
      case 'this_week':
        return 'This Week';
      case 'this_year':
        return 'This Year';
      case 'this_month':
        return 'This Month';
      default:
        if (_period.startsWith('custom:')) {
          final parts = _period.split(':');
          if (parts.length == 3) {
            return '${_formatDisplayDate(parts[1])} - '
                '${_formatDisplayDate(parts[2])}';
          }
        }
        return 'Custom Date Range';
    }
  }

  DateTimeRange? _currentCustomRange() {
    if (!_period.startsWith('custom:')) {
      return null;
    }

    final parts = _period.split(':');
    if (parts.length != 3) {
      return null;
    }

    try {
      final startParts = parts[1].split('-');
      final endParts = parts[2].split('-');

      if (startParts.length != 3 || endParts.length != 3) {
        return null;
      }

      final start = DateTime(
        int.parse(startParts[0]),
        int.parse(startParts[1]),
        int.parse(startParts[2]),
      );

      final end = DateTime(
        int.parse(endParts[0]),
        int.parse(endParts[1]),
        int.parse(endParts[2]),
      );

      return DateTimeRange(start: start, end: end);
    } catch (_) {
      return null;
    }
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();
    final initialRange =
        _currentCustomRange() ??
        DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.cyanDim,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) {
      return;
    }

    final start = _formatApiDate(picked.start);
    final end = _formatApiDate(picked.end);

    setState(() {
      _period = 'custom:$start:$end';
    });
  }

  String _buildReportKey() {
    return '$_providerFilter|$_period';
  }

  @override
  Widget build(BuildContext context) {
    final reportKey = _buildReportKey();

    return ReportScaffold(
      title: 'Provider Reports',
      onRefresh: () async {
        ref.invalidate(providerInvoiceReportsProvider(reportKey));
        ref.invalidate(providerReloadReportsProvider(reportKey));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ----------------------------------------------------------
          // 1. TOP TOGGLE + DATE DROPDOWN ROW (Matching Sales Reports)
          // ----------------------------------------------------------
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _reportType = 'invoices';
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: R.sp(context, 8),
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _reportType == 'invoices'
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: _reportType == 'invoices'
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Text(
                              'Invoices',
                              style: AppTextStyles.cardValue.copyWith(
                                fontSize: R.fs(context, 12.5),
                                fontWeight: _reportType == 'invoices'
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: _reportType == 'invoices'
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _reportType = 'reload';
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: R.sp(context, 8),
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _reportType == 'reload'
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: _reportType == 'reload'
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Text(
                              'Reload Amount',
                              style: AppTextStyles.cardValue.copyWith(
                                fontSize: R.fs(context, 12.5),
                                fontWeight: _reportType == 'reload'
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: _reportType == 'reload'
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: R.sp(context, AppSpacing.sm)),

              // Date Dropdown matching Sales Reports style
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
                    value: _dropdownPeriodValue,
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
                    selectedItemBuilder: (context) {
                      return [
                        const Text('This Month'),
                        const Text('Today'),
                        const Text('This Week'),
                        const Text('This Year'),
                        Text(
                          _period.startsWith('custom:')
                              ? _periodLabel()
                              : 'Custom Date Range',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ];
                    },
                    items: const [
                      DropdownMenuItem(
                        value: 'this_month',
                        child: Text('This Month'),
                      ),
                      DropdownMenuItem(value: 'today', child: Text('Today')),
                      DropdownMenuItem(
                        value: 'this_week',
                        child: Text('This Week'),
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
                    onChanged: (value) async {
                      if (value == null) {
                        return;
                      }
                      if (value == 'custom') {
                        await _selectCustomDateRange();
                        return;
                      }
                      setState(() {
                        _period = value;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),

          // ----------------------------------------------------------
          // CUSTOM DATE LABEL (If active)
          // ----------------------------------------------------------
          if (_period.startsWith('custom:')) ...[
            SizedBox(height: R.sp(context, 6)),
            Row(
              children: [
                Icon(
                  Icons.date_range_rounded,
                  color: AppColors.cyanDim,
                  size: R.icon(context, 14),
                ),
                SizedBox(width: R.sp(context, 5)),
                Text(
                  _periodLabel(),
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.cyanDim,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: R.sp(context, AppSpacing.sm)),

          // ----------------------------------------------------------
          // ACTIVE TAB CONTENT
          // ----------------------------------------------------------
          if (_reportType == 'invoices')
            _InvoicesTab(
              reportKey: reportKey,
              providerFilter: _providerFilter,
              onProviderFilterChanged: (v) {
                setState(() => _providerFilter = v);
              },
            )
          else
            _ReloadTab(
              reportKey: reportKey,
              providerFilter: _providerFilter,
              onProviderFilterChanged: (v) {
                setState(() => _providerFilter = v);
              },
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// INVOICES TAB
// ─────────────────────────────────────────────────────────────────────────
class _InvoicesTab extends ConsumerWidget {
  final String reportKey;
  final String providerFilter;
  final ValueChanged<String> onProviderFilterChanged;

  const _InvoicesTab({
    required this.reportKey,
    required this.providerFilter,
    required this.onProviderFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(providerInvoiceReportsProvider(reportKey));

    return ReportAsyncView<List<ProviderRechargeModel>>(
      value: invoicesAsync,
      isEmpty: (list) => list.isEmpty,
      emptyMessage: 'No provider invoices found for this date range.',
      builder: (context, invoices) {
        final allProviderNames = invoices
            .map((r) => r.providerName.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList();

        // Keep all filter options visible at all times, matching Sales Reports behavior
        final displayedProviderNames = ['all', ...allProviderNames];

        // Filter only the displayed list. The complete filter row remains
        // visible so the user can switch between All and each provider.
        final visible = invoices
            .where(
              (r) =>
                  providerFilter == 'all' || r.providerName == providerFilter,
            )
            .toList();

        final totalAmount = visible.fold<double>(0, (sum, r) => sum + r.amount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TotalsStrip(
              label: 'Total Invoiced',
              count: visible.length,
              amount: totalAmount,
              color: const Color(0xFF00A8D4),
              icon: Icons.receipt_long_rounded,
            ),
            SizedBox(height: R.sp(context, AppSpacing.sm)),

            // Keep the complete provider filter row visible, just like
            // Sales Reports keeps All/Paid/Partial/Pending visible.
            // Selecting a chip only changes the list shown below.
            // IMPORTANT: Always keep ALL filter chips visible.
            // Selecting one provider changes ONLY the list below.
            // The filter chips themselves never disappear.
            ReportSegmentedChips(
              options: displayedProviderNames
                  .map(
                    (name) => ReportChipOption(
                      name,
                      name == 'all' ? 'All (${invoices.length})' : name,
                    ),
                  )
                  .toList(),
              selected: providerFilter,
              onChanged: onProviderFilterChanged,
            ),

            SizedBox(height: R.sp(context, AppSpacing.sm)),

            ...visible.map((r) {
              final invoice = (r.invoiceNumber ?? '').trim();
              final hasBalance = r.balanceAmount > 0.01;

              final card = ReportListCard(
                leadingIcon: Icons.receipt_long_rounded,
                leadingColor: AppColors.cyanDim,
                title: r.providerName.isNotEmpty
                    ? r.providerName
                    : (invoice.isNotEmpty ? invoice : 'Provider Recharge'),
                subtitle:
                    '${r.categoryName}${r.submittedAt != null ? ' • ${formatReportDate(r.submittedAt!)}' : ''}'
                    '${invoice.isNotEmpty ? '\n$invoice' : ''}'
                    '${hasBalance ? '\nBalance due: ${formatRupee(r.balanceAmount)}' : ''}',
                trailingTop: formatRupee(r.amount),
                trailingBottom: '__badge__${r.paymentStatus}',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProviderInvoiceDetailsScreen(recharge: r),
                    ),
                  );
                  ref.invalidate(providerInvoiceReportsProvider(reportKey));
                },
              );

              // Keep all existing report UI/logic unchanged. Only invoices
              // with an outstanding balance get the Balance Payment action.
              //
              // IMPORTANT: this opens ProviderRechargeFormScreen in its
              // "settle balance" mode (existingRecharge set) — the same
              // screen used to enter the original recharge, but with
              // everything except the payment amount locked, pinned to
              // this specific recharge's outstanding balance so the user
              // can never pay more than what's actually due.
              if (!hasBalance) {
                return card;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  card,
                  Transform.translate(
                    offset: Offset(0, -R.sp(context, AppSpacing.sm)),
                    child: Container(
                      margin: EdgeInsets.only(
                        bottom: R.sp(context, AppSpacing.sm),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // No recharge id, nothing to pay against.
                          if (r.id == null) return;

                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProviderRechargeFormScreen(
                                providerId: r.providerId,
                                existingRecharge: r,
                              ),
                            ),
                          );

                          // Same refresh ProviderInvoiceDetailsScreen does
                          // after a payment: reload the raw recharge history
                          // so both the Invoices tab and the detail screen
                          // immediately reflect the new paid/balance amounts
                          // and payment_status (PAID / PARTIAL / PENDING).
                          if (context.mounted) {
                            ref.invalidate(providerRechargeHistoryProvider);
                            ref.invalidate(
                              providerInvoiceReportsProvider(reportKey),
                            );
                          }
                        },
                        icon: const Icon(Icons.account_balance_wallet_rounded),
                        label: Text(
                          'Balance Payment (${formatRupee(r.balanceAmount)})',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: R.sp(context, 12),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// RELOAD AMOUNT TAB
// ─────────────────────────────────────────────────────────────────────────
class _ReloadTab extends ConsumerWidget {
  final String reportKey;
  final String providerFilter;
  final ValueChanged<String> onProviderFilterChanged;

  const _ReloadTab({
    required this.reportKey,
    required this.providerFilter,
    required this.onProviderFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reloadsAsync = ref.watch(providerReloadReportsProvider(reportKey));

    return ReportAsyncView<List<ProviderReloadLogModel>>(
      value: reloadsAsync,
      isEmpty: (list) => list.isEmpty,
      emptyMessage: 'No provider reloads found for this date range.',
      builder: (context, reloads) {
        final allProviderNames = reloads
            .map((r) => r.providerName.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList();

        // Keep all filter options visible at all times
        final displayedProviderNames = ['all', ...allProviderNames];

        // Filter only the displayed list. The complete filter row remains
        // visible so the user can switch between All and each provider.
        final visible = reloads
            .where(
              (r) =>
                  providerFilter == 'all' || r.providerName == providerFilter,
            )
            .toList();

        final totalAmount = visible.fold<double>(0, (sum, r) => sum + r.amount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TotalsStrip(
              label: 'Total Reloaded',
              count: visible.length,
              amount: totalAmount,
              color: const Color(0xFF10B981),
              icon: Icons.account_balance_wallet_rounded,
            ),
            SizedBox(height: R.sp(context, AppSpacing.sm)),

            // Keep the complete provider filter row visible, just like
            // Sales Reports keeps All/Paid/Partial/Pending visible.
            // Selecting a chip only changes the list shown below.
            // IMPORTANT: Always keep ALL filter chips visible.
            // Selecting one provider changes ONLY the list below.
            // The filter chips themselves never disappear.
            ReportSegmentedChips(
              options: displayedProviderNames
                  .map(
                    (name) => ReportChipOption(
                      name,
                      name == 'all' ? 'All (${reloads.length})' : name,
                    ),
                  )
                  .toList(),
              selected: providerFilter,
              onChanged: onProviderFilterChanged,
            ),

            SizedBox(height: R.sp(context, AppSpacing.sm)),

            ...visible.map((r) {
              final isInitial = r.type == 'OPENING';

              return ReportListCard(
                leadingIcon: isInitial
                    ? Icons.play_circle_fill_rounded
                    : Icons.add_card_rounded,
                leadingColor: const Color(0xFF10B981),
                title: r.providerName.isNotEmpty
                    ? r.providerName
                    : 'Provider Reload',
                subtitle:
                    '${r.categoryName}${r.reloadedAt != null ? ' • ${formatReportDate(r.reloadedAt!)}' : ''}'
                    '\nBalance: ${formatRupee(r.balanceBefore)} → ${formatRupee(r.balanceAfter)}'
                    '${r.note.isNotEmpty ? '\n${r.note}' : ''}',
                trailingTop: '+${formatRupee(r.amount)}',
                trailingBottom:
                    '__badge__${isInitial ? 'INITIAL LOAD' : 'RELOAD'}',
              );
            }),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Small totals summary strip shown above each tab's list.
// ─────────────────────────────────────────────────────────────────────────
class _TotalsStrip extends StatelessWidget {
  final String label;
  final int count;
  final double amount;
  final Color color;
  final IconData icon;

  const _TotalsStrip({
    required this.label,
    required this.count,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: R.sp(context, 12),
        vertical: R.sp(context, 11),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: R.sp(context, 34),
            height: R.sp(context, 34),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: R.icon(context, 18)),
          ),
          SizedBox(width: R.sp(context, AppSpacing.sm)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.small.copyWith(
                    fontSize: R.fs(context, 10.5),
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: R.sp(context, 1)),
                Text(
                  formatRupee(amount),
                  style: AppTextStyles.cardValue.copyWith(
                    fontSize: R.fs(context, 15),
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$count ${count == 1 ? 'entry' : 'entries'}',
            style: AppTextStyles.small.copyWith(
              fontSize: R.fs(context, 11),
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
