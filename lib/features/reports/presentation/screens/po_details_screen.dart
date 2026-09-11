import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../providers/report_extras_provider.dart';

/// Purchase Order Details — full breakdown for a single PO, fetched live
/// from the `purchase_detail` PHP report action via
/// [purchaseOrderDetailProvider]. Accepts either the numeric purchases.id
/// or the human PO number (e.g. "PO-52") in [poNumber]; the backend
/// resolves either.
class PoDetailsScreen extends ConsumerWidget {
  final String poNumber;

  const PoDetailsScreen({super.key, required this.poNumber});

  String _formatCurrency(double val) {
    final parts = val.toStringAsFixed(2).split('.');
    final re = RegExp(r'\d{1,3}(?=(\d{3})+(?!\d))');
    parts[0] = parts[0].replaceAllMapped(re, (match) => '${match[0]},');
    return parts.join('.');
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RECEIVED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'PENDING':
      case 'ORDERED':
      case 'OPEN':
      case 'DRAFT':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poAsync = ref.watch(purchaseOrderDetailProvider(poNumber));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(R.sp(context, 52)),
        child: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          titleSpacing: R.sp(context, AppSpacing.screenPadding),
          title: Text('Purchase Order Details', style: AppTextStyles.heading),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(purchaseOrderDetailProvider(poNumber)),
          child: poAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, __) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: R.sp(context, 120)),
                Center(
                  child: Text(
                    'Failed to load this purchase order',
                    style: AppTextStyles.small,
                  ),
                ),
              ],
            ),
            data: (po) {
              final items = po.items;
              final receivedDate = po.status.toUpperCase() == 'RECEIVED'
                  ? _fmtDate(po.date)
                  : 'Not yet received';

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(
                  R.sp(context, AppSpacing.screenPadding),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header Card ──
                    Container(
                      width: double.infinity,
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'PO Number: ${po.poNumber}',
                                  style: AppTextStyles.cardValue.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(
                                    po.status,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  po.status,
                                  style: TextStyle(
                                    color: _statusColor(po.status),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: R.sp(context, AppSpacing.sm)),
                          Text(
                            'Supplier: ${po.supplierName}',
                            style: AppTextStyles.small.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: R.sp(context, AppSpacing.xs)),
                          Text(
                            'Ordered Date: ${_fmtDate(po.date)}',
                            style: AppTextStyles.small,
                          ),
                          SizedBox(height: R.sp(context, AppSpacing.xs)),
                          Text(
                            'Received Date: $receivedDate',
                            style: AppTextStyles.small.copyWith(
                              color: po.status.toUpperCase() == 'RECEIVED'
                                  ? Colors.green
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: R.sp(context, AppSpacing.sm)),
                          const Divider(height: 1),
                          SizedBox(height: R.sp(context, AppSpacing.sm)),
                          _summaryRow('Subtotal', po.subtotal),
                          SizedBox(height: R.sp(context, 4)),
                          _summaryRow('Tax + Shipping', po.taxOrShipping),
                          SizedBox(height: R.sp(context, 6)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Grand Total',
                                style: AppTextStyles.cardValue.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '₹${_formatCurrency(po.grandTotal)}',
                                style: AppTextStyles.cardValue.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: R.sp(context, AppSpacing.md)),
                    Text('Order Items', style: AppTextStyles.sectionTitle),
                    SizedBox(height: R.sp(context, AppSpacing.sm)),
                    items.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(R.sp(context, 32)),
                              child: Text(
                                'No items found in this order',
                                style: AppTextStyles.small,
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final itemMap =
                                  items[index] is Map<String, dynamic>
                                  ? items[index] as Map<String, dynamic>
                                  : <String, dynamic>{};
                              final itemName =
                                  itemMap['product_name']?.toString() ??
                                  'Product #${index + 1}';
                              final qty =
                                  (itemMap['quantity'] as num?)?.toDouble() ??
                                  1.0;
                              final unitPrice =
                                  (itemMap['unit_price'] as num?)?.toDouble() ??
                                  0.0;
                              final total =
                                  (itemMap['total'] as num?)?.toDouble() ??
                                  (unitPrice * qty);

                              return Container(
                                margin: EdgeInsets.only(
                                  bottom: R.sp(context, AppSpacing.xs),
                                ),
                                padding: EdgeInsets.all(R.sp(context, 12)),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            itemName,
                                            style: AppTextStyles.cardValue
                                                .copyWith(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Qty: ${qty % 1 == 0 ? qty.toStringAsFixed(0) : qty.toStringAsFixed(2)}  •  Unit: ₹${_formatCurrency(unitPrice)}',
                                            style: AppTextStyles.small.copyWith(
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '₹${_formatCurrency(total)}',
                                      style: AppTextStyles.cardValue.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
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
            },
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          '₹${_formatCurrency(value)}',
          style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
