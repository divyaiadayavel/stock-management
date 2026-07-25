// =========================================================
// lib/features/inventory/presentation/screens/new_purchase_order_screen.dart
// =========================================================
//
// Full file with:
// - Fast tab switching (AutomaticKeepAliveClientMixin)
// - Send existing draft from History (type‑safe)
// - Fixed _sendToSupplier() to send 'ORDERED'
//
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
import '../../../suppliers/presentation/screens/suppliers_screen.dart';
import '../providers/inventory_filter_provider.dart';

// ── Helper to safely parse dynamic → num ──
num _safeNum(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}

class NewPurchaseOrderScreen extends ConsumerStatefulWidget {
  const NewPurchaseOrderScreen({super.key});

  @override
  ConsumerState<NewPurchaseOrderScreen> createState() =>
      _NewPurchaseOrderScreenState();
}

class _NewPurchaseOrderScreenState
    extends ConsumerState<NewPurchaseOrderScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ── Tab Controller ──
  late TabController _tabController;

  // ── New Order Tab State ──
  Map<String, dynamic>? _selectedSupplier;
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _items = [];
  final DateTime _expectedDelivery = DateTime.now().add(const Duration(days: 3));
  bool _loading = false;
  bool _saving = false;

  // ── History Tab State ──
  List<Map<String, dynamic>> _ordersHistory = [];
  bool _loadingHistory = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadSuppliers();
    _fetchHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Data Fetching
  // --------------------------------------------------------------------------
  Future<void> _loadSuppliers() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getSuppliers),
        headers: ApiConfig.jsonHeaders,
      );
      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        if (resData['success'] == true && resData['data'] is List) {
          if (mounted) {
            setState(() {
              _suppliers = List<Map<String, dynamic>>.from(resData['data']);
              _loading = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading suppliers: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fetchHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final uri = Uri.parse('${ApiConfig.purchases}?action=list_purchases');
      final response = await http.get(uri, headers: ApiConfig.jsonHeaders);
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res['success'] == true && res['data'] is List) {
          setState(() {
            _ordersHistory = List<Map<String, dynamic>>.from(res['data']);
          });
        } else {
          _showError(res['message'] ?? 'Failed to load history');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Network error: $e');
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  // --------------------------------------------------------------------------
  // New Order Helpers
  // --------------------------------------------------------------------------
  double get _total => _items.fold(
        0.0,
        (sum, item) => sum + ((item['qty'] as num) * (item['unitPrice'] as num)),
      );

  Future<void> _openItemPicker(Map<String, dynamic> supplier) async {
    setState(() => _loading = true);

    final supplierId = (supplier['id'] as num).toInt();
    final supplierName =
        supplier['supplier_name'] ?? supplier['company_name'] ?? 'Supplier';

    List<Map<String, dynamic>> supplierProducts = [];

    try {
      final uri = Uri.parse(
          '${ApiConfig.purchases}?action=supplier_products&supplier_id=$supplierId');
      final response = await http.get(uri, headers: ApiConfig.jsonHeaders);
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res['success'] == true && res['data'] is List) {
          supplierProducts = List<Map<String, dynamic>>.from(res['data']);
        }
      }
    } catch (e) {
      debugPrint('Error fetching supplier products: $e');
    }

    if (mounted) setState(() => _loading = false);

    if (supplierProducts.isEmpty) {
      _showError('No products assigned to $supplierName.');
      return;
    }

    final Map<int, bool> selectedMap = {};
    final Map<int, TextEditingController> qtyCtrls = {};
    final Map<int, TextEditingController> priceCtrls = {};

    for (final p in supplierProducts) {
      final id = (p['id'] as num).toInt();
      final isLowOrOut = p['is_low'] == true || p['is_out'] == true;
      selectedMap[id] = isLowOrOut;
      qtyCtrls[id] = TextEditingController(text: p['suggested_qty'].toString());
      priceCtrls[id] = TextEditingController(
        text: (p['purchase_price'] as num).toStringAsFixed(2),
      );
    }

    String filter = 'all';

    if (!mounted) return;

    final result = await showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filtered = supplierProducts.where((p) {
              if (filter == 'low') return p['is_low'] == true;
              if (filter == 'out') return p['is_out'] == true;
              return true;
            }).toList();

            final selectedCount = selectedMap.values.where((v) => v).length;

            double runningTotal = 0;
            for (final p in supplierProducts) {
              final id = (p['id'] as num).toInt();
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
                    left: R.sp(ctx, AppSpacing.lg),
                    right: R.sp(ctx, AppSpacing.lg),
                    top: R.sp(ctx, AppSpacing.md),
                    bottom:
                        MediaQuery.of(ctx).viewInsets.bottom + R.sp(ctx, AppSpacing.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: R.sp(ctx, 40),
                          height: R.sp(ctx, 4),
                          margin: EdgeInsets.only(bottom: R.sp(ctx, AppSpacing.md)),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Text(
                        'Select items · $supplierName',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontDisplay,
                          fontSize: R.fs(ctx, 16),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      SizedBox(height: R.sp(ctx, AppSpacing.xs)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$selectedCount selected',
                            style: AppTextStyles.small
                                .copyWith(fontSize: R.fs(ctx, 12)),
                          ),
                          Text(
                            '₹${runningTotal.toStringAsFixed(0)}',
                            style: AppTextStyles.cardValue
                                .copyWith(fontSize: R.fs(ctx, 14)),
                          ),
                        ],
                      ),
                      SizedBox(height: R.sp(ctx, AppSpacing.md)),
                      Row(
                        children: [
                          _filterChip(ctx, 'All stock', filter == 'all',
                              () => setSheetState(() => filter = 'all')),
                          SizedBox(width: R.sp(ctx, AppSpacing.sm)),
                          _filterChip(ctx, 'Low stock', filter == 'low',
                              () => setSheetState(() => filter = 'low')),
                          SizedBox(width: R.sp(ctx, AppSpacing.sm)),
                          _filterChip(ctx, 'Out of stock', filter == 'out',
                              () => setSheetState(() => filter = 'out')),
                        ],
                      ),
                      SizedBox(height: R.sp(ctx, AppSpacing.md)),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'No products in this filter',
                                  style: AppTextStyles.small
                                      .copyWith(fontSize: R.fs(ctx, 13)),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) =>
                                    SizedBox(height: R.sp(ctx, AppSpacing.sm)),
                                itemBuilder: (_, i) {
                                  final p = filtered[i];
                                  final id = (p['id'] as num).toInt();
                                  final qty = (p['current_stock'] as num).toInt();
                                  final isOut = p['is_out'] == true;
                                  final isLow = p['is_low'] == true;
                                  final isSelected = selectedMap[id] ?? false;

                                  return Container(
                                    padding: EdgeInsets.all(R.sp(ctx, AppSpacing.md)),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withValues(alpha: 0.05)
                                          : AppColors.card,
                                      borderRadius: BorderRadius.circular(
                                          R.radius(ctx, AppSizes.radiusLg)),
                                      border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary.withValues(alpha: 0.4)
                                              : AppColors.border),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Checkbox(
                                              value: isSelected,
                                              activeColor: AppColors.primary,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize.shrinkWrap,
                                              onChanged: (v) => setSheetState(
                                                  () => selectedMap[id] = v ?? false),
                                            ),
                                            SizedBox(width: R.sp(ctx, AppSpacing.xs)),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    p['product_name'].toString(),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        fontSize: R.fs(ctx, 13.5),
                                                        fontWeight: FontWeight.w600,
                                                        color:
                                                            AppColors.textPrimaryDark),
                                                  ),
                                                  SizedBox(height: R.sp(ctx, 3)),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        '$qty on hand',
                                                        style: AppTextStyles.small
                                                            .copyWith(
                                                                fontSize: R.fs(ctx, 11)),
                                                      ),
                                                      if (isOut || isLow) ...[
                                                        SizedBox(
                                                            width: R.sp(ctx, AppSpacing.xs)),
                                                        _StatusTag(
                                                          label: isOut ? 'Out' : 'Low',
                                                          color: isOut
                                                              ? AppColors.red
                                                              : AppColors.orange,
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: R.sp(ctx, AppSpacing.sm)),
                                        Padding(
                                          padding:
                                              EdgeInsets.only(left: R.sp(ctx, AppSpacing.xs)),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: _PoFieldWithLabel(
                                                  label: 'QTY',
                                                  controller: qtyCtrls[id]!,
                                                  enabled: isSelected,
                                                  keyboardType: TextInputType.number,
                                                  onChanged: (_) => setSheetState(() {}),
                                                ),
                                              ),
                                              SizedBox(width: R.sp(ctx, AppSpacing.md)),
                                              Expanded(
                                                flex: 2,
                                                child: _PoFieldWithLabel(
                                                  label: 'UNIT PRICE (₹)',
                                                  controller: priceCtrls[id]!,
                                                  enabled: isSelected,
                                                  keyboardType:
                                                      const TextInputType.numberWithOptions(
                                                          decimal: true),
                                                  prefixText: '₹ ',
                                                  onChanged: (_) => setSheetState(() {}),
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
                      SizedBox(height: R.sp(ctx, AppSpacing.md)),
                      SizedBox(
                        width: double.infinity,
                        height: R.btnH(ctx),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius:
                                BorderRadius.circular(R.radius(ctx, AppSizes.radiusMd)),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        R.radius(ctx, AppSizes.radiusMd)))),
                            onPressed: selectedCount == 0
                                ? null
                                : () {
                                    final selectedItems = <Map<String, dynamic>>[];
                                    for (final p in supplierProducts) {
                                      final id = (p['id'] as num).toInt();
                                      if (selectedMap[id] == true) {
                                        final qtyVal =
                                            int.tryParse(qtyCtrls[id]!.text.trim()) ?? 1;
                                        final unitPrice = double.tryParse(
                                                priceCtrls[id]!.text.trim()) ??
                                            (p['purchase_price'] as num).toDouble();
                                        selectedItems.add({
                                          'productId': id,
                                          'name': p['product_name'],
                                          'unit': p['unit_name'] ?? 'pcs',
                                          'qty': qtyVal < 1 ? 1 : qtyVal,
                                          'unitPrice': unitPrice,
                                          'suggested':
                                              p['is_low'] == true || p['is_out'] == true,
                                        });
                                      }
                                    }
                                    Navigator.pop(ctx, selectedItems);
                                  },
                            child: Text(
                              'Add $selectedCount item${selectedCount == 1 ? '' : 's'} to PO',
                              style: AppTextStyles.button
                                  .copyWith(fontSize: R.fs(ctx, 14)),
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

    if (result != null && mounted) {
      setState(() {
        _items = result;
      });
    }
  }

  // --------------------------------------------------------------------------
  // New Order Actions
  // --------------------------------------------------------------------------
  Future<int?> _submitPoToBackend(String status) async {
    try {
      final itemsPayload = _items.map((item) {
        return {
          'product_id': item['productId'],
          'quantity': item['qty'],
          'purchase_price': item['unitPrice'],
          'tax': 0,
          'discount': 0,
        };
      }).toList();

      final payload = {
        'supplier_id': _selectedSupplier!['id'],
        'purchase_date': DateFormat('yyyy-MM-dd HH:mm:s').format(DateTime.now()),
        'status': status,
        'items': itemsPayload,
      };

      final uri = Uri.parse('${ApiConfig.purchases}?action=create_purchase');
      final response = await http.post(
        uri,
        headers: ApiConfig.jsonHeaders,
        body: json.encode(payload),
      );

      final res = json.decode(response.body);

      if (response.statusCode == 200 && res['success'] == true) {
        final poId = res['data']?['purchase_id'];
        return poId is int ? poId : int.tryParse(poId.toString());
      } else {
        _showError(res['message'] ?? 'Failed to create purchase order');
      }
    } catch (e) {
      _showError('Backend error: $e');
    }
    return null;
  }

  Future<void> _saveDraft() async {
    if (_selectedSupplier == null || _items.isEmpty) {
      _showError('Select a supplier and add at least one item.');
      return;
    }

    setState(() => _saving = true);
    final poId = await _submitPoToBackend('DRAFT');
    setState(() => _saving = false);

    if (poId != null && mounted) {
      ref.read(inventoryRefreshProvider.notifier).state++;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft saved successfully!')),
      );
      setState(() {
        _items = [];
        _selectedSupplier = null;
      });
      _fetchHistory();
    }
  }

  // ✅ Send new order as ORDERED
  Future<void> _sendToSupplier() async {
    if (_selectedSupplier == null || _items.isEmpty) {
      _showError('Select a supplier and add at least one item.');
      return;
    }

    final phone =
        (_selectedSupplier!['phone'] ?? _selectedSupplier!['contactNumber'] ?? '')
            .toString();

    setState(() => _saving = true);
    final poId = await _submitPoToBackend('ORDERED');
    setState(() => _saving = false);

    if (poId != null && mounted) {
      ref.read(inventoryRefreshProvider.notifier).state++;
      if (phone.trim().isNotEmpty) {
        await _openWhatsApp(phone, poId);
      }
      setState(() {
        _items = [];
        _selectedSupplier = null;
      });
      _fetchHistory();
    }
  }

  Future<bool> _openWhatsApp(String rawPhone, int poId) async {
    var digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) digits = '91$digits';
    final poNumber = 'PO-${poId.toString().padLeft(4, '0')}';

    final lines = _items
        .map((i) =>
            '• ${i['name']} — ${i['qty']} ${i['unit']} × ₹${(i['unitPrice'] as num).toStringAsFixed(0)}')
        .join('\n');

    final supplierName =
        _selectedSupplier!['supplier_name'] ?? _selectedSupplier!['company_name'] ?? '';

    final textMessage = 'Hi $supplierName, sending our purchase order $poNumber:\n\n'
        '$lines\n\n'
        'Total (incl GST): ₹${_total.toStringAsFixed(0)}\n'
        'Expected delivery: ${DateFormat('d MMM').format(_expectedDelivery)}\n\n'
        'Please confirm. Thank you!';

    final encodedMessage = Uri.encodeComponent(textMessage);

    final Uri appUri = Uri.parse('whatsapp://send?phone=$digits&text=$encodedMessage');
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

  // --------------------------------------------------------------------------
  // Send existing order from History (TYPE-SAFE)
  // --------------------------------------------------------------------------
  Future<void> _sendExistingOrder(int orderId, String poNumber, String supplier, String phone) async {
    setState(() => _deleting = true);
    try {
      // 1. Fetch order detail
      final detailUri = Uri.parse('${ApiConfig.purchases}?action=purchase_detail&id=$orderId');
      final detailRes = await http.get(detailUri, headers: ApiConfig.jsonHeaders);
      if (detailRes.statusCode != 200) {
        _showError('Failed to load order details');
        return;
      }
      final detailData = json.decode(detailRes.body);
      if (detailData['success'] != true) {
        _showError(detailData['message'] ?? 'Order not found');
        return;
      }
      final orderData = detailData['data'];
      final items = List<Map<String, dynamic>>.from(orderData['items'] ?? []);
      if (items.isEmpty) {
        _showError('No items in this order');
        return;
      }

      // 2. Build WhatsApp message – safely parse numeric values
      final lines = items.map((i) {
        final name = i['name']?.toString() ?? 'Product';
        final qty = _safeNum(i['orderedQty']).toInt();
        final unit = i['unit']?.toString() ?? 'pcs';
        final price = _safeNum(i['unitPrice']);
        return '• $name — $qty $unit × ₹${price.toStringAsFixed(0)}';
      }).join('\n');

      final total = _safeNum(orderData['grand_total']);
      final supplierName = supplier.isNotEmpty ? supplier : 'Supplier';
      final msg = 'Hi $supplierName, sending our purchase order $poNumber:\n\n'
          '$lines\n\n'
          'Total (incl GST): ₹${total.toStringAsFixed(0)}\n'
          'Expected delivery: ${DateFormat('d MMM').format(_expectedDelivery)}\n\n'
          'Please confirm. Thank you!';

      // 3. Update status to ORDERED
      final updateUri = Uri.parse('${ApiConfig.purchases}?action=update_purchase_status');
      final updateRes = await http.post(
        updateUri,
        headers: ApiConfig.jsonHeaders,
        body: json.encode({'id': orderId, 'status': 'ORDERED'}),
      );
      final updateData = json.decode(updateRes.body);
      if (updateRes.statusCode != 200 || updateData['success'] != true) {
        _showError(updateData['message'] ?? 'Failed to update order');
        return;
      }

      // 4. Open WhatsApp – if no phone, skip
      var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isNotEmpty) {
        if (digits.length == 10) digits = '91$digits';
        final encoded = Uri.encodeComponent(msg);
        final appUri = Uri.parse('whatsapp://send?phone=$digits&text=$encoded');
        final webUri = Uri.parse('https://wa.me/$digits?text=$encoded');
        if (await canLaunchUrl(appUri)) {
          await launchUrl(appUri, mode: LaunchMode.externalApplication);
        } else if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
        } else {
          _showError('WhatsApp not installed', isError: true);
        }
      } else {
        _showError('No phone number for supplier', isError: true);
      }

      // 5. Refresh history
      await _fetchHistory();
      _showError('Order sent to supplier!', isError: false);
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  // --------------------------------------------------------------------------
  // History Actions
  // --------------------------------------------------------------------------
  Future<void> _deleteOrder(int orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
        title: const Text('Cancel Order'),
        content: const Text(
            'Are you sure you want to cancel this order? It cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep order',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _deleting = true);
    try {
      final uri = Uri.parse('${ApiConfig.purchases}?action=cancel_purchase');
      final response = await http.post(
        uri,
        headers: ApiConfig.jsonHeaders,
        body: json.encode({'id': orderId}),
      );
      final res = json.decode(response.body);
      if (response.statusCode == 200 && res['success'] == true) {
        _showError('Order cancelled successfully.', isError: false);
        await _fetchHistory();
      } else {
        _showError(res['message'] ?? 'Failed to cancel order');
      }
    } catch (e) {
      _showError('Error cancelling order: $e');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  // --------------------------------------------------------------------------
  // UI Helpers
  // --------------------------------------------------------------------------
  void _showError(String msg, {bool isError = true}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? AppColors.red : AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
        ),
      );
    }
  }

  Widget _filterChip(BuildContext ctx, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: R.sp(ctx, AppSpacing.md), vertical: R.sp(ctx, AppSpacing.sm)),
        decoration: BoxDecoration(
          gradient: active ? AppColors.brandGradient : null,
          color: active ? null : AppColors.card,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: active ? Colors.transparent : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: R.fs(ctx, 12),
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textPrimaryDark),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.textPrimaryDark,
        surfaceTintColor: Colors.transparent,
        title: Text('Purchase Orders', style: AppTextStyles.appBarTitle),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5),
          tabs: const [
            Tab(text: 'New Order'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewOrderTab(),
          _buildHistoryTab(),
        ],
      ),
      bottomNavigationBar:
          _tabController.index == 0 ? _buildNewOrderBottomBar() : null,
    );
  }

  // --------------------------------------------------------------------------
  // Tab Contents
  // --------------------------------------------------------------------------
  Widget _buildNewOrderTab() {
    final leadDays = _expectedDelivery.difference(DateTime.now()).inDays;

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: R.hPad(context, base: AppSpacing.lg).copyWith(
                top: R.sp(context, AppSpacing.lg), bottom: R.sp(context, 120)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(
                        'SUPPLIER',
                        trailing: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SuppliersScreen()),
                            ).then((_) => _loadSuppliers());
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_circle_outline,
                                  size: R.icon(context, 15), color: AppColors.primary),
                              SizedBox(width: R.sp(context, 4)),
                              Text(
                                'Add supplier',
                                style: TextStyle(
                                    fontSize: R.fs(context, 12),
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: R.sp(context, AppSpacing.sm)),
                      DropdownButtonFormField<int>(
                        value: _selectedSupplier?['id'],
                        isExpanded: true,
                        menuMaxHeight: 250,
                        dropdownColor: AppColors.card,
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary),
                        style: TextStyle(
                            fontSize: R.fs(context, 14),
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimaryDark),
                        decoration: InputDecoration(
                          hintText: 'Select supplier',
                          hintStyle: TextStyle(color: AppColors.textSecondary),
                          prefixIcon: Icon(Icons.storefront_outlined,
                              color: AppColors.textSecondary, size: R.icon(context, 20)),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: R.sp(context, AppSpacing.md)),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(R.radius(context, AppSizes.radiusMd)),
                              borderSide: BorderSide(color: AppColors.border)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(R.radius(context, AppSizes.radiusMd)),
                              borderSide: BorderSide(color: AppColors.border)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(R.radius(context, AppSizes.radiusMd)),
                              borderSide: BorderSide(color: AppColors.primary, width: 1.4)),
                        ),
                        items: _suppliers.map((e) {
                          final id = (e['id'] as num).toInt();
                          final name = e['supplier_name'] ?? e['company_name'] ?? 'Supplier #$id';
                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(name.toString()),
                          );
                        }).toList(),
                        onChanged: (selectedId) {
                          if (selectedId != null) {
                            final match = _suppliers.firstWhere(
                                (element) => (element['id'] as num).toInt() == selectedId);
                            setState(() {
                              _selectedSupplier = match;
                              _items = [];
                            });
                            _openItemPicker(match);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: R.sp(context, AppSpacing.lg)),
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(
                        'ITEMS',
                        trailing: _selectedSupplier != null
                            ? GestureDetector(
                                onTap: () => _openItemPicker(_selectedSupplier!),
                                child: Text(
                                  _items.isEmpty ? 'Select items' : 'Edit items',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: R.fs(context, 12),
                                      fontWeight: FontWeight.w600),
                                ),
                              )
                            : null,
                      ),
                      SizedBox(height: R.sp(context, AppSpacing.sm)),
                      if (_selectedSupplier == null)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: R.sp(context, AppSpacing.sm)),
                          child: Text(
                            'Choose a supplier above to start adding items.',
                            style: AppTextStyles.small.copyWith(fontSize: R.fs(context, 12)),
                          ),
                        )
                      else if (_items.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: R.sp(context, AppSpacing.sm)),
                          child: Text(
                            'No items selected yet. Tap "Select items" above.',
                            style: AppTextStyles.small.copyWith(fontSize: R.fs(context, 12)),
                          ),
                        )
                      else
                        Column(
                          children: _items
                              .map((item) => _PoItemTile(
                                    item: item,
                                    onRemove: () => setState(() => _items.remove(item)),
                                  ))
                              .toList(),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: R.sp(context, AppSpacing.lg)),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(R.sp(context, AppSpacing.lg)),
                  decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius:
                          BorderRadius.circular(R.radius(context, AppSizes.radiusLg))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total · incl GST',
                            style: TextStyle(
                                fontSize: R.fs(context, 13),
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimaryDark),
                          ),
                          SizedBox(height: R.sp(context, 4)),
                          Row(
                            children: [
                              Icon(Icons.local_shipping_outlined,
                                  size: R.icon(context, 13), color: AppColors.textSecondary),
                              SizedBox(width: R.sp(context, 4)),
                              Text(
                                'Expected ${DateFormat('d MMM').format(_expectedDelivery)} · $leadDays-day lead',
                                style: AppTextStyles.small.copyWith(fontSize: R.fs(context, 11.5)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        '₹${_total.toStringAsFixed(0)}',
                        style: AppTextStyles.cardValue.copyWith(fontSize: R.fs(context, 18)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildHistoryTab() {
    if (_loadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_ordersHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            SizedBox(height: R.sp(context, AppSpacing.sm)),
            Text(
              'No purchase orders yet',
              style: AppTextStyles.small.copyWith(fontSize: R.fs(context, 13)),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchHistory,
      child: ListView.builder(
        padding: R.hPad(context, base: AppSpacing.lg).copyWith(
            top: R.sp(context, AppSpacing.md), bottom: R.sp(context, AppSpacing.md)),
        itemCount: _ordersHistory.length,
        itemBuilder: (context, index) {
          final order = _ordersHistory[index];
          final poId = (order['id'] as num).toInt();
          final poNumber = order['purchase_number']?.toString() ?? 'PO-$poId';
          final supplier = order['supplier_name']?.toString() ?? 'Supplier';
          final phone = order['supplier_phone']?.toString() ?? '';
          return _PoHistoryCard(
            order: order,
            deleting: _deleting,
            onDelete: () => _deleteOrder(poId),
            onSend: () => _sendExistingOrder(poId, poNumber, supplier, phone),
          );
        },
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Bottom Bar (New Order)
  // --------------------------------------------------------------------------
  Widget _buildNewOrderBottomBar() {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        padding: R.hPad(context, base: AppSpacing.lg)
            .copyWith(top: R.sp(context, AppSpacing.md), bottom: R.sp(context, AppSpacing.md)),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: R.btnH(context),
                child: OutlinedButton(
                  onPressed: _saving ? null : _saveDraft,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimaryDark,
                    side: BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(R.radius(context, AppSizes.radiusMd))),
                  ),
                  child: Text('Save draft',
                      style: AppTextStyles.button
                          .copyWith(fontSize: R.fs(context, 14), color: AppColors.textPrimaryDark)),
                ),
              ),
            ),
            SizedBox(width: R.sp(context, AppSpacing.md)),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: R.btnH(context),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius:
                          BorderRadius.circular(R.radius(context, AppSizes.radiusMd))),
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _sendToSupplier,
                    icon: _saving
                        ? SizedBox(
                            width: R.icon(context, 16),
                            height: R.icon(context, 16),
                            child: const CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(Icons.chat, color: Colors.white, size: R.icon(context, 18)),
                    label: Text('Send PO to supplier',
                        style: AppTextStyles.button.copyWith(fontSize: R.fs(context, 14))),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(R.radius(context, AppSizes.radiusMd)))),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Reusable Components
// ============================================================================

class _FieldLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const _FieldLabel(this.text, {this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style: AppTextStyles.cardTitle.copyWith(
            fontSize: R.fs(context, 11.5),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(R.sp(context, AppSpacing.lg)),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusLg)),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: R.sp(context, 6), vertical: R.sp(context, 1)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusSm)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: R.fs(context, 9), color: color, fontWeight: FontWeight.w700),
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
          style: AppTextStyles.cardTitle.copyWith(
            fontSize: R.fs(context, 10),
            fontWeight: FontWeight.w700,
            color: enabled
                ? AppColors.textSecondary
                : AppColors.textSecondary.withValues(alpha: 0.5),
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
              color: enabled ? AppColors.textPrimaryDark : AppColors.textSecondary),
          decoration: InputDecoration(
            isDense: true,
            prefixText: prefixText,
            filled: true,
            fillColor: enabled ? AppColors.card : AppColors.background,
            contentPadding: EdgeInsets.symmetric(
                horizontal: R.sp(context, AppSpacing.md), vertical: R.sp(context, 11)),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusMd)),
                borderSide: BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusMd)),
                borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusMd)),
                borderSide: BorderSide(color: AppColors.primary, width: 1.3)),
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
      margin: EdgeInsets.only(bottom: R.sp(context, AppSpacing.sm)),
      padding: EdgeInsets.all(R.sp(context, AppSpacing.md)),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusMd)),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: R.fs(context, 14),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryDark),
                ),
                SizedBox(height: R.sp(context, 4)),
                Row(
                  children: [
                    Text(
                      '$qty $unit × ₹${unitPrice.toStringAsFixed(0)}',
                      style: AppTextStyles.small.copyWith(fontSize: R.fs(context, 12)),
                    ),
                    if (suggested) ...[
                      SizedBox(width: R.sp(context, AppSpacing.xs)),
                      _StatusTag(label: 'suggested', color: AppColors.primary),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: R.sp(context, AppSpacing.sm)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '₹${total.toStringAsFixed(0)}',
                style: AppTextStyles.cardValue.copyWith(fontSize: R.fs(context, 14)),
              ),
              SizedBox(height: R.sp(context, 4)),
              GestureDetector(
                onTap: onRemove,
                child: Icon(Icons.close_rounded,
                    size: R.icon(context, 16), color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PoHistoryCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool deleting;
  final VoidCallback onDelete;
  final VoidCallback onSend;

  const _PoHistoryCard({
    required this.order,
    required this.deleting,
    required this.onDelete,
    required this.onSend,
  });

  String get _status => order['status']?.toString().toUpperCase() ?? 'DRAFT';

  Color get _statusColor {
    switch (_status) {
      case 'RECEIVED':
        return AppColors.green;
      case 'CANCELLED':
        return AppColors.textSecondary;
      default:
        return AppColors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final poId = (order['id'] as num).toInt();
    final poNumber = order['purchase_number']?.toString() ?? 'PO-$poId';
    final supplier = order['supplier_name']?.toString() ?? 'Supplier';
    final date = (order['purchase_date'] ?? order['created_at'] ?? '').toString();
    final total = order['grand_total'] != null ? '₹${order['grand_total']}' : '₹0';
    final isReceived = _status == 'RECEIVED';
    final isCancelled = _status == 'CANCELLED';
    final isDraft = _status == 'DRAFT';
    final canDelete = !isReceived && !isCancelled;
    final color = _statusColor;

    return Container(
      margin: EdgeInsets.only(bottom: R.sp(context, AppSpacing.sm)),
      padding: EdgeInsets.all(R.sp(context, AppSpacing.lg)),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusLg)),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  poNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontDisplay,
                    fontSize: R.fs(context, 14.5),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ),
              SizedBox(width: R.sp(context, AppSpacing.sm)),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: R.sp(context, AppSpacing.sm), vertical: R.sp(context, 3)),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusSm)),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    fontSize: R.fs(context, 10),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: R.sp(context, AppSpacing.xs)),
          Row(
            children: [
              Icon(Icons.storefront_outlined,
                  size: R.icon(context, 13), color: AppColors.textSecondary),
              SizedBox(width: R.sp(context, 4)),
              Flexible(
                child: Text(
                  supplier,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.small.copyWith(fontSize: R.fs(context, 12)),
                ),
              ),
              SizedBox(width: R.sp(context, AppSpacing.md)),
              Icon(Icons.calendar_today_outlined,
                  size: R.icon(context, 12), color: AppColors.textSecondary),
              SizedBox(width: R.sp(context, 4)),
              Text(
                date,
                style: AppTextStyles.small.copyWith(fontSize: R.fs(context, 11.5)),
              ),
            ],
          ),
          SizedBox(height: R.sp(context, AppSpacing.md)),
          Divider(height: 1, color: AppColors.border),
          SizedBox(height: R.sp(context, AppSpacing.sm)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TOTAL',
                      style: AppTextStyles.cardTitle.copyWith(
                          fontSize: R.fs(context, 10),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5)),
                  SizedBox(height: R.sp(context, 2)),
                  Text(
                    total,
                    style: AppTextStyles.cardValue.copyWith(fontSize: R.fs(context, 15)),
                  ),
                ],
              ),
              Row(
                children: [
                  if (isDraft)
                    OutlinedButton.icon(
                      onPressed: onSend,
                      icon: Icon(Icons.send, size: R.icon(context, 14)),
                      label: Text('Send',
                          style: TextStyle(fontSize: R.fs(context, 12))),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        padding: EdgeInsets.symmetric(
                            horizontal: R.sp(context, AppSpacing.sm),
                            vertical: R.sp(context, 4)),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(R.radius(context, AppSizes.radiusSm))),
                      ),
                    ),
                  if (canDelete) ...[
                    if (isDraft) SizedBox(width: R.sp(context, AppSpacing.sm)),
                    OutlinedButton.icon(
                      onPressed: deleting ? null : onDelete,
                      icon: Icon(Icons.close_rounded, size: R.icon(context, 14)),
                      label: Text('Cancel',
                          style: TextStyle(fontSize: R.fs(context, 12), fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.red,
                        side: BorderSide(color: AppColors.red.withValues(alpha: 0.35)),
                        padding: EdgeInsets.symmetric(
                            horizontal: R.sp(context, AppSpacing.sm),
                            vertical: R.sp(context, 4)),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(R.radius(context, AppSizes.radiusSm))),
                      ),
                    ),
                  ],
                  if (!isDraft && !canDelete)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isReceived ? Icons.check_circle_outline : Icons.block,
                          size: R.icon(context, 15),
                          color: color,
                        ),
                        SizedBox(width: R.sp(context, 4)),
                        Text(
                          isReceived ? 'Received' : 'Cancelled',
                          style: TextStyle(
                              fontSize: R.fs(context, 12),
                              fontWeight: FontWeight.w600,
                              color: color),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}