// lib/features/reports/presentation/screens/sales_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../providers/report_extras_provider.dart';
import '../widgets/report_shared_widgets.dart';
import 'invoice_details_screen.dart';

class SalesReportsScreen extends ConsumerStatefulWidget {
  const SalesReportsScreen({super.key});

  @override
  ConsumerState<SalesReportsScreen> createState() => _SalesReportsScreenState();
}

class _SalesReportsScreenState extends ConsumerState<SalesReportsScreen> {
  // Payment status filter.
  String _filter = 'all';

  // Supported:
  // this_month
  // today
  // this_week
  // this_year
  // custom:YYYY-MM-DD:YYYY-MM-DD
  String _period = 'this_month';

  String _query = '';

  final TextEditingController _searchCtrl = TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

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

  // ─────────────────────────────────────────────────────────────
  // PAYMENT FILTER & STATUS EVALUATION
  // ─────────────────────────────────────────────────────────────

  // The backend already tells us the authoritative payment_status for
  // each bill (PAID / PARTIAL / PENDING), and ReportBill now carries
  // real paidAmount/balanceAmount fields straight from the server —
  // no more guessing at property names that don't exist on the model.
  String _getEffectivePaymentStatus(dynamic bill) {
    final status = bill.paymentStatus.toString().trim().toUpperCase();

    if (status == 'PAID') return 'paid';
    if (status == 'PARTIAL') return 'partial';
    // PENDING, CREDIT, UNPAID, or anything else with money still owed.
    return 'pending';
  }

  List<dynamic> _filterBillsLocally(List<dynamic> bills) {
    if (_filter == 'all') {
      return bills;
    }

    return bills.where((bill) {
      final status = _getEffectivePaymentStatus(bill);
      return status == _filter;
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────
  // SEARCH BAR
  // ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar(BuildContext context) {
    final focused = _searchFocusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(
          R.radius(context, AppSizes.radiusMd),
        ),
        border: Border.all(
          color: focused ? AppColors.cyanDim : AppColors.border,
          width: focused ? 1.4 : 1,
        ),
      ),
      child: TextField(
        controller: _searchCtrl,
        focusNode: _searchFocusNode,
        onChanged: (value) {
          setState(() {
            _query = value;
          });
        },
        style: AppTextStyles.cardValue.copyWith(fontSize: R.fs(context, 13)),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search invoice # or customer...',
          hintStyle: AppTextStyles.small,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: focused ? AppColors.cyanDim : AppColors.textSecondary,
            size: R.icon(context, 18),
          ),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchCtrl.clear();

                    setState(() {
                      _query = '';
                    });
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: R.icon(context, 17),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: R.sp(context, 12)),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // INVOICE NUMBER HIGHLIGHT
  // ─────────────────────────────────────────────────────────────

  List<TextSpan> _highlightInvoiceNumber(
    BuildContext context,
    String invoiceNumber,
  ) {
    final search = _query.trim();

    final baseStyle = AppTextStyles.cardValue.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: R.fs(context, 13),
    );

    if (search.isEmpty) {
      return [TextSpan(text: invoiceNumber, style: baseStyle)];
    }

    final lowerInvoice = invoiceNumber.toLowerCase();

    final lowerSearch = search.toLowerCase();

    final spans = <TextSpan>[];

    int currentIndex = 0;

    while (currentIndex < invoiceNumber.length) {
      final matchIndex = lowerInvoice.indexOf(lowerSearch, currentIndex);

      if (matchIndex == -1) {
        spans.add(
          TextSpan(
            text: invoiceNumber.substring(currentIndex),
            style: baseStyle,
          ),
        );

        break;
      }

      if (matchIndex > currentIndex) {
        spans.add(
          TextSpan(
            text: invoiceNumber.substring(currentIndex, matchIndex),
            style: baseStyle,
          ),
        );
      }

      spans.add(
        TextSpan(
          text: invoiceNumber.substring(matchIndex, matchIndex + search.length),
          style: baseStyle.copyWith(
            color: AppColors.cyanDim,
            fontWeight: FontWeight.w800,
            backgroundColor: AppColors.cyanDim.withValues(alpha: 0.14),
          ),
        ),
      );

      currentIndex = matchIndex + search.length;
    }

    return spans;
  }

  // ─────────────────────────────────────────────────────────────
  // INVOICE CARD
  // ─────────────────────────────────────────────────────────────

  Widget _buildInvoiceCard(BuildContext context, dynamic bill) {
    final invoiceNumber = bill.invoiceNumber.toString();
    final double total = (bill.totalAmount ?? bill.grandTotal ?? 0.0)
        .toDouble();

    // ReportBill now carries real paidAmount/balanceAmount straight
    // from the server (see report_bill_model.dart) — no more guessing.
    final double paid = (bill.paidAmount as num).toDouble();
    final double due = (bill.balanceAmount as num).toDouble();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvoiceDetailsScreen(invoiceId: bill.billId),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(R.sp(context, AppSpacing.cardPadding)),
        margin: EdgeInsets.only(bottom: R.sp(context, AppSpacing.sm)),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(
            R.radius(context, AppSizes.cardRadius),
          ),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Invoice number
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: _highlightInvoiceNumber(context, invoiceNumber),
                    ),
                  ),

                  SizedBox(height: R.sp(context, 3)),

                  Text(
                    '${bill.customerName.isEmpty ? 'Walk-in Customer' : bill.customerName} • '
                    '${formatReportDate(bill.date)}\n'
                    '${bill.items} Item'
                    '${bill.items == 1 ? '' : 's'}',
                    style: AppTextStyles.small.copyWith(
                      fontSize: R.fs(context, 11),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            SizedBox(width: R.sp(context, AppSpacing.xs)),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatRupee(total),
                  style: AppTextStyles.cardValue.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: R.fs(context, 13),
                  ),
                ),

                SizedBox(height: R.sp(context, 4)),

                if (paid > 0.01) ...[
                  Text(
                    'PAID ${formatRupee(paid)}',
                    style: AppTextStyles.small.copyWith(
                      fontSize: R.fs(context, 9.5),
                      fontWeight: FontWeight.w700,
                      color: AppColors.green,
                    ),
                  ),
                  SizedBox(height: R.sp(context, 2)),
                ],

                if (due > 0.01) ...[
                  Text(
                    paid <= 0.01
                        ? 'PENDING ${formatRupee(due)}'
                        : 'DUE ${formatRupee(due)}',
                    style: AppTextStyles.small.copyWith(
                      fontSize: R.fs(context, 9.5),
                      fontWeight: FontWeight.w700,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final query = SalesReportsQuery(
      filter: 'all',
      query: _query,
      period: _period,
    );

    final billsAsync = ref.watch(salesReportsProvider(query));

    return ReportScaffold(
      title: 'Sales Reports',

      onRefresh: () async {
        ref.invalidate(salesReportsProvider(query));
      },

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─────────────────────────────────────────────────────────
          // SEARCH + PERIOD
          // ─────────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(child: _buildSearchBar(context)),

              SizedBox(width: R.sp(context, AppSpacing.sm)),

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

          // ─────────────────────────────────────────────────────────
          // CUSTOM DATE LABEL
          // ─────────────────────────────────────────────────────────
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

          // ─────────────────────────────────────────────────────────
          // REPORT CONTENT
          // ─────────────────────────────────────────────────────────
          ReportAsyncView(
            value: billsAsync,
            isEmpty: (list) => list.isEmpty,
            emptyMessage: 'No invoices found for this period.',
            builder: (context, bills) {
              final filteredBills = _filterBillsLocally(bills);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ───────────────────────────────────────────────
                  // PAYMENT FILTER
                  // ───────────────────────────────────────────────
                  ReportSegmentedChips(
                    options: [
                      ReportChipOption('all', 'All (${bills.length})'),
                      const ReportChipOption('paid', 'Paid'),
                      const ReportChipOption('partial', 'Partial'),
                      const ReportChipOption('pending', 'Pending'),
                    ],
                    selected: _filter,
                    onChanged: (value) {
                      setState(() {
                        _filter = value;
                      });
                    },
                  ),

                  SizedBox(height: R.sp(context, AppSpacing.sm)),

                  // ───────────────────────────────────────────────
                  // INVOICES
                  // ───────────────────────────────────────────────
                  if (filteredBills.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: R.sp(context, 24),
                      ),
                      child: Center(
                        child: Text(
                          'No invoices found for this filter.',
                          style: AppTextStyles.small,
                        ),
                      ),
                    )
                  else
                    ...filteredBills.map(
                      (bill) => _buildInvoiceCard(context, bill),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
