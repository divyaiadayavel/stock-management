// lib/features/reports/presentation/screens/customer_receivable_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../domain/entities/report_extras.dart';
import '../providers/report_extras_provider.dart';
import '../widgets/report_shared_widgets.dart';
import 'invoice_details_screen.dart';

/// Customer Receivable Details
///
/// Opened by tapping a customer on the "Receivable from Customers" list.
/// Shows:
/// 1. Customer summary — total receivable / settled / invoice count
/// 2. Every bill raised to this customer, each with its own
///    paid / balance breakdown, tapping through to the existing
///    InvoiceDetailsScreen for the full line-item + payment view.
///
/// DATA FLOW: customerDetailProvider(customerId) -> ReportsRepository
/// -> ReportsRemoteDataSource.getCustomerDetail() -> one HTTP GET to
/// reports.php?action=customer_detail&id=<id> — same single-endpoint
/// pattern as SupplierDetailsScreen's supplier_detail action, so wiring
/// the backend later only means adding that `case` server-side.
class CustomerReceivableDetailsScreen extends ConsumerWidget {
  final String customerId;
  final String? customerName;
  final String? phone;

  const CustomerReceivableDetailsScreen({
    super.key,
    required this.customerId,
    this.customerName,
    this.phone,
  });

  Future<void> _makeCall(BuildContext context, String contact) async {
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          customerName ?? 'Customer Details',
          style: AppTextStyles.heading.copyWith(fontSize: R.fs(context, 17)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: R.sp(context, AppSpacing.screenPadding)),
            child: IconButton(
              icon: Icon(Icons.call_rounded, color: AppColors.primary, size: R.icon(context, AppSizes.iconLg)),
              onPressed: () => _makeCall(
                context,
                phone ?? detailAsync.value?.phone ?? '',
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(customerDetailProvider(customerId));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: R.sp(context, AppSpacing.screenPadding),
              vertical: R.sp(context, AppSpacing.sm),
            ),
            child: ReportAsyncView<CustomerDetail>(
              value: detailAsync,
              builder: (context, detail) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummary(context, detail),
                  SizedBox(height: R.sp(context, AppSpacing.md)),
                  const ReportSectionTitle('Bills'),
                  SizedBox(height: R.sp(context, AppSpacing.xs)),
                  _buildBillsList(context, detail.bills),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, CustomerDetail detail) {
    final displayName = detail.customerName.isEmpty
        ? (customerName ?? 'Customer')
        : detail.customerName;

    return ReportSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: AppTextStyles.cardValue.copyWith(
                    fontSize: R.fs(context, 15),
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ReportBadge.auto(
                detail.outstandingBalance > 0 ? 'Due' : 'Settled',
              ),
            ],
          ),
          if (detail.phone.isNotEmpty) ...[
            SizedBox(height: R.sp(context, 2)),
            Text(
              detail.phone,
              style: AppTextStyles.small.copyWith(fontSize: R.fs(context, 11.5)),
            ),
          ],
          SizedBox(height: R.sp(context, AppSpacing.sm)),
          const Divider(height: 1, color: AppColors.border),
          SizedBox(height: R.sp(context, AppSpacing.xs)),
          ReportKeyValueRow(
            label: 'Total Receivable Amount',
            value: formatRupee(detail.outstandingBalance),
            bold: true,
            valueColor: detail.outstandingBalance > 0
                ? AppColors.red
                : AppColors.textPrimaryDark,
          ),
          ReportKeyValueRow(
            label: 'Total Sales Value',
            value: formatRupee(detail.totalSalesValue),
          ),
          ReportKeyValueRow(
            label: 'Settled Amount',
            value: formatRupee(detail.settledAmount),
            valueColor: AppColors.green,
          ),
          ReportKeyValueRow(
            label: 'Invoices',
            value: '${detail.invoiceCount}',
          ),
        ],
      ),
    );
  }

  Widget _buildBillsList(BuildContext context, List<ReportBillSummary> bills) {
    if (bills.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: R.sp(context, 24)),
        child: Center(
          child: Text(
            'No bills raised to this customer yet.',
            style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: bills.map((bill) {
        final label = bill.invoiceNumber.isNotEmpty
            ? bill.invoiceNumber
            : bill.invoiceId;
        return ReportListCard(
          leadingIcon: Icons.receipt_long_rounded,
          title: label,
          subtitle:
              '${formatReportDate(bill.date)}'
              '${bill.itemsSummary.isNotEmpty ? '\n${bill.itemsSummary}' : bill.itemCount > 0 ? '\n${bill.itemCount} item${bill.itemCount == 1 ? '' : 's'}' : ''}',
          trailingTop: formatRupee(bill.grandTotal),
          trailingTopColor: bill.balanceAmount > 0.01
              ? AppColors.orange
              : AppColors.textPrimaryDark,
          trailingBottom: '__badge__${bill.paymentStatus}',
          onTap: () {
            final invoiceId = bill.invoiceNumber.isNotEmpty
                ? bill.invoiceNumber
                : bill.invoiceId;
            if (invoiceId.isEmpty) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InvoiceDetailsScreen(invoiceId: invoiceId),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
