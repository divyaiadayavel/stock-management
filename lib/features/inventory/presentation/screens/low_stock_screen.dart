// =========================================================
// lib/screens/low_stock_screen.dart
// =========================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/storage/db_helper.dart';
import '../../../../core/utils/responsive_helper.dart';

import '../providers/inventory_providers.dart';
import 'new_purchase_order_screen.dart';

class LowStockScreen extends ConsumerWidget {
  const LowStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStockAsync = ref.watch(lowStockListProvider);
    final restockValueAsync = ref.watch(lowStockRestockValueProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textPrimaryDark,
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [Text('Low stock', style: AppTextStyles.heading)]),
      ),
      body: lowStockAsync.when(
        data: (products) {
          return Column(
            children: [
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
                    color: AppColors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(
                      R.radius(context, AppSizes.radiusLg),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${products.length} items need reordering',
                        style: AppTextStyles.sectionTitle.copyWith(
                          color: AppColors.red,
                          fontSize: R.fs(
                            context,
                            18,
                          ), // Mapped to font size helper
                        ),
                      ),
                      SizedBox(height: R.sp(context, 4)),
                      restockValueAsync.when(
                        data: (value) => Text(
                          'est. ₹${_formatCompact(value)} to restock',
                          style: AppTextStyles.small.copyWith(
                            color: Colors.black,
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: R.sp(context, AppSpacing.md)),
              Expanded(
                child: products.isEmpty
                    ? Center(
                        child: Text(
                          'Nothing is low on stock 🎉',
                          style: AppTextStyles.subHeading,
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          R.sp(context, AppSpacing.screenPadding),
                          0,
                          R.sp(context, AppSpacing.screenPadding),
                          R.sp(context, 100),
                        ),
                        itemCount: products.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: R.sp(context, AppSpacing.sm)),
                        itemBuilder: (context, i) =>
                            _LowStockTile(product: products[i]),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) =>
            Center(child: Text('Error: $e', style: AppTextStyles.small)),
      ),
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

class _LowStockTile extends StatelessWidget {
  final Map<String, dynamic> product;
  const _LowStockTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final qty = (product['quantity'] as num?)?.toInt() ?? 0;
    final lsl = (product['lsl'] as num?)?.toInt() ?? 0;
    final suggested = (product['suggestedQty'] as num?)?.toInt() ?? lsl;
    final unit = product['unit']?.toString() ?? '';
    final supplier = product['supplier']?.toString() ?? 'Unassigned';
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
                        product['name']?.toString() ?? '',
                        style: AppTextStyles.cardValue.copyWith(
                          fontSize: R.fs(
                            context,
                            14,
                          ), // Mapped to font size helper
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
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(
                          R.radius(context, AppSizes.radiusSm),
                        ),
                      ),
                      child: Text(
                        isOut ? 'Out' : 'Low',
                        style: AppTextStyles.small.copyWith(
                          color: isOut ? AppColors.red : AppColors.orange,
                          fontSize: R.fs(
                            context,
                            10,
                          ), // Mapped to font size helper
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: R.sp(context, 4)),
                Text(
                  '$qty on hand · reorder $lsl · supplier $supplier',
                  style: AppTextStyles.small,
                ),
                SizedBox(height: R.sp(context, 4)),
                Text(
                  'Suggested ${suggested > 0 ? suggested : lsl} $unit',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: R.sp(context, AppSpacing.sm)),
          ElevatedButton(
            onPressed: () => _createPoForProduct(context, product),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(
                horizontal: R.sp(context, 14),
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
              style: AppTextStyles.small.copyWith(color: AppColors.textWhite),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// Quick single-product PO flow
// -----------------------------------------------------------
// Opens a bottom sheet pre-filled with the supplier, product name
// and unit already known from the low-stock card. Only quantity
// and price need to be entered. "Send PO to supplier" creates the
// PO and fires the same WhatsApp dual-launch flow used in
// NewPurchaseOrderScreen.
// =========================================================

Future<void> _createPoForProduct(
  BuildContext context,
  Map<String, dynamic> product,
) async {
  final suppliers = await DBHelper.getSuppliersList();
  final supplierName = (product['supplier'] ?? '').toString().trim();

  Map<String, dynamic>? supplier;
  for (final s in suppliers) {
    if ((s['supplierName']?.toString() ?? '').trim().toLowerCase() ==
        supplierName.toLowerCase()) {
      supplier = s;
      break;
    }
  }

  if (supplier == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No supplier record found for "$supplierName". Add this supplier first.',
          ),
        ),
      );
    }
    return;
  }

  final qty = (product['quantity'] as num?)?.toInt() ?? 0;
  final lsl = (product['lsl'] as num?)?.toInt() ?? 0;
  final suggestedQty =
      ((product['suggestedQty'] as num?)?.toInt() ?? (lsl * 2 - qty)).clamp(
        1,
        100000,
      );
  final defaultPrice =
      (product['purchase_price'] as num?)?.toDouble() ??
      (product['selling_price'] as num?)?.toDouble() ??
      0.0;

  final qtyCtrl = TextEditingController(text: suggestedQty.toString());
  final priceCtrl = TextEditingController(
    text: defaultPrice > 0 ? defaultPrice.toStringAsFixed(0) : '',
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

                _readOnlyField(
                  sheetCtx,
                  'Supplier',
                  supplier!['supplierName']?.toString() ?? '',
                ),
                SizedBox(height: R.sp(sheetCtx, 10)),
                _readOnlyField(
                  sheetCtx,
                  'Product',
                  product['name']?.toString() ?? '',
                ),
                SizedBox(height: R.sp(sheetCtx, 10)),
                _readOnlyField(
                  sheetCtx,
                  'Unit',
                  product['unit']?.toString() ?? '',
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
                        keyboardType: TextInputType.number,
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

                              final phone = (supplier!['contactNumber'] ?? '')
                                  .toString();
                              if (phone.trim().isEmpty) {
                                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'This supplier has no phone number saved.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setSheetState(() => sending = true);

                              final item = {
                                'productId': product['id'],
                                'name': product['name'],
                                'unit': product['unit'] ?? 'unit',
                                'qty': qtyVal,
                                'unitPrice': priceVal,
                              };

                              final expectedDelivery = DateTime.now().add(
                                const Duration(days: 3),
                              );

                              final poId = await DBHelper.createPurchaseOrder(
                                supplierId: supplier!['id'],
                                items: [item],
                                expectedDelivery: expectedDelivery,
                                status: 'sent',
                              );

                              await _sendPoWhatsApp(
                                supplierName:
                                    supplier!['supplierName']?.toString() ?? '',
                                phone: phone,
                                poId: poId,
                                items: [item],
                                expectedDelivery: expectedDelivery,
                              );

                              setSheetState(() => sending = false);

                              if (sheetCtx.mounted) {
                                Navigator.pop(sheetCtx);
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'PO sent to ${supplier!['supplierName']}',
                                    ),
                                  ),
                                );
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

/// Same dual-launch WhatsApp strategy (whatsapp:// with wa.me fallback)
/// used in NewPurchaseOrderScreen, adapted for a single-item quick PO.
Future<bool> _sendPoWhatsApp({
  required String supplierName,
  required String phone,
  required int poId,
  required List<Map<String, dynamic>> items,
  required DateTime expectedDelivery,
}) async {
  var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length == 10) digits = '91$digits'; // default India code
  final poNumber = 'PO-${poId.toString().padLeft(4, '0')}';

  final total = items.fold(
    0.0,
    (sum, i) => sum + ((i['qty'] as num) * (i['unitPrice'] as num)),
  );

  final lines = items
      .map(
        (i) =>
            '• ${i['name']} — ${i['qty']} ${i['unit']} × ₹${(i['unitPrice'] as num).toStringAsFixed(0)}',
      )
      .join('\n');

  final textMessage =
      'Hi $supplierName, sending our purchase order $poNumber:\n\n'
      '$lines\n\n'
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
