// lib/features/services/presentation/screens/provider_payment_screen.dart
//
// NEW FILE — additive only.
//
// The provider-recharge equivalent of Sales' PaymentScreen in its
// "settling an existing balance" mode (widget.existingSaleId != null
// there). Same layout: header card showing the balance due, a locked
// name field, split Cash/UPI tender, a balance-due banner while the
// tendered amount is short, and a Confirm button that posts to
// add_payment-style endpoint. One deliberate simplification: this screen
// shows a plain success SnackBar and pops instead of Sales' full-screen
// checkmark animation, since that animation is private to payment_screen.dart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../data/models/provider_recharge_model.dart';
import '../providers/provider_recharge_provider.dart';
import '../../../reports/presentation/providers/provider_reports_data_provider.dart';

class ProviderPaymentScreen extends ConsumerStatefulWidget {
  final int rechargeId;
  final String providerName;
  final String? invoiceNumber;
  final double balanceDue;

  const ProviderPaymentScreen({
    super.key,
    required this.rechargeId,
    required this.providerName,
    required this.balanceDue,
    this.invoiceNumber,
  });

  @override
  ConsumerState<ProviderPaymentScreen> createState() =>
      _ProviderPaymentScreenState();
}

class _ProviderPaymentScreenState extends ConsumerState<ProviderPaymentScreen> {
  late TextEditingController _cashCtrl;
  late TextEditingController _upiCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _cashCtrl = TextEditingController(
      text: widget.balanceDue.toStringAsFixed(2),
    );
    _upiCtrl = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _cashCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  void _fail(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    setState(() => _saving = false);
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);

    try {
      final cash = double.tryParse(_cashCtrl.text) ?? 0;
      final upi = double.tryParse(_upiCtrl.text) ?? 0;
      final tendered = cash + upi;

      if (tendered <= 0) {
        _fail('Enter an amount to record.');
        return;
      }

      if (tendered > widget.balanceDue + 0.01) {
        _fail(
          'Amount cannot be greater than the balance due '
          '(₹${widget.balanceDue.toStringAsFixed(2)}).',
        );
        return;
      }

      final usecase = ref.read(addProviderRechargePaymentUseCaseProvider);

      dynamic result;

      if (cash > 0) {
        result = await usecase(
          rechargeId: widget.rechargeId,
          paymentMethod: 'CASH',
          amount: cash,
        );
      }
      if (upi > 0) {
        result = await usecase(
          rechargeId: widget.rechargeId,
          paymentMethod: 'UPI',
          amount: upi,
        );
      }

      if (!mounted) return;
      setState(() => _saving = false);

      // Balance moved — everything showing it must refetch.
      ref.invalidate(providerRechargeHistoryProvider);
      ref.invalidate(providerInvoiceReportsProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('₹${tendered.toStringAsFixed(2)} recorded.'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );

      Navigator.of(
        context,
      ).pop(result is ProviderRechargeModel ? result : true);
    } catch (e) {
      _fail(
        'Could not record payment: '
        '${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cash = double.tryParse(_cashCtrl.text) ?? 0;
    final upi = double.tryParse(_upiCtrl.text) ?? 0;
    final tendered = cash + upi;
    final remaining = tendered < widget.balanceDue
        ? widget.balanceDue - tendered
        : 0;

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
                    'BALANCE DUE',
                    style: AppTextStyles.small.copyWith(
                      color: Colors.white70,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: R.sp(context, AppSpacing.xs)),
                  Text(
                    '₹${widget.balanceDue.toStringAsFixed(2)}',
                    style: AppTextStyles.heading.copyWith(
                      color: Colors.white,
                      fontSize: R.fs(context, 30),
                    ),
                  ),
                  SizedBox(height: R.sp(context, AppSpacing.xs)),
                  Text(
                    widget.invoiceNumber != null &&
                            widget.invoiceNumber!.isNotEmpty
                        ? 'Invoice ${widget.invoiceNumber}'
                        : 'Outstanding balance',
                    style: AppTextStyles.small.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            SizedBox(height: R.sp(context, AppSpacing.lg)),
            Text(
              'Provider',
              style: AppTextStyles.small.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: R.sp(context, AppSpacing.xs)),
            Container(
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
                    widget.providerName,
                    style: AppTextStyles.cardValue.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    Icons.lock_outline,
                    color: AppColors.textSecondary,
                    size: R.icon(context, AppSizes.iconMd),
                  ),
                ],
              ),
            ),
            SizedBox(height: R.sp(context, AppSpacing.lg)),
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
                  'Tendered total ₹${tendered.toStringAsFixed(2)}',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (remaining > 0) ...[
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
                      'Still remaining',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '₹${remaining.toStringAsFixed(2)}',
                      style: AppTextStyles.cardValue.copyWith(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w700,
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
                      onPressed: _saving ? null : _confirm,
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
                              'Confirm Payment',
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
