// =========================================================
// lib/features/inventory/presentation/screens/new_purchase_order_screen.dart
// =========================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/db_helper.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../suppliers/presentation/screens/suppliers_screen.dart';

class NewPurchaseOrderScreen extends ConsumerStatefulWidget {
  const NewPurchaseOrderScreen({super.key});

  @override
  ConsumerState<NewPurchaseOrderScreen> createState() =>
      _NewPurchaseOrderScreenState();
}

class _NewPurchaseOrderScreenState
    extends ConsumerState<NewPurchaseOrderScreen> {
  Map<String, dynamic>? _selectedSupplier;
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _items = [];

  DateTime _expectedDelivery = DateTime.now().add(const Duration(days: 3));
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _loading = true);
    final suppliersData = await DBHelper.getSuppliers();
    setState(() {
      _suppliers = suppliersData;
      _loading = false;
    });
  }

  double get _total => _items.fold(
    0.0,
    (sum, item) => sum + ((item['qty'] as num) * (item['unitPrice'] as num)),
  );

  Future<void> _openItemPicker(Map<String, dynamic> supplier) async {
    setState(() => _loading = true);
    final allProducts = await DBHelper.getAllProducts();
    setState(() => _loading = false);

    final supplierName = (supplier['supplierName'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    final supplierProducts = allProducts
        .where(
          (p) =>
              (p['supplier'] ?? '').toString().trim().toLowerCase() ==
              supplierName,
        )
        .toList();

    if (supplierProducts.isEmpty) {
      _showError(
        'No products found under ${supplier['supplierName']}. Add products with this supplier first.',
      );
      return;
    }

    final Map<int, bool> selectedMap = {};
    final Map<int, TextEditingController> qtyCtrls = {};
    final Map<int, TextEditingController> priceCtrls = {};

    for (final p in supplierProducts) {
      final id = p['id'] as int;
      final qty = (p['quantity'] as num?)?.toInt() ?? 0;
      final lsl = (p['lsl'] as num?)?.toInt() ?? 0;
      final isLowOrOut = qty <= lsl;
      selectedMap[id] = isLowOrOut;
      final suggested = isLowOrOut ? (lsl * 2 - qty).clamp(1, 100000) : 1;
      qtyCtrls[id] = TextEditingController(text: suggested.toString());

      final defaultPrice =
          (p['purchase_price'] as num?)?.toDouble() ??
          (p['selling_price'] as num?)?.toDouble() ??
          0.0;
      priceCtrls[id] = TextEditingController(
        text: defaultPrice.toStringAsFixed(2),
      );
    }

    String filter = 'all';

    if (!mounted) return;

    final result = await showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filtered = supplierProducts.where((p) {
              final qty = (p['quantity'] as num?)?.toInt() ?? 0;
              final lsl = (p['lsl'] as num?)?.toInt() ?? 0;
              if (filter == 'low') return qty > 0 && qty <= lsl;
              if (filter == 'out') return qty <= 0;
              return true;
            }).toList();

            final selectedCount = selectedMap.values.where((v) => v).length;

            double runningTotal = 0;
            for (final p in supplierProducts) {
              final id = p['id'] as int;
              if (selectedMap[id] == true) {
                final q = int.tryParse(qtyCtrls[id]!.text.trim()) ?? 0;
                final pr = double.tryParse(priceCtrls[id]!.text.trim()) ?? 0;
                runningTotal += q * pr;
              }
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (ctx, scrollController) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: R.sp(ctx, 18),
                    right: R.sp(ctx, 18),
                    top: R.sp(ctx, 14),
                    bottom:
                        MediaQuery.of(ctx).viewInsets.bottom + R.sp(ctx, 14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: R.sp(ctx, 40),
                          height: R.sp(ctx, 4),
                          margin: EdgeInsets.only(bottom: R.sp(ctx, 12)),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Text(
                        'Select items · ${supplier['supplierName']}',
                        style: TextStyle(
                          fontSize: R.fs(ctx, 16),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      SizedBox(height: R.sp(ctx, 4)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$selectedCount selected',
                            style: TextStyle(
                              fontSize: R.fs(ctx, 12),
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '₹${runningTotal.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: R.fs(ctx, 13),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: R.sp(ctx, 12)),

                      Row(
                        children: [
                          _filterChip(
                            ctx,
                            'All stock',
                            filter == 'all',
                            () => setSheetState(() => filter = 'all'),
                          ),
                          SizedBox(width: R.sp(ctx, 8)),
                          _filterChip(
                            ctx,
                            'Low stock',
                            filter == 'low',
                            () => setSheetState(() => filter = 'low'),
                          ),
                          SizedBox(width: R.sp(ctx, 8)),
                          _filterChip(
                            ctx,
                            'Out of stock',
                            filter == 'out',
                            () => setSheetState(() => filter = 'out'),
                          ),
                        ],
                      ),
                      SizedBox(height: R.sp(ctx, 12)),

                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'No products in this filter',
                                  style: TextStyle(
                                    fontSize: R.fs(ctx, 13),
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: R.sp(ctx, 8)),
                                itemBuilder: (_, i) {
                                  final p = filtered[i];
                                  final id = p['id'] as int;
                                  final qty =
                                      (p['quantity'] as num?)?.toInt() ?? 0;
                                  final lsl = (p['lsl'] as num?)?.toInt() ?? 0;
                                  final isOut = qty <= 0;
                                  final isLow = !isOut && qty <= lsl;
                                  final isSelected = selectedMap[id] ?? false;

                                  return Container(
                                    padding: EdgeInsets.all(R.sp(ctx, 12)),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withOpacity(0.05)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        R.radius(ctx, 10),
                                      ),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary.withOpacity(0.4)
                                            : AppColors.border,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Checkbox(
                                              value: isSelected,
                                              activeColor: AppColors.primary,
                                              onChanged: (v) => setSheetState(
                                                () => selectedMap[id] =
                                                    v ?? false,
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    p['name']?.toString() ?? '',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: R.fs(ctx, 13.5),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppColors
                                                          .textPrimaryDark,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: R.sp(ctx, 3),
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        '$qty on hand',
                                                        style: TextStyle(
                                                          fontSize: R.fs(
                                                            ctx,
                                                            11,
                                                          ),
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                      if (isOut || isLow) ...[
                                                        SizedBox(
                                                          width: R.sp(ctx, 6),
                                                        ),
                                                        Container(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: R
                                                                    .sp(ctx, 6),
                                                                vertical: R.sp(
                                                                  ctx,
                                                                  1,
                                                                ),
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                (isOut
                                                                        ? Colors
                                                                              .red
                                                                        : Colors
                                                                              .orange)
                                                                    .withOpacity(
                                                                      0.12,
                                                                    ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  R.radius(
                                                                    ctx,
                                                                    6,
                                                                  ),
                                                                ),
                                                          ),
                                                          child: Text(
                                                            isOut
                                                                ? 'Out'
                                                                : 'Low',
                                                            style: TextStyle(
                                                              fontSize: R.fs(
                                                                ctx,
                                                                9,
                                                              ),
                                                              color: isOut
                                                                  ? Colors.red
                                                                  : Colors
                                                                        .orange,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: R.sp(ctx, 8)),
                                        Padding(
                                          padding: EdgeInsets.only(
                                            left: R.sp(ctx, 4),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: _PoFieldWithLabel(
                                                  label: 'QTY',
                                                  controller: qtyCtrls[id]!,
                                                  enabled: isSelected,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  onChanged: (_) =>
                                                      setSheetState(() {}),
                                                ),
                                              ),
                                              SizedBox(width: R.sp(ctx, 10)),
                                              Expanded(
                                                flex: 2,
                                                child: _PoFieldWithLabel(
                                                  label: 'UNIT PRICE (₹)',
                                                  controller: priceCtrls[id]!,
                                                  enabled: isSelected,
                                                  keyboardType:
                                                      const TextInputType.numberWithOptions(
                                                        decimal: true,
                                                      ),
                                                  prefixText: '₹ ',
                                                  onChanged: (_) =>
                                                      setSheetState(() {}),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),

                      SizedBox(height: R.sp(ctx, 12)),

                      SizedBox(
                        width: double.infinity,
                        height: R.btnH(ctx),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(
                              R.radius(ctx, 10),
                            ),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  R.radius(ctx, 10),
                                ),
                              ),
                            ),
                            onPressed: selectedCount == 0
                                ? null
                                : () {
                                    final selectedItems =
                                        <Map<String, dynamic>>[];
                                    for (final p in supplierProducts) {
                                      final id = p['id'] as int;
                                      if (selectedMap[id] == true) {
                                        final qtyVal =
                                            int.tryParse(
                                              qtyCtrls[id]!.text.trim(),
                                            ) ??
                                            1;
                                        final unitPrice =
                                            double.tryParse(
                                              priceCtrls[id]!.text.trim(),
                                            ) ??
                                            (p['purchase_price'] as num?)
                                                ?.toDouble() ??
                                            (p['selling_price'] as num?)
                                                ?.toDouble() ??
                                            0.0;
                                        final qtyOnHand =
                                            (p['quantity'] as num?)?.toInt() ??
                                            0;
                                        final lslVal =
                                            (p['lsl'] as num?)?.toInt() ?? 0;
                                        selectedItems.add({
                                          'productId': id,
                                          'name': p['name'],
                                          'unit': p['unit'] ?? 'box',
                                          'qty': qtyVal < 1 ? 1 : qtyVal,
                                          'unitPrice': unitPrice,
                                          'suggested': qtyOnHand <= lslVal,
                                        });
                                      }
                                    }
                                    Navigator.pop(ctx, selectedItems);
                                  },
                            child: Text(
                              selectedCount == 0
                                  ? 'Select at least 1 item'
                                  : 'Add $selectedCount item${selectedCount == 1 ? '' : 's'} to PO',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: R.fs(ctx, 14),
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

    if (result != null) {
      setState(() {
        _items = result;
      });
    }
  }

  Widget _filterChip(
    BuildContext ctx,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: R.sp(ctx, 12),
          vertical: R.sp(ctx, 8),
        ),
        decoration: BoxDecoration(
          gradient: active ? AppColors.brandGradient : null,
          color: active ? null : Colors.white,
          borderRadius: BorderRadius.circular(R.radius(ctx, 20)),
          border: Border.all(
            color: active ? Colors.transparent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: R.fs(ctx, 12),
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.textPrimaryDark,
          ),
        ),
      ),
    );
  }

  Future<void> _addItem() async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final unitCtrl = TextEditingController(text: 'box');
    final priceCtrl = TextEditingController();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: R.sp(ctx, 18),
          right: R.sp(ctx, 18),
          top: R.sp(ctx, 18),
          bottom: MediaQuery.of(ctx).viewInsets.bottom + R.sp(ctx, 18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add item',
              style: TextStyle(
                fontSize: R.fs(ctx, 16),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryDark,
              ),
            ),
            SizedBox(height: R.sp(ctx, 14)),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Item name'),
            ),
            SizedBox(height: R.sp(ctx, 10)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Qty'),
                  ),
                ),
                SizedBox(width: R.sp(ctx, 10)),
                Expanded(
                  child: TextField(
                    controller: unitCtrl,
                    decoration: const InputDecoration(labelText: 'Unit'),
                  ),
                ),
              ],
            ),
            SizedBox(height: R.sp(ctx, 10)),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Unit price (₹)'),
            ),
            SizedBox(height: R.sp(ctx, 18)),
            SizedBox(
              width: double.infinity,
              height: R.btnH(ctx),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(R.radius(ctx, 10)),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(R.radius(ctx, 10)),
                    ),
                  ),
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx, true);
                  },
                  child: Text(
                    'Add item',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: R.fs(ctx, 14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      setState(() {
        _items.add({
          'productId': null,
          'name': nameCtrl.text.trim(),
          'unit': unitCtrl.text.trim().isEmpty ? 'box' : unitCtrl.text.trim(),
          'qty': int.tryParse(qtyCtrl.text.trim()) ?? 1,
          'unitPrice': double.tryParse(priceCtrl.text.trim()) ?? 0.0,
          'suggested': false,
        });
      });
    }
  }

  Future<void> _saveDraft() async {
    if (_selectedSupplier == null || _items.isEmpty) {
      _showError('Select a supplier and add at least one item.');
      return;
    }
    setState(() => _saving = true);
    await DBHelper.createPurchaseOrder(
      supplierId: _selectedSupplier!['id'],
      items: _items,
      expectedDelivery: _expectedDelivery,
      status: 'draft',
    );
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Draft saved')));
      Navigator.pop(context, true);
    }
  }

  Future<void> _sendToSupplier() async {
    if (_selectedSupplier == null || _items.isEmpty) {
      _showError('Select a supplier and add at least one item.');
      return;
    }

    final phone = (_selectedSupplier!['contactNumber'] ?? '').toString();
    if (phone.trim().isEmpty) {
      _showError('This supplier has no phone number saved.');
      return;
    }

    setState(() => _saving = true);
    final poId = await DBHelper.createPurchaseOrder(
      supplierId: _selectedSupplier!['id'],
      items: _items,
      expectedDelivery: _expectedDelivery,
      status: 'sent',
    );
    setState(() => _saving = false);
    if (!mounted) return;

    await _openWhatsApp(phone, poId);
    Navigator.pop(context, true);
  }

  Future<bool> _openWhatsApp(String rawPhone, int poId) async {
    var digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) digits = '91$digits';
    final poNumber = 'PO-${poId.toString().padLeft(4, '0')}';

    final lines = _items
        .map(
          (i) =>
              '• ${i['name']} — ${i['qty']} ${i['unit']} × ₹${(i['unitPrice'] as num).toStringAsFixed(0)}',
        )
        .join('\n');

    final textMessage =
        'Hi ${_selectedSupplier!['supplierName'] ?? ''}, sending our purchase order $poNumber:\n\n'
        '$lines\n\n'
        'Total (incl GST): ₹${_total.toStringAsFixed(0)}\n'
        'Expected delivery: ${DateFormat('d MMM').format(_expectedDelivery)}\n\n'
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
      } else {
        if (mounted) _showError('Could not open WhatsApp. Is it installed?');
        return false;
      }
    } catch (e) {
      if (mounted) _showError('Error launching WhatsApp: $e');
      return false;
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final leadDays = _expectedDelivery.difference(DateTime.now()).inDays;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: R
                  .hPad(context, base: 18)
                  .copyWith(top: R.sp(context, 40), bottom: R.sp(context, 120)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back,
                          color: AppColors.textPrimaryDark,
                          size: R.icon(context, 22),
                        ),
                      ),
                      Text(
                        'New purchase order',
                        style: TextStyle(
                          color: AppColors.textPrimaryDark,
                          fontSize: R.fs(context, 18),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: R.sp(context, 20)),

                  // ── Supplier Section Header ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Supplier',
                        style: TextStyle(
                          fontSize: R.fs(context, 12),
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SuppliersScreen(),
                            ),
                          ).then((_) => _loadSuppliers());
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add,
                              size: R.icon(context, 14),
                              color: AppColors.primary,
                            ),
                            SizedBox(width: R.sp(context, 2)),
                            Text(
                              'Add supplier',
                              style: TextStyle(
                                fontSize: R.fs(context, 12),
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: R.sp(context, 6)),

                  // ── Integrated Dropdown Field ──
                  DropdownButtonFormField<int>(
                    // 🆕 Use unique id instead of raw Map reference to bypass memory reference mismatch checks
                    value: _selectedSupplier?['id'],
                    isExpanded: true,
                    menuMaxHeight: 250,
                    dropdownColor: Colors.white,
                    elevation: 2,
                    borderRadius: BorderRadius.circular(16),
                    decoration: InputDecoration(
                      hintText: "Select supplier",
                      hintStyle: TextStyle(
                        fontSize: R.fs(context, 14),
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                      prefixIcon: Icon(
                        Icons.storefront_outlined,
                        color: Colors.grey.shade500,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          R.radius(context, 10),
                        ),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          R.radius(context, 10),
                        ),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          R.radius(context, 10),
                        ),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    items: _suppliers.map((e) {
                      final id = (e['id'] as num).toInt();
                      final name = e['supplierName']?.toString() ?? '';
                      final terms = e['paymentTerms'] != null
                          ? ' · ${e['paymentTerms']}'
                          : '';
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(
                          '$name$terms',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: R.fs(context, 14),
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (selectedId) {
                      if (selectedId != null) {
                        // Locate target database map matching requested unique ID cleanly
                        final match = _suppliers.firstWhere(
                          (element) =>
                              (element['id'] as num).toInt() == selectedId,
                        );
                        setState(() {
                          _selectedSupplier = match;
                          _items = [];
                        });
                        // Automatically bring up picker sheet instantly
                        _openItemPicker(match);
                      }
                    },
                  ),

                  SizedBox(height: R.sp(context, 20)),

                  // ── Items ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items',
                        style: TextStyle(
                          fontSize: R.fs(context, 12),
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (_selectedSupplier != null)
                        TextButton(
                          onPressed: () => _openItemPicker(_selectedSupplier!),
                          child: Text(
                            'Select items',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: R.fs(context, 12),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: R.sp(context, 8)),

                  if (_selectedSupplier != null && _items.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: R.sp(context, 8)),
                      child: Text(
                        'No items selected yet. Tap "Select items" above to '
                        'choose products from ${_selectedSupplier!['supplierName']}.',
                        style: TextStyle(
                          fontSize: R.fs(context, 12),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

                  ..._items.map(
                    (item) => _PoItemTile(
                      item: item,
                      onRemove: () => setState(() => _items.remove(item)),
                    ),
                  ),
                  SizedBox(height: R.sp(context, 8)),

                  GestureDetector(
                    onTap: _addItem,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: R.sp(context, 15),
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          R.radius(context, 10),
                        ),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        '+ Add item',
                        style: TextStyle(
                          fontSize: R.fs(context, 14),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: R.sp(context, 16)),

                  // ── Total ──
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _expectedDelivery,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) {
                        setState(() => _expectedDelivery = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(R.sp(context, 16)),
                      decoration: BoxDecoration(
                        color: AppColors.background == Colors.white
                            ? const Color(0xFFF2F3F5)
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(
                          R.radius(context, 10),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total · incl GST',
                                style: TextStyle(
                                  fontSize: R.fs(context, 14),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimaryDark,
                                ),
                              ),
                              SizedBox(height: R.sp(context, 4)),
                              Text(
                                'Expected delivery: '
                                '${DateFormat('d MMM').format(_expectedDelivery)} '
                                '(${leadDays < 0 ? 0 : leadDays}-day lead)',
                                style: TextStyle(
                                  fontSize: R.fs(context, 12),
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '₹${_total.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: R.fs(context, 16),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: R
              .hPad(context, base: 18)
              .copyWith(top: R.sp(context, 12), bottom: R.sp(context, 12)),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: R.btnH(context),
                  child: OutlinedButton(
                    onPressed: _saving ? null : _saveDraft,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          R.radius(context, 10),
                        ),
                      ),
                    ),
                    child: Text(
                      'Save draft',
                      style: TextStyle(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.w600,
                        fontSize: R.fs(context, 14),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: R.sp(context, 12)),
              Expanded(
                child: SizedBox(
                  height: R.btnH(context),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(
                        R.radius(context, 10),
                      ),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _sendToSupplier,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            R.radius(context, 10),
                          ),
                        ),
                      ),
                      icon: _saving
                          ? SizedBox(
                              width: R.sp(context, 16),
                              height: R.sp(context, 16),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              Icons.chat,
                              color: Colors.white,
                              size: R.icon(context, 18),
                            ),
                      label: Text(
                        'Send PO to supplier',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: R.fs(context, 14),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PoFieldWithLabel extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType keyboardType;
  final String? prefixText;
  final ValueChanged<String>? onChanged;

  const _PoFieldWithLabel({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.keyboardType,
    this.prefixText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: R.fs(context, 10),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: enabled
                ? AppColors.textSecondary
                : AppColors.textSecondary.withOpacity(0.5),
          ),
        ),
        SizedBox(height: R.sp(context, 4)),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: R.fs(context, 13.5),
            fontWeight: FontWeight.w600,
            color: enabled
                ? AppColors.textPrimaryDark
                : AppColors.textSecondary,
          ),
          decoration: InputDecoration(
            isDense: true,
            prefixText: prefixText,
            prefixStyle: TextStyle(
              fontSize: R.fs(context, 13.5),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryDark,
            ),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(
              horizontal: R.sp(context, 12),
              vertical: R.sp(context, 11),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(R.radius(context, 8)),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(R.radius(context, 8)),
              borderSide: BorderSide(color: AppColors.border),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(R.radius(context, 8)),
              borderSide: BorderSide(color: AppColors.border.withOpacity(0.6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(R.radius(context, 8)),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PoItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onRemove;
  const _PoItemTile({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final qty = item['qty'] as int;
    final unit = item['unit'] as String;
    final unitPrice = (item['unitPrice'] as num).toDouble();
    final total = qty * unitPrice;
    final suggested = item['suggested'] == true;

    return Container(
      margin: EdgeInsets.only(bottom: R.sp(context, 10)),
      padding: EdgeInsets.all(R.sp(context, 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(R.radius(context, 10)),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: R.fs(context, 14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                SizedBox(height: R.sp(context, 4)),
                Text(
                  '$qty $unit × ₹${unitPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: R.fs(context, 12),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onLongPress: onRemove,
                child: Text(
                  '₹${total.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: R.fs(context, 14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ),
              if (suggested) ...[
                SizedBox(height: R.sp(context, 4)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: R.sp(context, 8),
                    vertical: R.sp(context, 2),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(R.radius(context, 6)),
                  ),
                  child: Text(
                    'suggested',
                    style: TextStyle(
                      fontSize: R.fs(context, 10),
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
