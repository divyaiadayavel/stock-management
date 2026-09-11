// lib/features/receivable/presentation/screens/receivable_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../reports/presentation/screens/invoice_details_screen.dart';
import '../../../reports/presentation/widgets/report_shared_widgets.dart';
import '../../domain/entities/customer_detail.dart';
import '../providers/receivable_provider.dart';

/// RECEIVABLE DETAILS SCREEN
/// ─────────────────────────
/// Opened by tapping a customer on [ReceivableScreen]. Shows a summary
/// block (Total Receivable is the exact real balance passed in from the
/// Customers screen — [currentBalance] — so it always matches) plus
/// every bill raised to this customer, tapping one goes straight to
/// [InvoiceDetailsScreen] (no preview step).
///
/// The bill list itself still comes from reports.php's `customer_detail`
/// action via [customerDetailProvider] — that's the only place the
/// itemized invoice history lives.
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
    final detailAsync = ref.watch(customerDetailProvider(customerId));
    final name = (customerName ?? '').trim().isEmpty ? 'Customer' : customerName!.trim();
    final parts = name.split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name[0].toUpperCase();

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
          onRefresh: () async => ref.invalidate(customerDetailProvider(customerId)),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: R.sp(context, 16), vertical: R.sp(context, 12)),
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

                ReportAsyncView<CustomerDetail>(
                  value: detailAsync,
                  builder: (context, detail) {
                    final paid = (detail.totalSalesValue - currentBalance).clamp(0, double.infinity);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _MiniStat(label: 'Total Sales', value: formatRupee(detail.totalSalesValue))),
                            SizedBox(width: R.sp(context, 8)),
                            Expanded(child: _MiniStat(label: 'Paid', value: formatRupee(paid.toDouble()), color: AppColors.green)),
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
                          'Bills (${detail.bills.length})',
                          style: TextStyle(fontSize: R.fs(context, 14), fontWeight: FontWeight.w700, color: AppColors.textPrimaryDark),
                        ),
                        SizedBox(height: R.sp(context, 8)),
                        _BillsList(bills: detail.bills),
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
  final List<ReportBillSummary> bills;
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

    return Column(
      children: bills.map((bill) {
        final label = bill.invoiceNumber.isNotEmpty ? bill.invoiceNumber : bill.invoiceId;
        final hasBalance = bill.balanceAmount > 0.01;
        return GestureDetector(
          onTap: () {
            final invoiceId = bill.invoiceNumber.isNotEmpty ? bill.invoiceNumber : bill.invoiceId;
            if (invoiceId.isEmpty) return;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => InvoiceDetailsScreen(invoiceId: invoiceId)),
            );
          },
          child: Container(
            margin: EdgeInsets.only(bottom: R.sp(context, 10)),
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
                      Text(label, style: TextStyle(fontSize: R.fs(context, 13.5), fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark)),
                      SizedBox(height: R.sp(context, 2)),
                      Text(
                        formatReportDate(bill.date),
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
