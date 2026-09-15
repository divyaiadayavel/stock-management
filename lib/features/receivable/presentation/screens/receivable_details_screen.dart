// lib/features/receivable/presentation/screens/receivable_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../reports/domain/entities/report_bill.dart';
import '../../../reports/presentation/screens/invoice_details_screen.dart';
import '../../../reports/presentation/widgets/report_shared_widgets.dart';
import '../providers/receivable_provider.dart';

/// RECEIVABLE DETAILS SCREEN
/// ─────────────────────────
/// Opened by tapping a customer on [ReceivableScreen]. Shows a summary
/// block (Total Receivable is the exact real balance passed in from the
/// Customers screen — [currentBalance] — so it always matches) plus
/// every bill raised to this customer, tapping one goes straight to
/// [InvoiceDetailsScreen] (no preview step).
///
/// DATA FLOW: [customerBillsProvider] (keyed by customer NAME, not id)
/// → reportsRepositoryProvider.getSalesReports() → the exact same
/// `reports.php?action=sales` action your Sales Reports screen already
/// uses successfully.
///
/// RESPONSIVE LAYOUT: horizontal insets come from [R.hPad], capping the
/// content to a readable max width and centering it on desktop rather
/// than stretching it edge-to-edge. The bill list itself flows through
/// [_ResponsiveGrid] — one column on phone, two on tablet and desktop.
class ReceivableDetailsScreen extends ConsumerWidget {
  final String customerId;
  final String? customerName;
  final String? phone;

  /// The real, authoritative outstanding balance for this customer,
  /// taken straight from the Customers screen's data source.
  final double currentBalance;

  const ReceivableDetailsScreen({
    super.key,
    required this.customerId,
    this.customerName,
    this.phone,
    this.currentBalance = 0.0,
  });

  Future<void> _callCustomer(BuildContext context, String contact) async {
    if (contact.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number saved for this customer.')),
      );
      return;
    }
    final cleaned = contact.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch dialer for $contact')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = (customerName ?? '').trim().isEmpty ? 'Customer' : customerName!.trim();
    final billsAsync = ref.watch(customerBillsProvider(name));
    final parts = name.split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name[0].toUpperCase();
    final hPad = R.hPad(context).left;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Customer Details',
          style: TextStyle(
            fontSize: R.fs(context, 17),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Call customer',
            icon: Icon(Icons.call_rounded, color: AppColors.primary, size: R.icon(context, 24)),
            onPressed: () => _callCustomer(context, phone ?? ''),
          ),
          SizedBox(width: R.sp(context, 4)),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(customerBillsProvider(name)),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: R.sp(context, 12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: R.fluid(context, 52, 60),
                      height: R.fluid(context, 52, 60),
                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.brandGradient),
                      child: Center(
                        child: Text(
                          initials,
                          style: TextStyle(fontSize: R.fs(context, 16), fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(width: R.sp(context, 12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: TextStyle(fontSize: R.fs(context, 16), fontWeight: FontWeight.w700, color: AppColors.textPrimaryDark)),
                          if ((phone ?? '').isNotEmpty)
                            Text(phone!, style: TextStyle(fontSize: R.fs(context, 12.5), color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: R.sp(context, 16)),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(R.sp(context, 16)),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(R.radius(context, 16)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Receivable', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: R.fs(context, 12))),
                      SizedBox(height: R.sp(context, 4)),
                      Text(
                        formatRupee(currentBalance),
                        style: TextStyle(color: Colors.white, fontSize: R.fs(context, 24), fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: R.sp(context, 12)),

                ReportAsyncView<List<ReportBill>>(
                  value: billsAsync,
                  builder: (context, bills) {
                    final totalSales = bills.fold<double>(0.0, (sum, b) => sum + b.grandTotal);
                    final totalPaid = bills.fold<double>(0.0, (sum, b) => sum + b.paidAmount);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _MiniStat(label: 'Total Sales', value: formatRupee(totalSales))),
                            SizedBox(width: R.sp(context, 8)),
                            Expanded(child: _MiniStat(label: 'Paid', value: formatRupee(totalPaid), color: AppColors.green)),
                            SizedBox(width: R.sp(context, 8)),
                            Expanded(
                              child: _MiniStat(
                                label: 'Balance',
                                value: formatRupee(currentBalance),
                                color: currentBalance > 0 ? AppColors.orange : AppColors.textPrimaryDark,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: R.sp(context, 20)),
                        Text(
                          'Bills (${bills.length})',
                          style: TextStyle(fontSize: R.fs(context, 14), fontWeight: FontWeight.w700, color: AppColors.textPrimaryDark),
                        ),
                        SizedBox(height: R.sp(context, 8)),
                        _BillsList(bills: bills),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _MiniStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: R.sp(context, 10), horizontal: R.sp(context, 8)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(R.radius(context, 12)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: R.fs(context, 10.5), color: AppColors.textSecondary), textAlign: TextAlign.center),
          SizedBox(height: R.sp(context, 4)),
          Text(
            value,
            style: TextStyle(fontSize: R.fs(context, 12.5), fontWeight: FontWeight.w700, color: color ?? AppColors.textPrimaryDark),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BillsList extends StatelessWidget {
  final List<ReportBill> bills;
  const _BillsList({required this.bills});

  @override
  Widget build(BuildContext context) {
    if (bills.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: R.sp(context, 24)),
        child: Center(
          child: Text(
            'No bills raised to this customer yet.',
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return _ResponsiveGrid(
      columns: R.gridCols(context, phone: 1, tablet: 2, desktop: 2),
      spacing: R.sp(context, 10),
      runSpacing: R.sp(context, 10),
      children: bills.map((bill) {
        final hasBalance = bill.balanceAmount > 0.01;
        return GestureDetector(
          key: ValueKey(bill.billId.isNotEmpty ? bill.billId : bill.invoiceNumber),
          onTap: () {
            if (bill.billId.isEmpty) return;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => InvoiceDetailsScreen(invoiceId: bill.billId)),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: R.sp(context, 14), vertical: R.sp(context, 12)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(R.radius(context, 12)),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: R.fluid(context, 36, 40),
                  height: R.fluid(context, 36, 40),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(R.radius(context, 10)),
                  ),
                  child: Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: R.icon(context, 18)),
                ),
                SizedBox(width: R.sp(context, 10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.invoiceNumber.isNotEmpty ? bill.invoiceNumber : bill.billId,
                        style: TextStyle(fontSize: R.fs(context, 13.5), fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
                      ),
                      SizedBox(height: R.sp(context, 2)),
                      Text(
                        '${bill.invoiceDate}${bill.itemCount > 0 ? ' • ${bill.itemCount} item${bill.itemCount == 1 ? '' : 's'}' : ''}',
                        style: TextStyle(fontSize: R.fs(context, 11.5), color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatRupee(bill.grandTotal),
                      style: TextStyle(
                        fontSize: R.fs(context, 13.5),
                        fontWeight: FontWeight.w700,
                        color: hasBalance ? AppColors.orange : AppColors.textPrimaryDark,
                      ),
                    ),
                    SizedBox(height: R.sp(context, 4)),
                    ReportBadge.auto(bill.paymentStatus),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// A tiny device-aware grid: 1 column just stacks children (identical to
/// the old Column on phone), anything more measures the available width
/// with [LayoutBuilder] and wraps equal-width children — no fixed row
/// height is assumed, so each card is free to size to its own content.
class _ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int columns;
  final double spacing;
  final double runSpacing;

  const _ResponsiveGrid({
    required this.children,
    required this.columns,
    required this.spacing,
    required this.runSpacing,
  });

  @override
  Widget build(BuildContext context) {
    if (columns <= 1) {
      return Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: runSpacing),
            children[i],
          ],
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children) SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
