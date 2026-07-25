// lib/features/inventory/presentation/screens/receive_order_screen.dart
//
// Complete implementation with:
// - Pending/Completed tabs
// - Expandable PO cards showing items with editable quantity and unit price
// - Confirm Stock‑In with partial support
// - Completed items showing actual received price vs ordered price
// - Partial badge and child PO link
// - Price history modal
// - No code compromises, full UI/UX.
//
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../providers/inventory_filter_provider.dart';

// --- Helpers (reused, self-contained) ---
int asInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? fallback;
  return fallback;
}

String asStr(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}

double asDouble(dynamic value, [double fallback = 0.0]) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

// ----------------------------------------------------------------------------
// Main Screen
// ----------------------------------------------------------------------------
class ReceiveOrderScreen extends ConsumerStatefulWidget {
  final int? poId;
  const ReceiveOrderScreen({super.key, this.poId});

  @override
  ConsumerState<ReceiveOrderScreen> createState() => _ReceiveOrderScreenState();
}

class _ReceiveOrderScreenState extends ConsumerState<ReceiveOrderScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _allOrders = [];
  bool _loadingOrders = true;
  int _selectedTab = 0; // 0 = Pending, 1 = Completed

  int? _expandedPendingPoId;
  int? _expandedCompletedPoId;

  final Map<int, Map<String, dynamic>> _poDetailsCache = {};
  final Map<int, bool> _loadingDetailMap = {};
  final Map<int, Map<int, int>> _receivingMapPerPo = {};
  final Map<int, Map<int, TextEditingController>> _priceControllers = {};

  bool _saving = false;

  int? get _expandedPoId => _selectedTab == 0 ? _expandedPendingPoId : _expandedCompletedPoId;
  void _setExpandedPoId(int? id) {
    if (_selectedTab == 0) _expandedPendingPoId = id;
    else _expandedCompletedPoId = id;
  }

  @override
  void initState() {
    super.initState();
    _fetchOrdersList();
  }

  // --------------------------------------------------------------------------
  // Data fetching
  // --------------------------------------------------------------------------
  Future<void> _fetchOrdersList() async {
    setState(() => _loadingOrders = true);
    try {
      final uri = Uri.parse('${ApiConfig.purchases}?action=list_purchases');
      final response = await http.get(uri, headers: ApiConfig.jsonHeaders);

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res['success'] == true && res['data'] != null) {
          _allOrders = List<Map<String, dynamic>>.from(res['data']);
          _expandedPendingPoId = null;
          _expandedCompletedPoId = null;
          _poDetailsCache.clear();
          _receivingMapPerPo.clear();
          _priceControllers.clear();
          _loadingDetailMap.clear();
        }
      }
    } catch (e) {
      _showToast('Failed to load orders', isError: true);
    } finally {
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  Future<void> _loadPoDetail(int poId) async {
    if (_poDetailsCache.containsKey(poId)) return;

    setState(() => _loadingDetailMap[poId] = true);
    try {
      final uri = Uri.parse('${ApiConfig.purchases}?action=purchase_detail&id=$poId');
      final response = await http.get(uri, headers: ApiConfig.jsonHeaders);

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res['success'] == true && res['data'] != null) {
          final poData = res['data'];
          final itemsList = List<Map<String, dynamic>>.from(poData['items'] ?? []);

          itemsList.sort((a, b) {
            final aOut = _outstandingOf(a);
            final bOut = _outstandingOf(b);
            if (aOut > 0 && bOut <= 0) return -1;
            if (aOut <= 0 && bOut > 0) return 1;
            return 0;
          });

          final fullPoData = Map<String, dynamic>.from(poData)..['items'] = itemsList;
          _poDetailsCache[poId] = fullPoData;

          final receivingMap = <int, int>{};
          final priceCtrls = <int, TextEditingController>{};
          for (final item in itemsList) {
            final itemId = asInt(item['id']);
            final outstanding = _outstandingOf(item);
            receivingMap[itemId] = outstanding > 0 ? outstanding : 0;
            final price = asDouble(item['unitPrice']);
            priceCtrls[itemId] = TextEditingController(text: price.toStringAsFixed(2));
          }
          _receivingMapPerPo[poId] = receivingMap;
          _priceControllers[poId] = priceCtrls;

          setState(() {});
        }
      }
    } catch (e) {
      _showToast('Failed to load PO details', isError: true);
    } finally {
      if (mounted) setState(() => _loadingDetailMap[poId] = false);
    }
  }

  // --------------------------------------------------------------------------
  // Price History
  // --------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> _fetchPriceHistory(int productId) async {
    try {
      final uri = Uri.parse('${ApiConfig.inventory}?action=price_history&product_id=$productId');
      final response = await http.get(uri, headers: ApiConfig.jsonHeaders);
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res['success'] == true) return List<Map<String, dynamic>>.from(res['data']);
      }
    } catch (e) {
      debugPrint('Error fetching price history: $e');
    }
    return [];
  }

  void _showPriceHistory(int productId, String productName) async {
    final history = await _fetchPriceHistory(productId);
    if (!mounted) return;
    if (history.isEmpty) {
      _showToast('No price history found for $productName', isError: false);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PriceHistoryModal(productName: productName, history: history),
    );
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------
  bool _isCompletedPO(Map<String, dynamic> po) {
    final status = asStr(po['status'] ?? po['purchase_status']).toUpperCase();
    return status == 'RECEIVED' || status == 'COMPLETE' || status == 'COMPLETED';
  }

  bool _isPendingPO(Map<String, dynamic> po) {
    final status = asStr(po['status'] ?? po['purchase_status']).toUpperCase();
    return status == 'ORDERED' || status == 'PARTIALLY_RECEIVED';
  }

  int _orderedQtyOf(Map<String, dynamic> item) => asInt(item['orderedQty']);
  int _alreadyReceivedOf(Map<String, dynamic> item) => asInt(item['receivedQty']);

  int _outstandingOf(Map<String, dynamic> item) {
    final ordered = _orderedQtyOf(item);
    final received = _alreadyReceivedOf(item);
    return (ordered - received).clamp(0, ordered);
  }

  int _getTotalReceivingForPo(int poId) {
    final map = _receivingMapPerPo[poId];
    if (map == null) return 0;
    return map.values.fold<int>(0, (sum, val) => sum + val);
  }

  bool _hasOutstandingForPo(int poId) {
    final map = _receivingMapPerPo[poId];
    if (map == null) return false;
    return map.values.any((qty) => qty > 0);
  }

  void _showToast(String msg, {required bool isError}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? AppColors.red : AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
        ),
      );
    }
  }

  // --------------------------------------------------------------------------
  // Actions
  // --------------------------------------------------------------------------
  void _toggleExpansion(int poId) {
    if (_expandedPoId == poId) {
      setState(() => _setExpandedPoId(null));
    } else {
      setState(() => _setExpandedPoId(poId));
      if (!_poDetailsCache.containsKey(poId)) _loadPoDetail(poId);
    }
  }

  Future<void> _confirmAndStockIn(int poId) async {
    if (_saving) return;

    final poData = _poDetailsCache[poId];
    if (poData == null) return;

    final items = List<Map<String, dynamic>>.from(poData['items'] ?? []);
    final receivingMap = _receivingMapPerPo[poId];
    final priceCtrls = _priceControllers[poId];
    if (receivingMap == null || priceCtrls == null) return;

    final receivedItemsPayload = items
        .where((item) => _outstandingOf(item) > 0)
        .map((item) {
          final itemId = asInt(item['id']);
          final prodId = asInt(item['productId']);
          final qtyVal = receivingMap[itemId] ?? 0;
          final priceController = priceCtrls[itemId];
          double? unitPrice;
          if (priceController != null) {
            final priceText = priceController.text.trim();
            if (priceText.isNotEmpty) unitPrice = double.tryParse(priceText);
          }
          final payload = <String, dynamic>{'product_id': prodId, 'quantity_received': qtyVal};
          if (unitPrice != null && unitPrice > 0) payload['unit_price'] = unitPrice;
          return payload;
        })
        .where((e) => (e['quantity_received'] as int) > 0)
        .toList();

    if (receivedItemsPayload.isEmpty) {
      _showToast('Set quantity > 0 for at least one item.', isError: true);
      return;
    }

    setState(() => _saving = true);

    try {
      final payload = {
        'purchase_order_id': poId,
        'received_items': receivedItemsPayload,
        'remarks': 'Received Order ${asStr(poData['purchase_number'])}',
        'created_by': 1,
      };

      final uri = Uri.parse('${ApiConfig.purchases}?action=receive_purchase');
      final response = await http.post(
        uri,
        headers: ApiConfig.jsonHeaders,
        body: json.encode(payload),
      );

      final res = json.decode(response.body);

      if (response.statusCode == 200 && res['success'] == true) {
        ref.read(inventoryRefreshProvider.notifier).state++;
        _showToast('Stock received & recorded successfully!', isError: false);

        final newPoId = res['data']?['child_po_id'];
        final newPoNumber = res['data']?['child_po_number'];
        if (newPoId != null && newPoNumber != null) {
          _showToast(
            'Original PO closed. Remaining items moved to new PO #$newPoNumber.',
            isError: false,
          );
        }

        await _fetchOrdersList();
        if (_expandedPoId == poId) {
          _poDetailsCache.remove(poId);
          _receivingMapPerPo.remove(poId);
          _priceControllers.remove(poId);
        }
      } else {
        _showToast(asStr(res['message'], 'Failed to stock in'), isError: true);
      }
    } catch (e) {
      _showToast('Network error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final pendingOrders = _allOrders.where((po) => _isPendingPO(po)).toList();
    final completedOrders = _allOrders.where((po) => _isCompletedPO(po)).toList();
    final currentList = _selectedTab == 0 ? pendingOrders : completedOrders;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.textPrimaryDark,
        surfaceTintColor: Colors.transparent,
        title: Text('Receive Orders', style: AppTextStyles.appBarTitle),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _fetchOrdersList,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loadingOrders
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTabs(pendingOrders.length, completedOrders.length),
                Expanded(
                  child: currentList.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: R.hPad(context, base: AppSpacing.lg).copyWith(
                            top: R.sp(context, AppSpacing.sm),
                            bottom: R.sp(context, AppSpacing.lg),
                          ),
                          itemCount: currentList.length,
                          itemBuilder: (context, index) {
                            final po = currentList[index];
                            final poId = asInt(po['id']);
                            final isExpanded = _expandedPoId == poId;
                            final isCompleted = _isCompletedPO(po);
                            final isLoading = _loadingDetailMap[poId] ?? false;
                            final poDetail = _poDetailsCache[poId];
                            final items = poDetail != null
                                ? List<Map<String, dynamic>>.from(poDetail['items'] ?? [])
                                : <Map<String, dynamic>>[];
                            final receivingMap = _receivingMapPerPo[poId] ?? {};
                            final priceCtrls = _priceControllers[poId] ?? {};

                            return _POCard(
                              po: po,
                              poDetail: poDetail,
                              isExpanded: isExpanded,
                              isLoading: isLoading,
                              items: items,
                              receivingMap: receivingMap,
                              priceControllers: priceCtrls,
                              onToggle: () => _toggleExpansion(poId),
                              onQtyChanged: (itemId, newQty) {
                                setState(() {
                                  final map = _receivingMapPerPo[poId];
                                  if (map != null) {
                                    final item = items.firstWhere(
                                      (i) => asInt(i['id']) == itemId,
                                    );
                                    map[itemId] = newQty.clamp(0, _outstandingOf(item));
                                  }
                                });
                              },
                              outstandingOf: _outstandingOf,
                              isCompleted: isCompleted,
                              onShowPriceHistory: _showPriceHistory,
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: _selectedTab == 0 &&
              _expandedPoId != null &&
              _poDetailsCache.containsKey(_expandedPoId) &&
              !(_loadingDetailMap[_expandedPoId] ?? false)
          ? _buildBottomBar(_expandedPoId!)
          : null,
    );
  }

  // ── Sub‑widgets ──
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _selectedTab == 0 ? Icons.inbox_outlined : Icons.task_alt_outlined,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          SizedBox(height: R.sp(context, AppSpacing.sm)),
          Text(
            _selectedTab == 0
                ? 'No pending purchase orders'
                : 'No completed purchase orders',
            style: AppTextStyles.small.copyWith(fontSize: R.fs(context, 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(int pending, int completed) {
    return Padding(
      padding: R.hPad(context, base: AppSpacing.lg)
          .copyWith(top: R.sp(context, AppSpacing.sm), bottom: R.sp(context, AppSpacing.sm)),
      child: SegmentedButton<int>(
        segments: [
          ButtonSegment<int>(
            value: 0,
            label: Text('Pending ($pending)'),
          ),
          ButtonSegment<int>(
            value: 1,
            label: Text('Completed ($completed)'),
          ),
        ],
        selected: {_selectedTab},
        onSelectionChanged: (Set<int> newSelection) {
          setState(() => _selectedTab = newSelection.first);
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.primary;
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return AppColors.textSecondary;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return const BorderSide(color: Colors.transparent);
            return BorderSide(color: AppColors.border);
          }),
          shape: WidgetStateProperty.resolveWith((states) {
            return RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusMd)),
            );
          }),
          textStyle: WidgetStateProperty.resolveWith((states) {
            return TextStyle(fontWeight: FontWeight.w600, fontSize: R.fs(context, 13));
          }),
        ),
      ),
    );
  }

  Widget _buildBottomBar(int poId) {
    final total = _getTotalReceivingForPo(poId);
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(R.sp(context, AppSpacing.lg)),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL TO RECEIVE',
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: R.fs(context, 10),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  SizedBox(height: R.sp(context, 2)),
                  Text(
                    '$total Units',
                    style: AppTextStyles.cardValue.copyWith(fontSize: R.fs(context, 18)),
                  ),
                ],
              ),
            ),
            SizedBox(width: R.sp(context, AppSpacing.md)),
            SizedBox(
              height: R.btnH(context),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusMd)),
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: R.sp(context, AppSpacing.xl)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusMd)),
                    ),
                  ),
                  onPressed: (_saving || !_hasOutstandingForPo(poId))
                      ? null
                      : () => _confirmAndStockIn(poId),
                  icon: _saving
                      ? SizedBox(
                          width: R.icon(context, 20),
                          height: R.icon(context, 20),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Icon(Icons.check_circle_outline,
                          color: Colors.white, size: R.icon(context, 20)),
                  label: Text(
                    _saving ? 'Saving…' : 'Confirm Stock-In',
                    style: AppTextStyles.button.copyWith(fontSize: R.fs(context, 14)),
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
// PO Card (Expandable)
// ============================================================================
class _POCard extends StatefulWidget {
  final Map<String, dynamic> po;
  final Map<String, dynamic>? poDetail;
  final bool isExpanded;
  final bool isLoading;
  final List<Map<String, dynamic>> items;
  final Map<int, int> receivingMap;
  final Map<int, TextEditingController> priceControllers;
  final VoidCallback onToggle;
  final Function(int, int) onQtyChanged;
  final int Function(Map<String, dynamic>) outstandingOf;
  final bool isCompleted;
  final Function(int, String) onShowPriceHistory;

  const _POCard({
    required this.po,
    this.poDetail,
    required this.isExpanded,
    required this.isLoading,
    required this.items,
    required this.receivingMap,
    required this.priceControllers,
    required this.onToggle,
    required this.onQtyChanged,
    required this.outstandingOf,
    required this.isCompleted,
    required this.onShowPriceHistory,
  });

  @override
  State<_POCard> createState() => _POCardState();
}

class _POCardState extends State<_POCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightFactor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightFactor = _controller.drive(
      CurveTween(curve: Curves.easeInOut),
    );
    if (widget.isExpanded) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant _POCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      widget.isExpanded ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final poId = asInt(widget.po['id']);
    final poNumber = asStr(widget.po['purchase_number'], 'PO-$poId');
    final supplier = asStr(widget.po['supplier_name'], 'Supplier');
    final total = widget.po['grand_total'] != null ? '₹${widget.po['grand_total']}' : null;
    final parentPo = widget.po['parent_po_number'] != null
        ? 'Remainder from ${widget.po['parent_po_number']}'
        : '';
    final hasPartial = widget.po['has_partial'] == true;
    final childPoNumber = widget.po['child_po_number'] ?? '';

    final subtotal = widget.poDetail != null ? asDouble(widget.poDetail!['subtotal']) : 0.0;
    final tax = widget.poDetail != null ? asDouble(widget.poDetail!['tax_amount']) : 0.0;
    final discount = widget.poDetail != null ? asDouble(widget.poDetail!['discount_amount']) : 0.0;
    final shipping = widget.poDetail != null ? asDouble(widget.poDetail!['shipping_charge']) : 0.0;
    final grandTotal = widget.poDetail != null ? asDouble(widget.poDetail!['grand_total']) : 0.0;
    double calculatedGrandTotal = grandTotal;

if (!widget.isCompleted && widget.items.isNotEmpty) {
  calculatedGrandTotal = 0;

  for (final item in widget.items) {
    final itemId = asInt(item['id']);

    final qty = widget.receivingMap[itemId] ?? 0;

    double price = asDouble(item['unitPrice']);

    final controller = widget.priceControllers[itemId];
    if (controller != null) {
      final parsed = double.tryParse(controller.text.trim());
      if (parsed != null) {
        price = parsed;
      }
    }

    calculatedGrandTotal += qty * price;
  }
}

    return Container(
      margin: EdgeInsets.only(bottom: R.sp(context, AppSpacing.sm)),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusLg)),
        border: Border.all(
          color: widget.isExpanded ? AppColors.primary.withValues(alpha: 0.35) : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onToggle,
              borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusLg)),
              child: Padding(
                padding: EdgeInsets.all(R.sp(context, AppSpacing.lg)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
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
                              if (parentPo.isNotEmpty)
                                Text(
                                  parentPo,
                                  style: AppTextStyles.small.copyWith(
                                    fontSize: R.fs(context, 11),
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (total != null) ...[
                          SizedBox(width: R.sp(context, AppSpacing.sm)),
                          Text(
                            total,
                            style: AppTextStyles.cardValue.copyWith(fontSize: R.fs(context, 14)),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: R.sp(context, AppSpacing.xs)),
                    Row(
                      children: [
                        Icon(Icons.storefront_outlined,
                            size: R.icon(context, 13), color: AppColors.textSecondary),
                        SizedBox(width: R.sp(context, 4)),
                        Expanded(
                          child: Text(
                            supplier,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.small.copyWith(fontSize: R.fs(context, 12)),
                          ),
                        ),
                        SizedBox(width: R.sp(context, AppSpacing.sm)),
                        if (widget.isCompleted) ...[
                          if (hasPartial) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: R.sp(context, AppSpacing.sm),
                                vertical: R.sp(context, 3),
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusSm)),
                              ),
                              child: Text(
                                'Partially Received',
                                style: TextStyle(
                                  fontSize: R.fs(context, 9),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.orange,
                                ),
                              ),
                            ),
                            if (childPoNumber.isNotEmpty) ...[
                              SizedBox(width: R.sp(context, AppSpacing.xs)),
                              Text(
                                '→ $childPoNumber',
                                style: TextStyle(
                                  fontSize: R.fs(context, 10),
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ] else ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: R.sp(context, AppSpacing.sm),
                                vertical: R.sp(context, 3),
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusSm)),
                              ),
                              child: Text(
                                'RECEIVED',
                                style: TextStyle(
                                  fontSize: R.fs(context, 10),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                  color: AppColors.green,
                                ),
                              ),
                            ),
                          ],
                        ],
                        SizedBox(width: R.sp(context, AppSpacing.xs)),
                        Icon(
                          widget.isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary,
                          size: R.icon(context, 22),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

// ── Expanded Content ──
SizeTransition(
  sizeFactor: _heightFactor,
  child: widget.isLoading
      ? Padding(
          padding: EdgeInsets.all(R.sp(context, AppSpacing.lg)),
          child: const Center(child: CircularProgressIndicator()),
        )
      : widget.items.isEmpty
          ? Padding(
              padding: EdgeInsets.all(R.sp(context, AppSpacing.lg)),
              child: Text(
                'No items in this order',
                style: AppTextStyles.small.copyWith(
                  fontSize: R.fs(context, 12),
                ),
              ),
            )
          : Padding(
              padding: EdgeInsets.fromLTRB(
                R.sp(context, AppSpacing.lg),
                0,
                R.sp(context, AppSpacing.lg),
                R.sp(context, AppSpacing.md),
              ),
              child: Column(
                children: [
                  Divider(
                    color: AppColors.border,
                    height: R.sp(context, AppSpacing.md),
                  ),

                  ...widget.items.map((item) {
                    final itemId = asInt(item['id']);
                    final outstanding = widget.outstandingOf(item);

                    if (widget.isCompleted || outstanding <= 0) {
                      return _CompletedItemTile(
                        item: item,
                        onShowPriceHistory: widget.onShowPriceHistory,
                      );
                    }

                    return _ReceivingItemTile(
                      item: item,
                      outstanding: outstanding,
                      currentQty: widget.receivingMap[itemId] ?? 0,
                      priceController: widget.priceControllers[itemId],
                      onQtyChanged: (newQty) =>
                          widget.onQtyChanged(itemId, newQty),
                      onShowPriceHistory: widget.onShowPriceHistory,
                    );
                  }).toList(),

                  const SizedBox(height: 6),

                  // ── Grand Total Only ──
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: R.sp(context, AppSpacing.md),
                      vertical: R.sp(context, 10),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(
                        R.radius(context, AppSizes.radiusMd),
                      ),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: _SummaryRow(
                      label: 'Grand Total',
                      value: widget.isCompleted
                          ? grandTotal
                          : calculatedGrandTotal,
                      isBold: true,
                    ),
                  ),
                ],
              ),
            ),
),
        ],
      ),
    );
  }
}

// ── Summary Row ──
class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isNegative;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isNegative = false,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: R.sp(context, 2)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.small.copyWith(
              fontSize: R.fs(context, 12),
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              color: isBold ? AppColors.textPrimaryDark : AppColors.textSecondary,
            ),
          ),
          Text(
            '${isNegative ? '- ' : ''}₹${value.toStringAsFixed(2)}',
            style: AppTextStyles.small.copyWith(
              fontSize: R.fs(context, 13),
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold ? AppColors.textPrimaryDark : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Receiving Item Tile – editable quantity and price
// ============================================================================
class _ReceivingItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final int outstanding;
  final int currentQty;
  final TextEditingController? priceController;
  final ValueChanged<int> onQtyChanged;
  final Function(int, String) onShowPriceHistory;

  const _ReceivingItemTile({
    required this.item,
    required this.outstanding,
    required this.currentQty,
    this.priceController,
    required this.onQtyChanged,
    required this.onShowPriceHistory,
  });

  @override
  Widget build(BuildContext context) {
    final name = asStr(item['name']);
    final sku = asStr(item['sku']);
    final unit = asStr(item['unit'], 'pcs');
    final productId = asInt(item['productId']);
    final unitPrice = asDouble(item['unitPrice']);

    double currentPrice = unitPrice;
    if (priceController != null) {
      final text = priceController!.text.trim();
      if (text.isNotEmpty) {
        final parsed = double.tryParse(text);
        if (parsed != null && parsed > 0) currentPrice = parsed;
      }
    }
    final lineTotal = currentQty * currentPrice;

    return Container(
      margin: EdgeInsets.only(bottom: R.sp(context, AppSpacing.sm)),
      padding: EdgeInsets.symmetric(
          horizontal: R.sp(context, AppSpacing.md), vertical: R.sp(context, AppSpacing.sm)),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusMd)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: R.fs(context, 14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.history, size: R.icon(context, 16), color: AppColors.primary),
                onPressed: () => onShowPriceHistory(productId, name),
                tooltip: 'View price history',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: R.sp(context, 4)),
          Row(
            children: [
              if (sku.isNotEmpty) ...[
                Text(
                  'SKU: $sku',
                  style: AppTextStyles.small.copyWith(fontSize: R.fs(context, 11)),
                ),
                SizedBox(width: R.sp(context, AppSpacing.sm)),
              ],
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: R.sp(context, 6), vertical: R.sp(context, 2)),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusSm)),
                ),
                child: Text(
                  'Bal: $outstanding $unit',
                  style: TextStyle(
                    fontSize: R.fs(context, 10.5),
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: R.sp(context, AppSpacing.sm)),
          // Price and quantity row
Row(
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    // ---------------- Unit Price ----------------
    Expanded(
      flex: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unit Price (₹)',
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: R.fs(context, 10),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: priceController,
            onChanged: (_) {
              (context as Element).markNeedsBuild();
            },
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppColors.card,
              contentPadding: EdgeInsets.symmetric(
                horizontal: R.sp(context, 12),
                vertical: R.sp(context, 10),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  R.radius(context, AppSizes.radiusSm),
                ),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  R.radius(context, AppSizes.radiusSm),
                ),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  R.radius(context, AppSizes.radiusSm),
                ),
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 1.3,
                ),
              ),
            ),
            style: TextStyle(
              fontSize: R.fs(context, 15),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryDark,
            ),
          ),
        ],
      ),
    ),

    SizedBox(width: R.sp(context, 12)),

    // ---------------- Quantity ----------------
    SizedBox(
      width: 90,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Qty',
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: R.fs(context, 10),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: currentQty > 0
                    ? () => onQtyChanged(currentQty - 1)
                    : null,
                child: Icon(
                  Icons.remove_circle_outline,
                  size: 22,
                  color: currentQty > 0
                      ? AppColors.primary
                      : AppColors.textSecondary.withValues(alpha: 0.4),
                ),
              ),

              Text(
                '$currentQty',
                style: AppTextStyles.cardValue.copyWith(
                  fontSize: R.fs(context, 15),
                  fontWeight: FontWeight.w600,
                ),
              ),

              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: currentQty < outstanding
                    ? () => onQtyChanged(currentQty + 1)
                    : null,
                child: Icon(
                  Icons.add_circle_outline,
                  size: 22,
                  color: currentQty < outstanding
                      ? AppColors.primary
                      : AppColors.textSecondary.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    ),

    const Spacer(),

    // ---------------- Total ----------------
    SizedBox(
      width: 60,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Total',
            style: AppTextStyles.small.copyWith(
              fontSize: R.fs(context, 9),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              '₹${lineTotal.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: R.fs(context, 15),
                color: AppColors.textPrimaryDark,
              ),
            ),
          ),
        ],
      ),
    ),
  ],
),
        ],
      ),
    );
  }
}

// ============================================================================
// Completed Item Tile – shows actual received price with optional note
// ============================================================================
class _CompletedItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final Function(int, String) onShowPriceHistory;

  const _CompletedItemTile({
    required this.item,
    required this.onShowPriceHistory,
  });

  @override
  Widget build(BuildContext context) {
    final name = asStr(item['name']);
    final receivedQty = asInt(item['receivedQty']);
    final unit = asStr(item['unit'], 'pcs');
    final productId = asInt(item['productId']);
    // Use actual received unit price if available
    final unitPrice = asDouble(item['actualReceivedUnitPrice'] ?? item['unitPrice'] ?? 0.0);
    final orderedPrice = asDouble(item['unitPrice'] ?? 0.0);
    final totalReceived = receivedQty * unitPrice;
    final priceDiffers = (orderedPrice - unitPrice).abs() > 0.01;

    return Container(
      margin: EdgeInsets.only(bottom: R.sp(context, AppSpacing.sm)),
      padding: EdgeInsets.symmetric(
          horizontal: R.sp(context, AppSpacing.md), vertical: R.sp(context, AppSpacing.sm)),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusMd)),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.green, size: R.icon(context, 18)),
          SizedBox(width: R.sp(context, AppSpacing.sm)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: R.fs(context, 13),
                          color: AppColors.textPrimaryDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.history, size: R.icon(context, 16), color: AppColors.primary),
                      onPressed: () => onShowPriceHistory(productId, name),
                      tooltip: 'View price history',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Text(
                  '$receivedQty $unit × ₹${unitPrice.toStringAsFixed(2)} = ₹${totalReceived.toStringAsFixed(2)}',
                  style: AppTextStyles.small.copyWith(
                    fontSize: R.fs(context, 11),
                    color: AppColors.textSecondary,
                  ),
                ),
                if (priceDiffers)
                  Text(
                    '(Ordered @ ₹${orderedPrice.toStringAsFixed(2)})',
                    style: AppTextStyles.small.copyWith(
                      fontSize: R.fs(context, 10),
                      color: AppColors.orange,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: R.sp(context, AppSpacing.sm), vertical: R.sp(context, 3)),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusSm)),
            ),
            child: Text(
              '$receivedQty $unit received',
              style: TextStyle(
                fontSize: R.fs(context, 10.5),
                fontWeight: FontWeight.w700,
                color: AppColors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Price History Modal
// ============================================================================
class _PriceHistoryModal extends StatelessWidget {
  final String productName;
  final List<Map<String, dynamic>> history;

  const _PriceHistoryModal({
    required this.productName,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: EdgeInsets.all(R.sp(context, AppSpacing.lg)),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: R.sp(context, 40),
              height: R.sp(context, 4),
              margin: EdgeInsets.only(bottom: R.sp(context, AppSpacing.md)),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Text(
            'Price History – $productName',
            style: AppTextStyles.heading.copyWith(fontSize: R.fs(context, 18)),
          ),
          SizedBox(height: R.sp(context, AppSpacing.sm)),
          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Text(
                      'No price history found',
                      style: AppTextStyles.small,
                    ),
                  )
                : ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (ctx, index) {
                      final entry = history[index];
                      final date = entry['date']?.toString() ?? '';
                      final supplier = entry['supplier']?.toString() ?? 'Supplier';
                      final unitPrice = asDouble(entry['unit_price']);
                      final quantity = asInt(entry['quantity']);
                      final poNumber = entry['po_number']?.toString() ?? 'PO-';
                      final source = entry['source']?.toString() ?? 'ordered';
                      final isReceived = source == 'received';
                      final total = unitPrice * quantity;

                      return Container(
                        margin: EdgeInsets.only(bottom: R.sp(context, AppSpacing.sm)),
                        padding: EdgeInsets.all(R.sp(context, AppSpacing.md)),
                        decoration: BoxDecoration(
                          color: isReceived ? AppColors.green.withValues(alpha: 0.05) : AppColors.background,
                          borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusMd)),
                          border: Border.all(
                            color: isReceived ? AppColors.green.withValues(alpha: 0.3) : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        poNumber,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: R.fs(context, 13),
                                          color: AppColors.textPrimaryDark,
                                        ),
                                      ),
                                      SizedBox(width: R.sp(context, AppSpacing.sm)),
                                      Text(
                                        date,
                                        style: AppTextStyles.small.copyWith(fontSize: R.fs(context, 11)),
                                      ),
                                      if (isReceived) ...[
                                        SizedBox(width: R.sp(context, AppSpacing.sm)),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: R.sp(context, 6),
                                            vertical: R.sp(context, 1),
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.green.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Received',
                                            style: TextStyle(
                                              fontSize: R.fs(context, 9),
                                              color: AppColors.green,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ] else ...[
                                        SizedBox(width: R.sp(context, AppSpacing.sm)),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: R.sp(context, 6),
                                            vertical: R.sp(context, 1),
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Ordered',
                                            style: TextStyle(
                                              fontSize: R.fs(context, 9),
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  SizedBox(height: R.sp(context, 2)),
                                  Text(
                                    supplier,
                                    style: AppTextStyles.small.copyWith(fontSize: R.fs(context, 12)),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${unitPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: R.fs(context, 14),
                                    color: AppColors.textPrimaryDark,
                                  ),
                                ),
                                Text(
                                  '$quantity units · ₹${total.toStringAsFixed(2)}',
                                  style: AppTextStyles.small.copyWith(fontSize: R.fs(context, 11)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}