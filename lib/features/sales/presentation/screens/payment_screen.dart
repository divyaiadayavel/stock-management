import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/storage/db_helper.dart';
import 'invoice_screen.dart';
import '../providers/billing_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final double totalAmount;
  final String invoiceNumber;
  final int invoiceId;
  final double? gstAmount;

  const PaymentScreen({
    super.key,
    required this.totalAmount,
    required this.invoiceNumber,
    required this.invoiceId,
    this.gstAmount,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  late TextEditingController _cashCtrl;
  late TextEditingController _upiCtrl;
  Map<String, dynamic>? _selectedCustomer;
  bool _saving = false;

  double get _gst =>
      widget.gstAmount ?? (widget.totalAmount - widget.totalAmount / 1.18);

  double get _cash => double.tryParse(_cashCtrl.text) ?? 0;
  double get _upi => double.tryParse(_upiCtrl.text) ?? 0;
  double get _tendered => _cash + _upi;
  double get _change =>
      _tendered > widget.totalAmount ? _tendered - widget.totalAmount : 0;
  double get _balanceDue =>
      _tendered < widget.totalAmount ? widget.totalAmount - _tendered : 0;

  @override
  void initState() {
    super.initState();
    _cashCtrl = TextEditingController(
      text: widget.totalAmount.toStringAsFixed(0),
    );
    _upiCtrl = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _cashCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCustomer() async {
    final customers = await DBHelper.getCustomers();
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
            top: R.sp(ctx, AppSpacing.lg),
            bottom:
                MediaQuery.of(ctx).viewInsets.bottom + R.sp(ctx, AppSpacing.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: R.sp(ctx, AppSpacing.screenPadding),
                ),
                child: Text(
                  'Select customer',
                  style: AppTextStyles.sectionTitle,
                ),
              ),
              SizedBox(height: R.sp(ctx, AppSpacing.sm)),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: customers.length,
                  itemBuilder: (_, i) {
                    final c = customers[i];
                    return ListTile(
                      title: Text(
                        c['name']?.toString() ?? '',
                        style: AppTextStyles.cardValue,
                      ),
                      onTap: () => Navigator.pop(ctx, c),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _selectedCustomer = picked);
  }

  Future<void> _confirmAndPrint() async {
    setState(() => _saving = true);

    try {
      await DBHelper.recordSplitPayment(
        invoiceId: widget.invoiceId,
        cashAmount: _cash,
        upiAmount: _upi,
        balanceDue: _balanceDue,
        customerId: _selectedCustomer?['id'],
        customerName: _selectedCustomer?['name'],
      );

      if (!mounted) return;

      ref.read(billingProvider.notifier).clearCart();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InvoiceScreen(
            invoiceId: widget.invoiceId,
            customerName: _selectedCustomer?['name'] ?? 'Walk-in Customer',
            balanceDue: _balanceDue,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not confirm payment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text('Payment', style: AppTextStyles.heading),
      ),
      body: SingleChildScrollView(
        padding: R
            .hPad(context, base: AppSpacing.screenPadding)
            .copyWith(
              top: R.sp(context, AppSpacing.md),
              bottom: R.sp(context, AppSpacing.xl),
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Total payable card ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(R.sp(context, AppSpacing.lg)),
              decoration: BoxDecoration(
                color: AppColors.textPrimaryDark,
                borderRadius: BorderRadius.circular(
                  R.radius(context, AppSizes.cardRadius),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL PAYABLE',
                    style: AppTextStyles.small.copyWith(
                      color: Colors.white70,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: R.sp(context, AppSpacing.xs)),
                  Text(
                    '₹${widget.totalAmount.toStringAsFixed(0)}',
                    style: AppTextStyles.heading.copyWith(
                      color: Colors.white,
                      fontSize: R.fs(context, 30),
                    ),
                  ),
                  SizedBox(height: R.sp(context, AppSpacing.xs)),
                  Text(
                    'incl ₹${_gst.toStringAsFixed(0)} GST · ${widget.invoiceNumber}',
                    style: AppTextStyles.small.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),

            SizedBox(height: R.sp(context, AppSpacing.lg)),

            // ── Customer ──
            Text(
              'Customer',
              style: AppTextStyles.small.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: R.sp(context, AppSpacing.xs)),
            GestureDetector(
              onTap: _pickCustomer,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: R.sp(context, AppSpacing.md),
                  vertical: R.sp(context, AppSpacing.md),
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(
                    R.radius(context, AppSizes.radiusMd),
                  ),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCustomer?['name']?.toString() ??
                          'Walk-in Customer',
                      style: AppTextStyles.cardValue.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                      size: R.icon(context, AppSizes.iconMd),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: R.sp(context, AppSpacing.lg)),

            // ── Split tender ──
            Text('Split tender', style: AppTextStyles.sectionTitle),
            SizedBox(height: R.sp(context, AppSpacing.sm)),

            _TenderField(
              label: 'Cash',
              controller: _cashCtrl,
              onChanged: () => setState(() {}),
            ),
            SizedBox(height: R.sp(context, AppSpacing.sm)),
            _TenderField(
              label: 'UPI',
              controller: _upiCtrl,
              onChanged: () => setState(() {}),
            ),

            SizedBox(height: R.sp(context, AppSpacing.sm)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cash tendered ₹${_cash.toStringAsFixed(0)}',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Change ₹${_change.toStringAsFixed(0)}',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            if (_balanceDue > 0) ...[
              SizedBox(height: R.sp(context, AppSpacing.sm)),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: R.sp(context, AppSpacing.md),
                  vertical: R.sp(context, AppSpacing.sm + 2),
                ),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(
                    R.radius(context, AppSizes.radiusMd),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Balance due (credit)',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '₹${_balanceDue.toStringAsFixed(0)}',
                      style: AppTextStyles.cardValue.copyWith(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: R.sp(context, AppSpacing.xxl)),

            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: R.icon(context, AppSizes.iconSm),
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: R.sp(context, AppSpacing.xs)),
                  Text(
                    'Secure 256-bit encrypted transaction',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: R.sp(context, AppSpacing.lg)),
          ],
        ),
      ),

      // ── Bottom buttons ──
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: R
              .hPad(context, base: AppSpacing.screenPadding)
              .copyWith(
                top: R.sp(context, AppSpacing.sm),
                bottom: R.sp(context, AppSpacing.sm),
              ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: R.btnH(context),
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.border),
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
              ),
              SizedBox(width: R.sp(context, AppSpacing.sm)),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: R.btnH(context),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(
                        R.radius(context, AppSizes.radiusMd),
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: _saving ? null : _confirmAndPrint,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            R.radius(context, AppSizes.radiusMd),
                          ),
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
                              'Confirm & print invoice',
                              style: AppTextStyles.button.copyWith(
                                color: Colors.white,
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

class _TenderField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _TenderField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: R.sp(context, AppSpacing.md),
        vertical: R.sp(context, AppSpacing.sm),
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(
          R.radius(context, AppSizes.radiusMd),
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.cardValue.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text('₹', style: AppTextStyles.cardValue),
          SizedBox(
            width: R.sp(context, 100),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: AppTextStyles.cardValue.copyWith(
                fontWeight: FontWeight.w600,
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
    );
  }
}
