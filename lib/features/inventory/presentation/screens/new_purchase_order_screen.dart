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

class NewPurchaseOrderScreen extends ConsumerStatefulWidget {
  const NewPurchaseOrderScreen({super.key});

  @override
  ConsumerState<NewPurchaseOrderScreen> createState() =>
      _NewPurchaseOrderScreenState();
}

class _NewPurchaseOrderScreenState
    extends ConsumerState<NewPurchaseOrderScreen> {
  Map<String, dynamic>? _selectedSupplier;

  // Full low-stock list, unfiltered — kept so we can re-filter whenever
  // the selected supplier changes without hitting the DB again.
  List<Map<String, dynamic>> _allLowStockProducts = [];

  // What's actually shown / sent — filtered to the selected supplier
  // (plus anything manually added via "+ Add item").
  List<Map<String, dynamic>> _items = [];

  DateTime _expectedDelivery = DateTime.now().add(const Duration(days: 3));
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSuggested();
  }

  Future<void> _loadSuggested() async {
    // Pulls ALL items currently at/under reorder level across every
    // supplier. We don't build `_items` from this directly anymore —
    // that only happens once a supplier is selected, so the PO only
    // ever contains that supplier's own low-stock products.
    final lowStock = await DBHelper.getLowStockProducts();
    setState(() {
      _allLowStockProducts = lowStock;
      _loading = false;
    });
  }

  /// Builds the suggested-item list for a single supplier by matching
  /// each low-stock product's `supplier` name against the picked
  /// supplier's `supplierName`.
  List<Map<String, dynamic>> _buildItemsForSupplier(
    Map<String, dynamic> supplier,
  ) {
    final supplierName = (supplier['supplierName'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    return _allLowStockProducts
        .where(
          (p) =>
              (p['supplier'] ?? '').toString().trim().toLowerCase() ==
              supplierName,
        )
        .map((p) {
          final qty = (p['quantity'] as num?)?.toInt() ?? 0;
          final lsl = (p['lsl'] as num?)?.toInt() ?? 0;
          final suggestedQty = (lsl * 2 - qty).clamp(1, 100000);
          final unitPrice =
              (p['purchase_price'] as num?)?.toDouble() ??
              (p['selling_price'] as num?)?.toDouble() ??
              0.0;
          return {
            'productId': p['id'],
            'name': p['name'],
            'unit': p['unit'] ?? 'box',
            'qty': suggestedQty,
            'unitPrice': unitPrice,
            'suggested': true,
          };
        })
        .toList();
  }

  double get _total => _items.fold(
    0.0,
    (sum, item) => sum + ((item['qty'] as num) * (item['unitPrice'] as num)),
  );

  Future<void> _pickSupplier() async {
    final suppliers = await DBHelper.getSuppliers();
    if (!mounted) return;
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            top: R.sp(ctx, 16),
            bottom: MediaQuery.of(ctx).viewInsets.bottom + R.sp(ctx, 16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: R.sp(ctx, 18)),
                child: Text(
                  'Select supplier',
                  style: TextStyle(
                    fontSize: R.fs(ctx, 16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ),
              SizedBox(height: R.sp(ctx, 8)),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: suppliers.length,
                  itemBuilder: (_, i) {
                    final s = suppliers[i];
                    return ListTile(
                      title: Text(
                        s['supplierName']?.toString() ?? '',
                        style: TextStyle(fontSize: R.fs(ctx, 14)),
                      ),
                      subtitle: Text(
                        s['paymentTerms']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: R.fs(ctx, 12),
                          color: AppColors.textSecondary,
                        ),
                      ),
                      onTap: () => Navigator.pop(ctx, s),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedSupplier = picked;
        _items = _buildItemsForSupplier(picked);
      });
    }
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

  /// Returns true if launched successfully, false if it failed
  Future<bool> _openWhatsApp(String rawPhone, int poId) async {
    var digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) digits = '91$digits'; // default India code
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

    // Primary: Direct WhatsApp Scheme
    final Uri appUri = Uri.parse(
      'whatsapp://send?phone=$digits&text=$encodedMessage',
    );

    // Fallback: Web Scheme
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

                  // ── Supplier ──
                  Text(
                    'Supplier',
                    style: TextStyle(
                      fontSize: R.fs(context, 12),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: R.sp(context, 6)),
                  GestureDetector(
                    onTap: _pickSupplier,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: R.sp(context, 14),
                        vertical: R.sp(context, 15),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          R.radius(context, 10),
                        ),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        _selectedSupplier == null
                            ? 'Select supplier'
                            : '${_selectedSupplier!['supplierName']}'
                                  '${_selectedSupplier!['paymentTerms'] != null ? ' · ${_selectedSupplier!['paymentTerms']}' : ''}',
                        style: TextStyle(
                          fontSize: R.fs(context, 14),
                          fontWeight: FontWeight.w500,
                          color: _selectedSupplier == null
                              ? AppColors.textSecondary
                              : AppColors.textPrimaryDark,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: R.sp(context, 20)),

                  // ── Items ──
                  Text(
                    'Items',
                    style: TextStyle(
                      fontSize: R.fs(context, 12),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: R.sp(context, 8)),

                  if (_selectedSupplier != null && _items.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: R.sp(context, 8)),
                      child: Text(
                        'No low stock items for ${_selectedSupplier!['supplierName']}. '
                        'Use "+ Add item" below to add one manually.',
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

      // ── Bottom buttons ──
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
