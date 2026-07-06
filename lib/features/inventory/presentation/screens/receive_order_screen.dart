// =========================================================
// lib/features/inventory/presentation/screens/receive_order_screen.dart
// =========================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/db_helper.dart';
import '../../../../core/utils/responsive_helper.dart';

class ReceiveOrderScreen extends ConsumerStatefulWidget {
  final int poId;
  const ReceiveOrderScreen({super.key, required this.poId});

  @override
  ConsumerState<ReceiveOrderScreen> createState() =>
      _ReceiveOrderScreenState();
}

class _ReceiveOrderScreenState extends ConsumerState<ReceiveOrderScreen> {
  Map<String, dynamic>? _po;
  List<Map<String, dynamic>> _items = [];
  Map<int, TextEditingController> _receivedCtrls = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final po = await DBHelper.getPurchaseOrderDetail(widget.poId);
    setState(() {
      _po = po;
      _items = List<Map<String, dynamic>>.from(po['items']);
      _receivedCtrls = {
        for (final item in _items)
          item['id'] as int: TextEditingController(
            text: (item['receivedQty'] ?? item['orderedQty']).toString(),
          ),
      };
      _loading = false;
    });
  }

  @override
  void dispose() {
    for (final c in _receivedCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  int _shortBy(Map<String, dynamic> item) {
    final ordered = item['orderedQty'] as int;
    final received =
        int.tryParse(_receivedCtrls[item['id']]!.text) ?? ordered;
    return (ordered - received).clamp(0, ordered);
  }

  int get _totalShort =>
      _items.fold(0, (sum, item) => sum + _shortBy(item));

  Future<void> _reportIssue() async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Report issue',
          style: TextStyle(
            fontSize: R.fs(ctx, 16),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: noteCtrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Describe the issue…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DBHelper.reportPurchaseOrderIssue(
        poId: widget.poId,
        note: noteCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Issue reported')));
      }
    }
  }

  Future<void> _confirmAndStockIn() async {
    setState(() => _saving = true);
    final receivedItems = _items
        .map((item) => {
              'id': item['id'],
              'productId': item['productId'],
              'receivedQty':
                  int.tryParse(_receivedCtrls[item['id']]!.text) ??
                      item['orderedQty'],
            })
        .toList();

    await DBHelper.receivePurchaseOrder(
      poId: widget.poId,
      items: receivedItems,
    );

    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Stock updated')));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final poNumber = 'PO-${widget.poId.toString().padLeft(4, '0')}';
    final orderedDate = _po!['orderedAt'] != null
        ? DateFormat('d MMM').format(DateTime.parse(_po!['orderedAt']))
        : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
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
                  'Receive · $poNumber',
                  style: TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: R.fs(context, 18),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: R.sp(context, 16)),

            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: R.sp(context, 14),
                vertical: R.sp(context, 12),
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(R.radius(context, 10)),
              ),
              child: Text(
                '${_po!['supplierName'] ?? ''} · ordered $orderedDate',
                style: TextStyle(
                  fontSize: R.fs(context, 13),
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),

            SizedBox(height: R.sp(context, 16)),

            ..._items.map((item) => _ReceiveItemTile(
                  item: item,
                  controller: _receivedCtrls[item['id']]!,
                  onChanged: () => setState(() {}),
                )),

            if (_totalShort > 0) ...[
              SizedBox(height: R.sp(context, 8)),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: R.sp(context, 14),
                  vertical: R.sp(context, 12),
                ),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(R.radius(context, 10)),
                ),
                child: Text(
                  '$_totalShort item${_totalShort == 1 ? '' : 's'} short — PO stays open for the balance.',
                  style: TextStyle(
                    fontSize: R.fs(context, 12),
                    fontWeight: FontWeight.w500,
                    color: AppColors.orange,
                  ),
                ),
              ),
            ],
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
                    onPressed: _saving ? null : _reportIssue,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(R.radius(context, 10)),
                      ),
                    ),
                    child: Text(
                      'Report issue',
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
                      borderRadius:
                          BorderRadius.circular(R.radius(context, 10)),
                    ),
                    child: ElevatedButton(
                      onPressed: _saving ? null : _confirmAndStockIn,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(R.radius(context, 10)),
                        ),
                      ),
                      child: _saving
                          ? SizedBox(
                              width: R.sp(context, 18),
                              height: R.sp(context, 18),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Confirm & stock in',
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

class _ReceiveItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _ReceiveItemTile({
    required this.item,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ordered = item['orderedQty'] as int;
    final received = int.tryParse(controller.text) ?? ordered;
    final isFull = received >= ordered;
    final isPartial = received > 0 && received < ordered;

    final statusLabel = isFull ? 'Full' : (isPartial ? 'Partial' : 'Pending');
    final statusColor =
        isFull ? AppColors.green : (isPartial ? AppColors.orange : AppColors.red);

    return Container(
      margin: EdgeInsets.only(bottom: R.sp(context, 10)),
      padding: EdgeInsets.all(R.sp(context, 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(R.radius(context, 10)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item['name']?.toString() ?? '',
                style: TextStyle(
                  fontSize: R.fs(context, 14),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: R.sp(context, 8),
                  vertical: R.sp(context, 2),
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(R.radius(context, 6)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: R.fs(context, 10),
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: R.sp(context, 6)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ordered $ordered ${item['unit'] ?? ''}',
                style: TextStyle(
                  fontSize: R.fs(context, 12),
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                width: R.sp(context, 110),
                padding: EdgeInsets.symmetric(
                  horizontal: R.sp(context, 12),
                  vertical: R.sp(context, 4),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(R.radius(context, 20)),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Text(
                      'received ',
                      style: TextStyle(
                        fontSize: R.fs(context, 12),
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: R.fs(context, 13),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryDark,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => onChanged(),
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