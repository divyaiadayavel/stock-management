import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../providers/report_extras_provider.dart';
import '../widgets/report_shared_widgets.dart';
import 'po_details_screen.dart';

/// Supplier Details
///
/// Shows:
/// 1. Supplier summary
/// 2. Products purchased from this supplier
/// 3. All purchase orders
/// 4. Pending purchase orders
/// 5. Completed purchase orders
///
/// All data comes from:
/// supplierDetailProvider -> repository -> datasource -> backend
class SupplierDetailsScreen extends ConsumerStatefulWidget {
  final String supplierId;
  final String? supplierName;

  const SupplierDetailsScreen({
    super.key,
    required this.supplierId,
    this.supplierName,
  });

  @override
  ConsumerState<SupplierDetailsScreen> createState() =>
      _SupplierDetailsScreenState();
}

class _SupplierDetailsScreenState extends ConsumerState<SupplierDetailsScreen> {
  /// Available filters:
  ///
  /// products
  /// all
  /// pending
  /// complete
  ///
  /// Products is the default because this screen is primarily
  /// used to see what products were purchased from this supplier.
  String _filter = 'products';

  /// Purchase statuses considered pending.
  static const Set<String> _pendingStatuses = {
    'PENDING',
    'ORDERED',
    'OPEN',
    'DRAFT',
  };

  /// Purchase statuses considered complete.
  static const Set<String> _completeStatuses = {
    'RECEIVED',
    'COMPLETED',
    'COMPLETE',
    'PAID',
  };

  // ================================================================
  // NUMBER HELPERS
  // ================================================================

  /// Safely converts API values to double.
  ///
  /// Backend can return:
  ///
  /// 100
  /// 100.50
  /// "100"
  /// "100.50"
  ///
  /// This prevents UI values becoming 0 when the API returns
  /// numbers as strings.
  double _toDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString().trim()) ?? 0.0;
  }

  /// Formats quantity without unnecessary decimal places.
  ///
  /// 10.0 -> 10
  /// 10.50 -> 10.50
  String _formatQuantity(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  // ================================================================
  // STATUS FILTER
  // ================================================================

  /// Returns true when a purchase order belongs to the selected
  /// filter.
  bool _matchesFilter(String status) {
    final normalized = status.trim().toUpperCase();

    switch (_filter) {
      case 'pending':
        return _pendingStatuses.contains(normalized);

      case 'complete':
        return _completeStatuses.contains(normalized);

      case 'all':
        // Cancelled POs are not shown in the normal
        // purchase history.
        return normalized != 'CANCELLED';

      case 'products':
        // Products has its own list.
        return false;

      default:
        return true;
    }
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(supplierDetailProvider(widget.supplierId));

    return ReportScaffold(
      title: widget.supplierName ?? 'Supplier Details',

      onRefresh: () async {
        ref.invalidate(supplierDetailProvider(widget.supplierId));
      },

      child: ReportAsyncView(
        value: detailAsync,

        builder: (context, detail) {
          // --------------------------------------------------------
          // DEBUG
          // --------------------------------------------------------
          //
          // These are useful while testing.
          // Once everything works, you can remove them.
          debugPrint('════════ SUPPLIER DETAILS SCREEN ════════');

          debugPrint('Supplier ID: ${widget.supplierId}');

          debugPrint('Supplier Name: ${detail.supplierName}');

          debugPrint('Products Count: ${detail.products.length}');

          debugPrint('Orders Count: ${detail.orders.length}');

          debugPrint(
            'Total Procurement: '
            '${detail.totalProcurementValue}',
          );

          debugPrint('Settled: ${detail.settledInvoices}');

          debugPrint(
            'Outstanding: '
            '${detail.outstandingBalance}',
          );

          debugPrint('════════════════════════════════════════');

          // --------------------------------------------------------
          // FILTER PURCHASE ORDERS
          // --------------------------------------------------------

          final filteredOrders = detail.orders.where((o) {
            final status = o.purchaseStatus.trim().toUpperCase();

            return _matchesFilter(status);
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ====================================================
              // SUPPLIER SUMMARY
              // ====================================================
              _buildSupplierSummary(context, detail),

              SizedBox(height: R.sp(context, AppSpacing.sm)),

              // ====================================================
              // FILTER TABS
              // ====================================================
              ReportSegmentedChips(
                options: const [
                  ReportChipOption('products', 'Products'),
                  ReportChipOption('all', 'All'),
                  ReportChipOption('pending', 'Pending'),
                  ReportChipOption('complete', 'Complete'),
                ],

                selected: _filter,

                onChanged: (value) {
                  setState(() {
                    _filter = value;
                  });
                },
              ),

              SizedBox(height: R.sp(context, AppSpacing.sm)),

              // ====================================================
              // PRODUCTS
              // ====================================================
              if (_filter == 'products')
                _buildProductsList(context, detail.products)
              // ====================================================
              // PURCHASE ORDERS
              // ====================================================
              else
                _buildOrdersList(context, filteredOrders),
            ],
          );
        },
      ),
    );
  }

  // ================================================================
  // SUPPLIER SUMMARY CARD
  // ================================================================

  Widget _buildSupplierSummary(BuildContext context, dynamic detail) {
    final supplierDisplayName = detail.supplierName.isEmpty
        ? (widget.supplierName ?? 'Supplier')
        : detail.supplierName;

    return ReportSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // --------------------------------------------------------
          // NAME + CATEGORY
          // --------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Expanded(
                child: Text(
                  supplierDisplayName,

                  style: AppTextStyles.cardValue.copyWith(
                    fontSize: R.fs(context, 15),
                    fontWeight: FontWeight.w700,
                  ),

                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 8),

              ReportBadge.auto(detail.category),
            ],
          ),

          // --------------------------------------------------------
          // PHONE
          // --------------------------------------------------------
          if (detail.phone.isNotEmpty) ...[
            SizedBox(height: R.sp(context, 2)),

            Text(
              detail.phone,

              style: AppTextStyles.small.copyWith(
                fontSize: R.fs(context, 11.5),
              ),
            ),
          ],

          SizedBox(height: R.sp(context, AppSpacing.sm)),

          const Divider(height: 1, color: AppColors.border),

          SizedBox(height: R.sp(context, AppSpacing.xs)),

          // --------------------------------------------------------
          // TOTAL PROCUREMENT
          // --------------------------------------------------------
          ReportKeyValueRow(
            label: 'Total Procurement Value',

            value: formatRupee(_toDouble(detail.totalProcurementValue)),

            bold: true,
          ),

          // --------------------------------------------------------
          // SETTLED
          // --------------------------------------------------------
          ReportKeyValueRow(
            label: 'Settled Invoices',

            value: formatRupee(_toDouble(detail.settledInvoices)),

            valueColor: AppColors.green,
          ),

          // --------------------------------------------------------
          // OUTSTANDING
          // --------------------------------------------------------
          ReportKeyValueRow(
            label: 'Balance',
            value: formatRupee(_toDouble(detail.outstandingBalance)),
            valueColor: _toDouble(detail.outstandingBalance) > 0
                ? AppColors.red
                : AppColors.textPrimaryDark,
          ),
        ],
      ),
    );
  }

  // ================================================================
  // PRODUCTS LIST
  // ================================================================

  Widget _buildProductsList(BuildContext context, List<dynamic> products) {
    // --------------------------------------------------------------
    // EMPTY STATE
    // --------------------------------------------------------------

    if (products.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: R.sp(context, 24)),

        child: Center(
          child: Text(
            'No products purchased from this supplier yet.',

            style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),

            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // --------------------------------------------------------------
    // PRODUCT CARDS
    // --------------------------------------------------------------

    return Column(
      children: products.map((product) {
        return _buildProductCard(context, product);
      }).toList(),
    );
  }

  // ================================================================
  // SINGLE PRODUCT CARD
  // ================================================================

  Widget _buildProductCard(BuildContext context, dynamic product) {
    /*
     * ProductModel/entity fields are used first.
     *
     * The values are already converted by SupplierDetailModel.
     */

    final productName = product.productName.toString();

    final purchaseCount = product.purchaseCount;

    final quantity = _toDouble(product.totalQuantity);

    final totalValue = _toDouble(product.totalValue);

    final lastUnitPrice = _toDouble(product.lastUnitPrice);

    DateTime? lastDate;

    if (product.lastPurchaseDate != null) {
      lastDate = DateTime.tryParse(product.lastPurchaseDate.toString());
    }

    return Container(
      width: double.infinity,

      margin: EdgeInsets.only(bottom: R.sp(context, AppSpacing.xs)),

      padding: EdgeInsets.all(R.sp(context, 14)),

      decoration: BoxDecoration(
        color: AppColors.card,

        borderRadius: BorderRadius.circular(10),

        border: Border.all(color: AppColors.border),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // --------------------------------------------------------
          // PRODUCT NAME + QUANTITY
          // --------------------------------------------------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Expanded(
                child: Text(
                  productName,

                  style: AppTextStyles.cardValue.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),

                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 10),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),

                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),

                  borderRadius: BorderRadius.circular(20),
                ),

                child: Text(
                  '${_formatQuantity(quantity)} Qty',

                  style: AppTextStyles.cardValue.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: R.sp(context, 12)),

          const Divider(height: 1, color: AppColors.border),

          SizedBox(height: R.sp(context, 10)),

          // --------------------------------------------------------
          // PURCHASE PRICE
          // --------------------------------------------------------
          Row(
            children: [
              Expanded(
                child: _productInfo(
                  context,
                  label: 'Purchase Price',
                  value: formatRupee(lastUnitPrice),
                ),
              ),

              // ----------------------------------------------------
              // TOTAL QUANTITY
              // ----------------------------------------------------
              Expanded(
                child: _productInfo(
                  context,
                  label: 'Quantity',
                  value: _formatQuantity(quantity),
                ),
              ),

              // ----------------------------------------------------
              // TOTAL VALUE
              // ----------------------------------------------------
              Expanded(
                child: _productInfo(
                  context,
                  label: 'Total Purchased',
                  value: formatRupee(totalValue),
                ),
              ),
            ],
          ),

          // --------------------------------------------------------
          // PURCHASE COUNT
          // --------------------------------------------------------
          if (purchaseCount > 0) ...[
            SizedBox(height: R.sp(context, 8)),

            Text(
              'Purchased in '
              '$purchaseCount '
              '${purchaseCount == 1 ? 'order' : 'orders'}',

              style: AppTextStyles.small.copyWith(
                fontSize: 10.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],

          // --------------------------------------------------------
          // LAST PURCHASE DATE
          // --------------------------------------------------------
          if (lastDate != null) ...[
            SizedBox(height: R.sp(context, 3)),

            Text(
              'Last purchase: '
              '${formatReportDate(lastDate)}',

              style: AppTextStyles.small.copyWith(
                fontSize: 10.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================================================================
  // PRODUCT INFORMATION FIELD
  // ================================================================

  Widget _productInfo(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            label,

            style: AppTextStyles.small.copyWith(
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),

            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 3),

          Text(
            value,

            style: AppTextStyles.cardValue.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),

            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ================================================================
  // PURCHASE ORDER LIST
  // ================================================================

  Widget _buildOrdersList(BuildContext context, List<dynamic> orders) {
    // --------------------------------------------------------------
    // EMPTY STATE
    // --------------------------------------------------------------

    if (orders.isEmpty) {
      String message;

      switch (_filter) {
        case 'pending':
          message = 'No pending purchase orders found.';

          break;

        case 'complete':
          message = 'No completed purchase orders found.';

          break;

        default:
          message = 'No purchase orders found.';
      }

      return Padding(
        padding: EdgeInsets.symmetric(vertical: R.sp(context, 24)),

        child: Center(
          child: Text(
            message,

            style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),

            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // --------------------------------------------------------------
    // ORDER CARDS
    // --------------------------------------------------------------

    return Column(
      children: orders.map((order) {
        return _buildPurchaseOrderCard(context, order);
      }).toList(),
    );
  }

  // ================================================================
  // SINGLE PURCHASE ORDER CARD
  // ================================================================

  Widget _buildPurchaseOrderCard(BuildContext context, dynamic order) {
    final poNumber = order.poNumber.toString();

    final purchaseDate = order.purchaseDate;

    final itemCount = order.itemCount;

    final grandTotal = _toDouble(order.grandTotal);

    final purchaseStatus = order.purchaseStatus.toString().trim().toUpperCase();

    final itemsSummary = order.itemsSummary.toString();

    return ReportListCard(
      title: poNumber,

      subtitle:
          '${formatReportDate(purchaseDate)}'
          ' • '
          '$itemCount '
          'item${itemCount == 1 ? '' : 's'}'
          '${itemsSummary.isNotEmpty ? '\n$itemsSummary' : ''}',

      trailingTop: formatRupee(grandTotal),

      trailingBottom: '__badge__$purchaseStatus',

      onTap: () {
        if (poNumber.isEmpty) {
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PoDetailsScreen(poNumber: poNumber),
          ),
        );
      },
    );
  }
}
