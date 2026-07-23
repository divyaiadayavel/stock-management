// =========================================================
// lib/features/inventory/presentation/screens/low_stock_screen.dart
// =========================================================
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/utils/responsive_helper.dart';

import '../../../products/data/models/product_model.dart';
import '../providers/inventory_filter_provider.dart';
import '../providers/inventory_provider.dart';

class LowStockScreen extends ConsumerWidget {
  const LowStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🌐 Live Riverpod provider connected to PHP inventory.php?action=low_stock
    final lowStockAsync = ref.watch(lowStockProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimaryDark,
            size: R.icon(context, AppSizes.iconLg),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Low stock', style: AppTextStyles.heading),
      ),
      body: lowStockAsync.when(
        data: (products) {
          // Dynamic calculation of total restock value from PHP backend data
          final totalRestockValue = products.fold<double>(
            0.0,
            (sum, p) {
              final needed = (p.lsl * 2 - p.quantity).clamp(1, 100000);
              return sum + (needed * p.purchasePrice);
            },
          );

          return Column(
            children: [
              // ── Header Summary Card ──
              Padding(
                padding: EdgeInsets.fromLTRB(
                  R.sp(context, AppSpacing.screenPadding),
                  R.sp(context, AppSpacing.sm),
                  R.sp(context, AppSpacing.screenPadding),
                  0,
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(
                    R.sp(context, AppSpacing.cardPadding),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(
                      R.radius(context, AppSizes.radiusLg),
                    ),
                    border: Border.all(
                      color: AppColors.red.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${products.length} items need reordering',
                        style: AppTextStyles.sectionTitle.copyWith(
                          color: AppColors.red,
                          fontSize: R.fs(context, 18),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: R.sp(context, 4)),
                      Text(
                        'est. ₹${_formatCompact(totalRestockValue)} to restock',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.textPrimaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: R.sp(context, AppSpacing.md)),

              // ── Low Stock Products List ──
              Expanded(
                child: products.isEmpty
                    ? Center(
                        child: Text(
                          'Nothing is low on stock 🎉',
                          style: AppTextStyles.subHeading,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.read(inventoryRefreshProvider.notifier).state++;
                        },
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            R.sp(context, AppSpacing.screenPadding),
                            0,
                            R.sp(context, AppSpacing.screenPadding),
                            R.sp(context, 100),
                          ),
                          itemCount: products.length,
                          separatorBuilder: (_, _) =>
                              SizedBox(height: R.sp(context, AppSpacing.sm)),
                          itemBuilder: (context, i) =>
                              _LowStockTile(product: products[i]),
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Text('Error loading low stock: $e',
              style: AppTextStyles.small),
        ),
      ),

      // ── Bottom Navigation Bar: Bulk Create POs Grouped by Supplier ──
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.all(R.sp(context, AppSpacing.screenPadding)),
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SizedBox(
            width: double.infinity,
            height: R.sp(context, AppSizes.buttonHeight),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(
                  R.radius(context, AppSizes.radiusMd),
                ),
              ),
              child: ElevatedButton(
                onPressed: () {
                  final products = lowStockAsync.value;
                  if (products == null || products.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No low stock items available to reorder.'),
                      ),
                    );
                    return;
                  }
                  _createGroupedPurchaseOrders(context, ref, products);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      R.radius(context, AppSizes.radiusMd),
                    ),
                  ),
                ),
                child: Text(
                  'Create all POs · grouped by supplier',
                  style: AppTextStyles.button.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatCompact(double value) {
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}

// =========================================================
// Item Tile Widget with Individual Create PO Button
// =========================================================
class _LowStockTile extends ConsumerWidget {
  final Product product;
  const _LowStockTile({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = product.quantity;
    final lsl = product.lsl;
    final suggested = (lsl * 2 - qty).clamp(1, 100000);
    final unit = product.unit.isNotEmpty ? product.unit : 'unit';
    final supplier = product.supplier.isNotEmpty ? product.supplier : 'Unassigned';
    final isOut = qty <= 0;

    return Container(
      padding: EdgeInsets.all(R.sp(context, AppSpacing.cardPadding)),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(
          R.radius(context, AppSizes.cardRadius),
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        product.name,
                        style: AppTextStyles.cardValue.copyWith(
                          fontSize: R.fs(context, 14),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: R.sp(context, AppSpacing.xs)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: R.sp(context, 6),
                        vertical: R.sp(context, 2),
                      ),
                      decoration: BoxDecoration(
                        color: (isOut ? AppColors.red : AppColors.orange)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          R.radius(context, AppSizes.radiusSm),
                        ),
                      ),
                      child: Text(
                        isOut ? 'Out' : 'Low',
                        style: AppTextStyles.small.copyWith(
                          color: isOut ? AppColors.red : AppColors.orange,
                          fontSize: R.fs(context, 10),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: R.sp(context, 4)),
                Text(
                  '$qty on hand · reorder $lsl · supplier $supplier',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: R.sp(context, 4)),
                Text(
                  'Suggested $suggested $unit',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: R.sp(context, AppSpacing.sm)),
          ElevatedButton(
            onPressed: () => _createPoForProduct(context, ref, product),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(
                horizontal: R.sp(context, 12),
                vertical: R.sp(context, 8),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  R.radius(context, AppSizes.radiusMd),
                ),
              ),
            ),
            child: Text(
              'Create PO ›',
              style: AppTextStyles.small.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// 1. Quick Single-Product PO Modal & Backend Integration
// =========================================================
Future<void> _createPoForProduct(
  BuildContext context,
  WidgetRef ref,
  Product product,
) async {
  if (product.supplierId == null || product.supplierId == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'No supplier assigned for "${product.name}". Assign a supplier in product settings.',
        ),
      ),
    );
    return;
  }

  // 🌐 Fetch Supplier details dynamically from suppliers.php API endpoint
  Map<String, dynamic>? supplierData;
  try {
    final supplierUri = Uri.parse(
        ApiConfig.inventory.replaceAll('/inventory/inventory.php', '/suppliers/suppliers.php?id=${product.supplierId}'));
    final response = await http.get(supplierUri, headers: ApiConfig.jsonHeaders);
    if (response.statusCode == 200) {
      final jsonRes = json.decode(response.body);
      if (jsonRes['success'] == true && jsonRes['data'] != null) {
        supplierData = jsonRes['data'];
      }
    }
  } catch (e) {
    debugPrint('Error fetching supplier details: $e');
  }

  final supplierName = supplierData?['supplier_name'] ??
      supplierData?['company_name'] ??
      product.supplier;
  final supplierPhone = supplierData?['phone'] ??
      supplierData?['alternate_phone'] ??
      '';

  final qty = product.quantity;
  final lsl = product.lsl;
  final suggestedQty = (lsl * 2 - qty).clamp(1, 100000);
  final defaultPrice = product.purchasePrice > 0
      ? product.purchasePrice
      : product.sellingPrice;

  final qtyCtrl = TextEditingController(text: suggestedQty.toString());
  final priceCtrl = TextEditingController(
    text: defaultPrice > 0 ? defaultPrice.toStringAsFixed(2) : '0.00',
  );

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
      bool sending = false;
      return StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: R.sp(sheetCtx, 18),
              right: R.sp(sheetCtx, 18),
              top: R.sp(sheetCtx, 18),
              bottom:
                  MediaQuery.of(sheetCtx).viewInsets.bottom +
                  R.sp(sheetCtx, 18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick purchase order',
                  style: TextStyle(
                    fontSize: R.fs(sheetCtx, 16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                SizedBox(height: R.sp(sheetCtx, 14)),

                _readOnlyField(sheetCtx, 'Supplier', supplierName),
                SizedBox(height: R.sp(sheetCtx, 10)),
                _readOnlyField(sheetCtx, 'Product', product.name),
                SizedBox(height: R.sp(sheetCtx, 10)),
                _readOnlyField(
                    sheetCtx, 'Unit', product.unit.isNotEmpty ? product.unit : 'unit'),
                SizedBox(height: R.sp(sheetCtx, 10)),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Qty'),
                      ),
                    ),
                    SizedBox(width: R.sp(sheetCtx, 10)),
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Unit price (₹)',
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: R.sp(sheetCtx, 18)),

                SizedBox(
                  width: double.infinity,
                  height: R.btnH(sheetCtx),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(
                        R.radius(sheetCtx, 10),
                      ),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: sending
                          ? null
                          : () async {
                              final qtyVal = int.tryParse(qtyCtrl.text.trim());
                              final priceVal =
                                  double.tryParse(priceCtrl.text.trim());

                              if (qtyVal == null || qtyVal <= 0) {
                                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Enter a valid quantity'),
                                  ),
                                );
                                return;
                              }
                              if (priceVal == null || priceVal < 0) {
                                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Enter a valid unit price'),
                                  ),
                                );
                                return;
                              }

                              setSheetState(() => sending = true);

                              try {
                                final poPayload = {
                                  'supplier_id': product.supplierId,
                                  'purchase_date':
                                      DateFormat('yyyy-MM-dd').format(DateTime.now()),
                                  'items': [
                                    {
                                      'product_id': product.id,
                                      'quantity': qtyVal,
                                      'purchase_price': priceVal,
                                      'tax': 0,
                                      'discount': 0
                                    }
                                  ]
                                };

                                final createPoUri = Uri.parse(
                                    '${ApiConfig.inventory}?action=create_purchase');
                                final response = await http.post(
                                  createPoUri,
                                  headers: ApiConfig.jsonHeaders,
                                  body: json.encode(poPayload),
                                );

                                final resData = json.decode(response.body);

                                if (response.statusCode == 200 &&
                                    resData['success'] == true) {
                                  final poId = resData['data']?['purchase_id'] ?? 0;

                                  // Refresh inventory providers
                                  ref
                                      .read(inventoryRefreshProvider.notifier)
                                      .state++;

                                  if (supplierPhone.trim().isNotEmpty) {
                                    await _sendPoWhatsApp(
                                      supplierName: supplierName,
                                      phone: supplierPhone,
                                      poId: poId is int
                                          ? poId
                                          : int.tryParse(poId.toString()) ?? 0,
                                      productName: product.name,
                                      unit: product.unit,
                                      qty: qtyVal,
                                      unitPrice: priceVal,
                                    );
                                  }

                                  setSheetState(() => sending = false);

                                  if (sheetCtx.mounted) {
                                    Navigator.pop(sheetCtx);
                                  }
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'PO created for $supplierName!',
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  throw Exception(
                                      resData['message'] ?? 'Failed to create PO');
                                }
                              } catch (err) {
                                setSheetState(() => sending = false);
                                if (sheetCtx.mounted) {
                                  ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                    SnackBar(
                                      content: Text('Backend error: $err'),
                                    ),
                                  );
                                }
                              }
                            },
                      icon: sending
                          ? SizedBox(
                              width: R.sp(sheetCtx, 16),
                              height: R.sp(sheetCtx, 16),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              Icons.chat,
                              color: Colors.white,
                              size: R.icon(sheetCtx, 18),
                            ),
                      label: Text(
                        'Send PO to supplier',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: R.fs(sheetCtx, 14),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            R.radius(sheetCtx, 10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

// =========================================================
// 2. Bulk Create POs Grouped by Supplier Flow
// =========================================================
Future<void> _createGroupedPurchaseOrders(
  BuildContext context,
  WidgetRef ref,
  List<Product> products,
) async {
  // Group low stock products by supplierId
  final Map<int, List<Product>> grouped = {};
  final List<Product> unassigned = [];

  for (final p in products) {
    if (p.supplierId != null && p.supplierId! > 0) {
      grouped.putIfAbsent(p.supplierId!, () => []).add(p);
    } else {
      unassigned.add(p);
    }
  }

  if (grouped.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'None of the low-stock items have a supplier assigned. Please assign suppliers to products first.',
        ),
      ),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
      bool creating = false;

      return StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (_, scrollController) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: R.sp(sheetCtx, 18),
                  vertical: R.sp(sheetCtx, 16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: R.sp(sheetCtx, 40),
                        height: R.sp(sheetCtx, 4),
                        margin: EdgeInsets.only(bottom: R.sp(sheetCtx, 12)),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Text(
                      'Bulk Create Purchase Orders',
                      style: TextStyle(
                        fontSize: R.fs(sheetCtx, 16),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    SizedBox(height: R.sp(sheetCtx, 4)),
                    Text(
                      'Creating ${grouped.keys.length} purchase orders grouped by supplier.',
                      style: TextStyle(
                        fontSize: R.fs(sheetCtx, 12),
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (unassigned.isNotEmpty) ...[
                      SizedBox(height: R.sp(sheetCtx, 8)),
                      Text(
                        '⚠️ ${unassigned.length} items have no supplier assigned and will be skipped.',
                        style: TextStyle(
                          fontSize: R.fs(sheetCtx, 11),
                          color: AppColors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    SizedBox(height: R.sp(sheetCtx, 14)),

                    // Grouped Suppliers List
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: grouped.keys.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: R.sp(sheetCtx, 12)),
                        itemBuilder: (_, index) {
                          final supplierId = grouped.keys.elementAt(index);
                          final supplierItems = grouped[supplierId]!;
                          final supplierName = supplierItems.first.supplier.isNotEmpty
                              ? supplierItems.first.supplier
                              : 'Supplier #$supplierId';

                          final groupTotal = supplierItems.fold<double>(
                            0.0,
                            (sum, p) {
                              final qty = (p.lsl * 2 - p.quantity).clamp(1, 100000);
                              final price = p.purchasePrice > 0
                                  ? p.purchasePrice
                                  : p.sellingPrice;
                              return sum + (qty * price);
                            },
                          );

                          return Container(
                            padding: EdgeInsets.all(R.sp(sheetCtx, 12)),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(
                                R.radius(sheetCtx, 10),
                              ),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        supplierName,
                                        style: TextStyle(
                                          fontSize: R.fs(sheetCtx, 14),
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimaryDark,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '₹${groupTotal.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: R.fs(sheetCtx, 13),
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(height: R.sp(sheetCtx, 16)),
                                ...supplierItems.map((p) {
                                  final qty = (p.lsl * 2 - p.quantity)
                                      .clamp(1, 100000);
                                  final price = p.purchasePrice > 0
                                      ? p.purchasePrice
                                      : p.sellingPrice;
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: R.sp(sheetCtx, 4),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '• ${p.name}',
                                            style: TextStyle(
                                              fontSize: R.fs(sheetCtx, 12),
                                              color: AppColors.textPrimaryDark,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '$qty ${p.unit.isNotEmpty ? p.unit : 'unit'} × ₹${price.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: R.fs(sheetCtx, 11),
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: R.sp(sheetCtx, 14)),

                    // Batch Creation Action Button
                    SizedBox(
                      width: double.infinity,
                      height: R.btnH(sheetCtx),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(
                            R.radius(sheetCtx, 10),
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: creating
                              ? null
                              : () async {
                                  setSheetState(() => creating = true);
                                  int successCount = 0;

                                  for (final supplierId in grouped.keys) {
                                    final supplierItems = grouped[supplierId]!;
                                    final itemsPayload = supplierItems.map((p) {
                                      final qty = (p.lsl * 2 - p.quantity)
                                          .clamp(1, 100000);
                                      final price = p.purchasePrice > 0
                                          ? p.purchasePrice
                                          : p.sellingPrice;
                                      return {
                                        'product_id': p.id,
                                        'quantity': qty,
                                        'purchase_price': price,
                                        'tax': 0,
                                        'discount': 0,
                                      };
                                    }).toList();

                                    final payload = {
                                      'supplier_id': supplierId,
                                      'purchase_date': DateFormat('yyyy-MM-dd')
                                          .format(DateTime.now()),
                                      'items': itemsPayload,
                                    };

                                    try {
                                      final uri = Uri.parse(
                                          '${ApiConfig.inventory}?action=create_purchase');
                                      final response = await http.post(
                                        uri,
                                        headers: ApiConfig.jsonHeaders,
                                        body: json.encode(payload),
                                      );
                                      final res = json.decode(response.body);
                                      if (response.statusCode == 200 &&
                                          res['success'] == true) {
                                        successCount++;
                                      }
                                    } catch (e) {
                                      debugPrint(
                                          'Failed to create PO for supplier $supplierId: $e');
                                    }
                                  }

                                  // Refresh global state
                                  ref
                                      .read(inventoryRefreshProvider.notifier)
                                      .state++;

                                  setSheetState(() => creating = false);

                                  if (sheetCtx.mounted) {
                                    Navigator.pop(sheetCtx);
                                  }
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Successfully created $successCount purchase order(s) in backend!',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                R.radius(sheetCtx, 10),
                              ),
                            ),
                          ),
                          child: creating
                              ? SizedBox(
                                  width: R.sp(sheetCtx, 20),
                                  height: R.sp(sheetCtx, 20),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Confirm & Create ${grouped.keys.length} Purchase Orders',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: R.fs(sheetCtx, 14),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

Widget _readOnlyField(BuildContext context, String label, String value) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(
      horizontal: R.sp(context, 14),
      vertical: R.sp(context, 12),
    ),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F3F5),
      borderRadius: BorderRadius.circular(R.radius(context, 10)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: R.fs(context, 11),
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: R.sp(context, 2)),
        Text(
          value,
          style: TextStyle(
            fontSize: R.fs(context, 14),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ],
    ),
  );
}

/// Dual-launch WhatsApp strategy (whatsapp:// with wa.me web fallback)
Future<bool> _sendPoWhatsApp({
  required String supplierName,
  required String phone,
  required int poId,
  required String productName,
  required String unit,
  required int qty,
  required double unitPrice,
}) async {
  var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length == 10) digits = '91$digits';
  final poNumber = 'PO-${poId.toString().padLeft(4, '0')}';
  final total = qty * unitPrice;
  final expectedDelivery = DateTime.now().add(const Duration(days: 3));

  final textMessage =
      'Hi $supplierName, sending our purchase order $poNumber:\n\n'
      '• $productName — $qty ${unit.isNotEmpty ? unit : 'unit'} × ₹${unitPrice.toStringAsFixed(0)}\n\n'
      'Total (incl GST): ₹${total.toStringAsFixed(0)}\n'
      'Expected delivery: ${DateFormat('d MMM').format(expectedDelivery)}\n\n'
      'Please confirm. Thank you!';

  final encodedMessage = Uri.encodeComponent(textMessage);

  final Uri appUri = Uri.parse(
    'whatsapp://send?phone=$digits&text=$encodedMessage',
  );
  final Uri webUri = Uri.parse('https://wa.me/$digits?text=$encodedMessage');

  try {
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
      return true;
    } else if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  } catch (e) {
    return false;
  }
}