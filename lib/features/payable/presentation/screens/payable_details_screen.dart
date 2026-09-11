// lib/features/payable/presentation/screens/payable_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../reports/presentation/screens/po_details_screen.dart';
import '../../../reports/presentation/widgets/report_shared_widgets.dart';
import '../../domain/entities/supplier_detail.dart';
import '../providers/payable_provider.dart';

/// PAYABLE DETAILS SCREEN
/// ───────────────────────
/// Opened by tapping a supplier on [PayableScreen]. Shows a summary
/// block (Total Payable is the exact real balance passed in from the
/// Suppliers screen — [currentBalance] — so it always matches) plus
/// every purchase order raised with this supplier, tapping one goes
/// straight to [PoDetailsScreen] (no preview step).
///
/// The purchase-order list itself still comes from reports.php's
/// `supplier_detail` action via [supplierDetailProvider] — that's the
/// only place the itemized purchase history lives.
class PayableDetailsScreen extends ConsumerWidget {
  final String supplierId;
  final String? supplierName;
  final String? phone;

  /// The real, authoritative outstanding balance for this supplier,
  /// taken straight from the Suppliers screen's data source.
  final double currentBalance;

  const PayableDetailsScreen({
    super.key,
    required this.supplierId,
    this.supplierName,
    this.phone,
    this.currentBalance = 0.0,
  });

  Future<void> _callSupplier(BuildContext context, String contact) async {
    if (contact.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number saved for this supplier.')),
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
    final detailAsync = ref.watch(supplierDetailProvider(supplierId));
    final name = (supplierName ?? '').trim().isEmpty ? 'Supplier' : supplierName!.trim();
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
          'Supplier Details',
          style: TextStyle(
            fontSize: R.fs(context, 17),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Call supplier',
            icon: Icon(Icons.call_rounded, color: AppColors.primary, size: R.icon(context, 24)),
            onPressed: () => _callSupplier(context, phone ?? ''),
          ),
          SizedBox(width: R.sp(context, 4)),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(supplierDetailProvider(supplierId)),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: R.sp(context, 16), vertical: R.sp(context, 12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Identity row ──
                Row(
                  children: [
                    Container(
                      width: R.fluid(context, 52, 60),
                      height: R.fluid(context, 52, 60),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.brandGradient,
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontSize: R.fs(context, 16),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: R.sp(context, 12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: R.fs(context, 16),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                          if ((phone ?? '').isNotEmpty)
                            Text(
                              phone!,
                              style: TextStyle(fontSize: R.fs(context, 12.5), color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: R.sp(context, 16)),

                // ── Total payable headline ──
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
                      Text(
                        'Total Payable',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: R.fs(context, 12)),
                      ),
                      SizedBox(height: R.sp(context, 4)),
                      Text(
                        formatRupee(currentBalance),
                        style: TextStyle(color: Colors.white, fontSize: R.fs(context, 24), fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: R.sp(context, 12)),

                ReportAsyncView<SupplierDetail>(
                  value: detailAsync,
                  builder: (context, detail) {
                    final paid = (detail.totalProcurementValue - currentBalance).clamp(0, double.infinity);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _MiniStat(label: 'Total Purchases', value: formatRupee(detail.totalProcurementValue)),
                            ),
                            SizedBox(width: R.sp(context, 8)),
                            Expanded(
                              child: _MiniStat(label: 'Paid', value: formatRupee(paid.toDouble()), color: AppColors.green),
                            ),
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
                          'Purchase Orders (${detail.orders.length})',
                          style: TextStyle(
                            fontSize: R.fs(context, 14),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                        SizedBox(height: R.sp(context, 8)),
                        _PurchasesList(orders: detail.orders),
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

class _PurchasesList extends StatelessWidget {
  final List<PurchaseOrderSummary> orders;
  const _PurchasesList({required this.orders});

  String _formatQuantity(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: R.sp(context, 24)),
        child: Center(
          child: Text(
            'No purchases made from this supplier yet.',
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: orders.map((order) {
        final hasBalance = order.balanceAmount > 0.01;
        final qtyText = _formatQuantity(order.totalQuantity);
        return GestureDetector(
          onTap: () {
            if (order.poNumber.isEmpty) return;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PoDetailsScreen(poNumber: order.poNumber)),
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
                  child: Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: R.icon(context, 18)),
                ),
                SizedBox(width: R.sp(context, 10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.poNumber, style: TextStyle(fontSize: R.fs(context, 13.5), fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark)),
                      SizedBox(height: R.sp(context, 2)),
                      Text(
                        '${formatReportDate(order.purchaseDate).split(',').first} • $qtyText Qty'
                        '${order.itemsSummary.isNotEmpty ? '\n${order.itemsSummary}' : ''}',
                        style: TextStyle(fontSize: R.fs(context, 11.5), color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatRupee(order.grandTotal),
                      style: TextStyle(
                        fontSize: R.fs(context, 13.5),
                        fontWeight: FontWeight.w700,
                        color: hasBalance ? AppColors.orange : AppColors.textPrimaryDark,
                      ),
                    ),
                    SizedBox(height: R.sp(context, 4)),
                    ReportBadge.auto(order.paymentStatus.isNotEmpty ? order.paymentStatus : order.purchaseStatus),
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
