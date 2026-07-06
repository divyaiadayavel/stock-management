// =========================================================
// lib/screens/stock_out_screen.dart
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

class StockOutScreen extends ConsumerStatefulWidget {
  const StockOutScreen({super.key});

  @override
  ConsumerState<StockOutScreen> createState() => _StockOutScreenState();
}

class _StockOutScreenState extends ConsumerState<StockOutScreen> {
  final List<String> _reasons = [
    'Damage',
    'Theft / loss',
    'Sample',
    'Internal use',
  ];
  String _selectedReason = 'Damage';

  Map<String, dynamic>? _selectedProduct;
  final TextEditingController _productCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  String _warehouse = 'Main store';
  bool _saving = false;

  int get _enteredQty => int.tryParse(_qtyCtrl.text) ?? 0;
  double get _writeOffValue {
    final price =
        (_selectedProduct?['purchase_price'] as num?)?.toDouble() ?? 0.0;
    return price * _enteredQty;
  }

  // Threshold above which we flag "needs owner approval"
  static const double _largeWriteOffThreshold = 5000;

  @override
  void dispose() {
    _productCtrl.dispose();
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedProduct == null || _enteredQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a product and enter quantity')),
      );
      return;
    }
    if (_noteCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note is required for write-off')),
      );
      return;
    }

    final currentQty = (_selectedProduct!['quantity'] as num).toInt();
    if (_enteredQty > currentQty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Not enough stock on hand')));
      return;
    }

    setState(() => _saving = true);

    final ok = await DBHelper.stockOutTransaction(
      productId: _selectedProduct!['id'] as int,
      quantity: _enteredQty,
      reason: _selectedReason,
      note: _noteCtrl.text.trim(),
      warehouse: _warehouse,
    );

    setState(() => _saving = false);

    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Stock out failed')));
      }
      return;
    }

    refreshInventory(ref);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(productSearchResultsProvider);
    final isLargeWriteOff = _writeOffValue >= _largeWriteOffThreshold;

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
        title: Text('Stock Out', style: AppTextStyles.heading),
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
            // ── CHANGED: Made "Reason" label larger and bolder
            Text(
              'Reason',
              style: AppTextStyles.cardTitle.copyWith(
                fontSize: R.fs(context, 16),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryDark,
              ),
            ),
            SizedBox(height: R.sp(context, AppSpacing.xs)),

            // ── CHANGED: Tighter chip padding and adjusted Wrap spacing
            Wrap(
              spacing: R.sp(context, 6),
              runSpacing: R.sp(context, 8),
              children: _reasons.map((r) {
                final selected = _selectedReason == r;
                return GestureDetector(
                  onTap: () => setState(() => _selectedReason = r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: R.sp(context, 10), // reduced padding
                      vertical: R.sp(context, 6), // reduced padding
                    ),
                    decoration: BoxDecoration(
                      gradient: selected ? AppColors.brandGradient : null,
                      color: selected ? null : AppColors.card,
                      borderRadius: BorderRadius.circular(
                        R.radius(context, 50),
                      ),
                      border: Border.all(
                        color: selected ? Colors.transparent : AppColors.border,
                      ),
                    ),
                    child: Text(
                      r,
                      style: AppTextStyles.small.copyWith(
                        color: selected
                            ? AppColors.textWhite
                            : AppColors.textSecondary,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: R.fs(
                          context,
                          11,
                        ), // slightly smaller text to fit
                      ),
                    ),
                  ),
                );
              }).toList(),
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
                                '− 0 ${_selectedProduct?['unit'] ?? 'unit'}',
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
              ],
            ),

            SizedBox(height: R.sp(context, AppSpacing.lg)),
            _Label('Note (required for write-off)'),
            SizedBox(height: R.sp(context, AppSpacing.xs)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: R.sp(context, AppSpacing.md),
                vertical: R.sp(context, 10),
              ),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(
                  R.radius(context, AppSizes.radiusMd),
                ),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _noteCtrl,
                minLines: 2,
                maxLines: 3,
                style: AppTextStyles.cardValue,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'e.g. Water damage during transit',
                ),
              ),
            ),

            if (_selectedProduct != null && _enteredQty > 0) ...[
              SizedBox(height: R.sp(context, AppSpacing.lg)),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(R.sp(context, AppSpacing.cardPadding)),
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(
                    R.radius(context, AppSizes.radiusMd),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Write-off value',
                      style: AppTextStyles.small.copyWith(color: AppColors.red),
                    ),
                    SizedBox(height: R.sp(context, 4)),
                    Text(
                      '₹${_writeOffValue.toStringAsFixed(0)}',
                      style: AppTextStyles.cardValue.copyWith(
                        color: AppColors.red,
                        fontSize: R.fs(context, 18),
                      ),
                    ),
                    if (isLargeWriteOff) ...[
                      SizedBox(height: R.sp(context, 4)),
                      Text(
                        'Large write-off — needs owner approval',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.red,
                        ),
                      ),
                    ],
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
                // ── CHANGED: Replaced background color with AppColors.brandGradient using Ink
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(
                      R.radius(context, AppSizes.radiusMd),
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.transparent, // Let gradient show through
                      shadowColor: Colors.transparent,
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
                            isLargeWriteOff
                                ? 'Submit for approval'
                                : 'Confirm stock out',
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
