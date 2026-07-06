// =========================================================
// lib/screens/stock_in_screen.dart
// =========================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';

import '../../../../core/storage/db_helper.dart';
import '../providers/inventory_providers.dart';

class StockInScreen extends ConsumerStatefulWidget {
  const StockInScreen({super.key});

  @override
  ConsumerState<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends ConsumerState<StockInScreen> {
  int _tab = 0; // 0 Receiving, 1 Return, 2 Opening
  final List<String> _tabs = ['Receiving', 'Return', 'Opening'];

  Map<String, dynamic>? _selectedProduct;
  final TextEditingController _productCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _costCtrl = TextEditingController();
  final TextEditingController _referenceCtrl = TextEditingController();
  String _warehouse = 'Main store';
  bool _saving = false;
  DateTime? _expiryDate;
  int get _currentQty => (_selectedProduct?['quantity'] as num?)?.toInt() ?? 0;
  int get _enteredQty => int.tryParse(_qtyCtrl.text) ?? 0;

  @override
  void dispose() {
    _productCtrl.dispose();
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    _referenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _confirm() async {
    if (_selectedProduct == null || _enteredQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a product and enter quantity')),
      );
      return;
    }
    setState(() => _saving = true);

    await DBHelper.stockInTransaction(
      productId: _selectedProduct!['id'] as int,
      quantity: _enteredQty,
      unitCost: double.tryParse(_costCtrl.text) ?? 0.0,
      reason: _tabs[_tab],
      reference: _referenceCtrl.text.trim(),
      warehouse: _warehouse,
    );

    refreshInventory(ref);
    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(productSearchResultsProvider);

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
        title: Text('Stock In', style: AppTextStyles.heading),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          R.sp(context, AppSpacing.screenPadding),
          0,
          R.sp(context, AppSpacing.screenPadding),
          R.sp(context, 120),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tabs ──
            Container(
              padding: EdgeInsets.all(R.sp(context, 4)),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(
                  R.radius(context, AppSizes.radiusMd),
                ),
              ),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final selected = _tab == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tab = i),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: R.sp(context, 8),
                        ),
                        decoration: BoxDecoration(
                          gradient: selected ? AppColors.brandGradient : null,
                          color: selected ? null : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            R.radius(context, AppSizes.radiusSm),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _tabs[i],
                          style: AppTextStyles.small.copyWith(
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: R.sp(context, AppSpacing.lg)),

            _Label('Product'),
            SizedBox(height: R.sp(context, AppSpacing.xs)),
            _BoxField(
              child: TextField(
                controller: _productCtrl,
                style: AppTextStyles.cardValue,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search product · SKU',
                ),
                onChanged: (v) {
                  ref.read(productSearchQueryProvider.notifier).state = v;
                  setState(() => _selectedProduct = null);
                },
              ),
            ),
            searchResults.when(
              data: (results) {
                if (results.isEmpty || _selectedProduct != null) {
                  return const SizedBox.shrink();
                }
                return Container(
                  margin: EdgeInsets.only(top: R.sp(context, 4)),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(
                      R.radius(context, AppSizes.radiusMd),
                    ),
                    border: Border.all(color: AppColors.border),
                  ),
                  constraints: BoxConstraints(maxHeight: R.sp(context, 200)),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: results.length,
                    itemBuilder: (context, i) {
                      final p = results[i];
                      return ListTile(
                        dense: true,
                        title: Text(
                          '${p['name']} · SKU-${p['id']}',
                          style: AppTextStyles.cardValue,
                        ),
                        subtitle: Text(
                          'on-hand ${p['quantity']} · ${p['unit'] ?? ''}',
                          style: AppTextStyles.small,
                        ),
                        onTap: () {
                          setState(() {
                            _selectedProduct = p;
                            _productCtrl.text = '${p['name']} · SKU-${p['id']}';
                            _costCtrl.text = (p['purchase_price'] ?? '')
                                .toString();
                          });
                          ref.read(productSearchQueryProvider.notifier).state =
                              '';
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            SizedBox(height: R.sp(context, AppSpacing.lg)),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Quantity'),
                      SizedBox(height: R.sp(context, AppSpacing.xs)),
                      _BoxField(
                        child: TextField(
                          controller: _qtyCtrl,
                          keyboardType: TextInputType.number,
                          style: AppTextStyles.cardValue,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText:
                                '+ 0 ${_selectedProduct?['unit'] ?? 'unit'}',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: R.sp(context, AppSpacing.sm)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Unit cost'),
                      SizedBox(height: R.sp(context, AppSpacing.xs)),
                      _BoxField(
                        child: TextField(
                          controller: _costCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: AppTextStyles.cardValue,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '₹ 0',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: R.sp(context, AppSpacing.lg)),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Warehouse'),
                      SizedBox(height: R.sp(context, AppSpacing.xs)),
                      _BoxField(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _warehouse,
                            isExpanded: true,
                            style: AppTextStyles.cardValue,
                            items: ['Main store', 'Warehouse 2', 'Backroom']
                                .map(
                                  (w) => DropdownMenuItem(
                                    value: w,
                                    child: Text(w),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _warehouse = v ?? _warehouse),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: R.sp(context, AppSpacing.sm)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Batch / expiry'),
                      SizedBox(height: R.sp(context, AppSpacing.xs)),
                      GestureDetector(
                        onTap: _pickExpiryDate,
                        child: _BoxField(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _expiryDate == null
                                    ? 'Select expiry'
                                    : "${_expiryDate!.day.toString().padLeft(2, '0')}/"
                                          "${_expiryDate!.month.toString().padLeft(2, '0')}/"
                                          "${_expiryDate!.year}",
                                style: AppTextStyles.cardValue,
                              ),
                              Icon(
                                Icons.calendar_month_outlined,
                                color: AppColors.primary,
                                size: R.icon(context, 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: R.sp(context, AppSpacing.lg)),
            _Label('Reference (PO / supplier)'),
            SizedBox(height: R.sp(context, AppSpacing.xs)),
            _BoxField(
              child: TextField(
                controller: _referenceCtrl,
                style: AppTextStyles.cardValue,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'PO-0231 · Supplier name',
                ),
              ),
            ),

            if (_selectedProduct != null && _enteredQty > 0) ...[
              SizedBox(height: R.sp(context, AppSpacing.lg)),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(R.sp(context, AppSpacing.cardPadding)),
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    R.radius(context, AppSizes.radiusMd),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New on-hand',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.green,
                      ),
                    ),
                    SizedBox(height: R.sp(context, 4)),
                    Text(
                      '$_currentQty → ${_currentQty + _enteredQty} ${_selectedProduct?['unit'] ?? ''}',
                      style: AppTextStyles.cardValue.copyWith(
                        color: AppColors.green,
                        fontSize: R.fs(context, 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.all(R.sp(context, AppSpacing.screenPadding)),
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: R.sp(context, 14)),
                    side: BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        R.radius(context, AppSizes.radiusMd),
                      ),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                ),
              ),
              SizedBox(width: R.sp(context, AppSpacing.sm)),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(
                      R.radius(context, AppSizes.radiusMd),
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: _saving ? null : _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        vertical: R.sp(context, 14),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          R.radius(context, AppSizes.radiusMd),
                        ),
                      ),
                    ),
                    child: _saving
                        ? SizedBox(
                            height: R.sp(context, 18),
                            width: R.sp(context, 18),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Confirm stock in',
                            style: AppTextStyles.button.copyWith(
                              color: Colors.white,
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.cardTitle);
}

class _BoxField extends StatelessWidget {
  final Widget child;
  const _BoxField({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: R.sp(context, AppSpacing.md),
        vertical: R.sp(context, 4),
      ),
      height: R.sp(context, AppSizes.inputHeight + 8),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(
          R.radius(context, AppSizes.radiusMd),
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
