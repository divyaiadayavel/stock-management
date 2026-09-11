// =========================================================
// lib/features/inventory/presentation/screens/low_stock_screen.dart
// =========================================================
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/no_internet_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/utils/responsive_helper.dart';

import '../../../products/data/models/product_model.dart';
import '../../../inventory/presentation/screens/new_purchase_order_screen.dart';
import '../providers/inventory_filter_provider.dart';
import '../providers/inventory_provider.dart';
import 'receive_order_screen.dart';

/// Helper to capitalize the first letter of every word
String _capitalize(String text) {
  if (text.isEmpty) return text;
  return text
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      })
      .join(' ');
}

class LowStockScreen extends ConsumerStatefulWidget {
  const LowStockScreen({super.key});

  @override
  ConsumerState<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends ConsumerState<LowStockScreen> {
  // ── Keeps track of product IDs that have already had POs created in this session ──
  final Set<String> _createdPoProductIds = {};

  void _markPoAsCreated(dynamic productId) {
    if (productId != null) {
      setState(() {
        _createdPoProductIds.add(productId.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌐 Live Riverpod provider connected to PHP inventory.php?action=low_stock
    final lowStockAsync = ref.watch(lowStockProductsProvider);
    if (lowStockAsync.hasError) {
  return Scaffold(
    body: NoInternetScreen(
      onRetry: () {
        ref.invalidate(lowStockProductsProvider);
      },
    ),
  );
}

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
          final totalRestockValue = products.fold<double>(0.0, (sum, p) {
            final needed = (p.lsl * 2 - p.quantity).clamp(1, 100000);
            return sum + (needed * p.purchasePrice);
          });

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
                          itemBuilder: (context, i) {
                            final product = products[i];
                            final isCreated = _createdPoProductIds.contains(
                              product.id.toString(),
                            );

                            return _LowStockTile(
                              product: product,
                              isAlreadyCreated: isCreated,
                              onPoCreatedSuccess: () {
                                _markPoAsCreated(product.id);
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
error: (e, st) => const SizedBox.shrink(),
      ),

      // ── Bottom Navigation Bar: Navigate Directly to Purchases Screen ──
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NewPurchaseOrderScreen(),
                    ),
                  );
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
// Item Tile Widget with Individual Gradient Create PO Button
// =========================================================
class _LowStockTile extends ConsumerWidget {
  final Product product;
  final bool isAlreadyCreated;
  final VoidCallback onPoCreatedSuccess;

  const _LowStockTile({
    required this.product,
    required this.isAlreadyCreated,
    required this.onPoCreatedSuccess,
  });

  void _showAlreadyCreatedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              R.radius(dialogCtx, AppSizes.radiusLg),
            ),
          ),
          title: Text(
            'PO Already Sent',
            style: AppTextStyles.heading.copyWith(
              fontSize: R.fs(dialogCtx, 16),
            ),
          ),
          content: Text(
            'A Purchase Order for "${_capitalize(product.name)}" has already been created.\n\nPlease check in the "Receive Orders" section to manage or track this PO.',
            style: AppTextStyles.small.copyWith(
              color: AppColors.textSecondary,
              fontSize: R.fs(dialogCtx, 13),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                'Go back',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: R.fs(dialogCtx, 14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = product.quantity;
    final lsl = product.lsl;
    final suggested = (lsl * 2 - qty).clamp(1, 100000);
    final unit = product.unit.isNotEmpty ? product.unit : 'unit';
    final supplier = product.supplier.isNotEmpty
        ? _capitalize(product.supplier)
        : 'Unassigned';
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
                        _capitalize(product.name),
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
          Container(
            decoration: BoxDecoration(
              gradient: isAlreadyCreated ? null : AppColors.brandGradient,
              color: isAlreadyCreated ? Colors.grey.shade400 : null,
              borderRadius: BorderRadius.circular(
                R.radius(context, AppSizes.radiusMd),
              ),
            ),
            child: ElevatedButton(
              onPressed: () {
                if (isAlreadyCreated) {
                  _showAlreadyCreatedDialog(context);
                } else {
                  _createPoForProduct(
                    context,
                    ref,
                    product,
                    onSuccess: onPoCreatedSuccess,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
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
                isAlreadyCreated ? 'PO Created' : 'Create PO ›',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w600,
                ),
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
  Product product, {
  required VoidCallback onSuccess,
}) async {
  if (product.supplierId == null || product.supplierId == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'No supplier assigned for "${_capitalize(product.name)}". Assign a supplier in product settings.',
        ),
      ),
    );
    return;
  }

  // 🌐 Fetch Supplier details dynamically from suppliers API endpoint
  Map<String, dynamic>? supplierData;
  try {
    final supplierUri = Uri.parse(
      ApiConfig.inventory.replaceAll(
        '/inventory/inventory.php',
        '/suppliers/suppliers.php?id=${product.supplierId}',
      ),
    );
    final response = await http.get(
      supplierUri,
      headers: ApiConfig.jsonHeaders,
    );
    if (response.statusCode == 200) {
      final jsonRes = json.decode(response.body);
      if (jsonRes['success'] == true && jsonRes['data'] != null) {
        supplierData = jsonRes['data'];
      }
    }
  } catch (e) {
    debugPrint('Error fetching supplier details: $e');
  }

  final supplierName = _capitalize(
    supplierData?['supplier_name'] ??
        supplierData?['company_name'] ??
        product.supplier,
  );
  final supplierPhone =
      supplierData?['phone'] ?? supplierData?['alternate_phone'] ?? '';

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
                _readOnlyField(sheetCtx, 'Product', _capitalize(product.name)),
                SizedBox(height: R.sp(sheetCtx, 10)),
                _readOnlyField(
                  sheetCtx,
                  'Unit',
                  product.unit.isNotEmpty ? product.unit : 'unit',
                ),
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
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
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
                              final priceVal = double.tryParse(
                                priceCtrl.text.trim(),
                              );

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
                                // Safely convert product.id to integer
                                final int parsedProductId =
                                    int.tryParse(product.id.toString()) ?? 0;

                                final poPayload = {
                                  'supplier_id': product.supplierId,
                                  'purchase_date': DateFormat(
                                    'yyyy-MM-dd HH:mm:ss',
                                  ).format(DateTime.now()),
                                  'status': 'ORDERED',
                                  'items': [
                                    {
                                      'product_id': parsedProductId > 0
                                          ? parsedProductId
                                          : product.id,
                                      'quantity': qtyVal,
                                      'purchase_price': priceVal,
                                      'tax': 0,
                                      'discount': 0,
                                    },
                                  ],
                                };

                                final createPoUri = Uri.parse(
                                  '${ApiConfig.purchases}?action=create_purchase',
                                );
                                final response = await http.post(
                                  createPoUri,
                                  headers: ApiConfig.jsonHeaders,
                                  body: json.encode(poPayload),
                                );

                                final resData = json.decode(response.body);

                                if (response.statusCode == 200 &&
                                    resData['success'] == true) {
                                  final rawPoId =
                                      resData['data']?['purchase_id'] ?? 0;
                                  final int createdPoId = rawPoId is int
                                      ? rawPoId
                                      : int.tryParse(rawPoId.toString()) ?? 0;

                                  // Callback to disable the button locally
                                  onSuccess();

                                  // Refresh inventory providers
                                  ref
                                      .read(inventoryRefreshProvider.notifier)
                                      .state++;

                                  if (supplierPhone.trim().isNotEmpty) {
                                    await _sendPoWhatsApp(
                                      supplierName: supplierName,
                                      phone: supplierPhone,
                                      poId: createdPoId,
                                      productName: _capitalize(product.name),
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
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ReceiveOrderScreen(
                                          poId: createdPoId > 0
                                              ? createdPoId
                                              : null,
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  throw Exception(
                                    resData['message'] ?? 'Failed to create PO',
                                  );
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
