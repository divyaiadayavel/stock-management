// lib/features/sales/presentation/screens/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../data/models/sale_model.dart';
import '../providers/billing_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/sales_provider.dart';
import '../../../customers/presentation/provider/customer_provider.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../customers/presentation/screens/add_customer_screen.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import 'invoice_screen.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final double totalAmount;

  /// When set, this screen is being used to settle the outstanding
  /// balance on an already-existing invoice (e.g. from the Invoice
  /// Details screen's "Balance Payment" button) instead of creating a
  /// brand new sale. [totalAmount] is then the remaining balance due.
  final int? existingSaleId;
  final String? existingCustomerName;
  final String? existingInvoiceNumber;

  const PaymentScreen({
    super.key,
    required this.totalAmount,
    this.existingSaleId,
    this.existingCustomerName,
    this.existingInvoiceNumber,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  late TextEditingController _cashCtrl;
  late TextEditingController _upiCtrl;
  bool _saving = false;

  /// True when this screen is settling an existing invoice's balance
  /// (add_payment.php) rather than creating a brand new sale.
  bool get _isSettlingBalance => widget.existingSaleId != null;

  @override
  void initState() {
    super.initState();
    _cashCtrl = TextEditingController(
      text: widget.totalAmount.toStringAsFixed(2),
    );
    _upiCtrl = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _cashCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  Future<void> _addNewCustomer() async {
    final createdCustomer = await Navigator.push<CustomerModel>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddCustomerScreen(returnCreatedCustomer: true),
      ),
    );

    if (!mounted) return;

    if (createdCustomer != null && createdCustomer.id != null) {
      ref
          .read(paymentProvider.notifier)
          .selectCustomer(
            id: createdCustomer.id!,
            name: createdCustomer.customerName,
          );

      ref.invalidate(rawCustomersProvider);
      ref.invalidate(allCustomersProvider);
    }
  }

  Future<void> _pickCustomer() async {
    final customers = await ref.read(rawCustomersProvider.future);
    if (!mounted) return;

    final picked = await showModalBottomSheet<CustomerModel>(
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
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: R.sp(ctx, AppSpacing.screenPadding),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _addNewCustomer();
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: R.sp(ctx, AppSpacing.sm),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_add_alt_1,
                          color: AppColors.primary,
                          size: R.icon(ctx, AppSizes.iconMd),
                        ),
                        SizedBox(width: R.sp(ctx, AppSpacing.sm)),
                        Text(
                          'Add new customer',
                          style: AppTextStyles.cardValue.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              SizedBox(height: R.sp(ctx, AppSpacing.xs)),
              Flexible(
                child: customers.isEmpty
                    ? Padding(
                        padding: EdgeInsets.all(R.sp(ctx, AppSpacing.lg)),
                        child: Text(
                          'No customers available',
                          style: AppTextStyles.small,
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: customers.length,
                        itemBuilder: (_, i) {
                          final c = customers[i];
                          return ListTile(
                            title: Text(
                              c.customerName,
                              style: AppTextStyles.cardValue,
                            ),
                            subtitle: c.phone != null ? Text(c.phone!) : null,
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

    if (picked != null) {
      ref
          .read(paymentProvider.notifier)
          .selectCustomer(id: picked.id!, name: picked.customerName);
    }
  }

  void _showSuccessOverlay(int saleId, double paidAmount) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _SuccessAnimationWidget(
          paidAmount: paidAmount,
          onAnimationComplete: () {
            if (!mounted) return;

            if (_isSettlingBalance) {
              // Settling an existing invoice: close the success dialog
              // and pop straight back to whoever opened this screen
              // (Invoice Details), which will reload the invoice and
              // show it as PAID / PARTIAL / PENDING accordingly.
              Navigator.of(context).pop();
              Navigator.of(context).pop(true);
              return;
            }

            ref.read(billingProvider.notifier).clearCart();
            ref.read(paymentProvider.notifier).reset();

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => InvoiceScreen(saleId: saleId)),
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
          child: child,
        );
      },
    );
  }

  Future<void> _confirmAndPrint() async {
    setState(() => _saving = true);

    try {
      final billingState = ref.read(billingProvider);
      final paymentState = ref.read(paymentProvider);

      final cash = double.tryParse(_cashCtrl.text) ?? 0;
      final upi = double.tryParse(_upiCtrl.text) ?? 0;
      final tendered = cash + upi;
      final balanceDue = tendered < widget.totalAmount
          ? widget.totalAmount - tendered
          : 0;

      // Validation check: Require a registered customer if there is a balance due
      if (balanceDue > 0 && paymentState.selectedCustomerId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please select a customer for sales with an outstanding balance.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _saving = false);
        }
        return;
      }

      // Determine correct payment status based on tendered amount
      String paymentStatus = "PAID";
      if (tendered <= 0.001) {
        paymentStatus = "PENDING";
      } else if (tendered < widget.totalAmount - 0.001) {
        paymentStatus = "PARTIAL";
      } else {
        paymentStatus = "PAID";
      }

      final List<SalePayment> salePayments = [];
      if (cash > 0) {
        salePayments.add(
          SalePayment(id: 0, saleId: 0, paymentMethod: 'CASH', amount: cash),
        );
      }
      if (upi > 0) {
        salePayments.add(
          SalePayment(id: 0, saleId: 0, paymentMethod: 'UPI', amount: upi),
        );
      }

      final sale = SaleModel(
        invoiceNumber: '',
        customerId: paymentState.selectedCustomerId,
        customerName: paymentState.selectedCustomerName ?? 'Walk-in Customer',
        paymentMethod: paymentState.paymentMethod,
        subtotal: billingState.subtotal,
        taxAmount: billingState.tax,
        discountAmount: billingState.itemDiscount,
        grandTotal: billingState.grandTotal,
        paidAmount: tendered.toDouble(),
        balanceAmount: balanceDue.toDouble(),
        invoiceDate: DateTime.now(),
        roundOff: 0.0,
        paymentStatus: paymentStatus,
        invoiceStatus: "FINAL",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: List.from(billingState.cart),
        payments: salePayments,
        recordedPaymentTotal: tendered.toDouble(),
      );

      final saleId = await ref.read(createSaleUseCaseProvider)(sale);

      if (saleId == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create sale. Please try again.'),
            ),
          );
          setState(() => _saving = false);
        }
        return;
      }

      if (!mounted) return;
      setState(() => _saving = false);

      ref.invalidate(rawCustomersProvider);
      ref.invalidate(allCustomersProvider);
      ref.read(dashboardProvider.notifier).refresh();

      _showSuccessOverlay(saleId, tendered.toDouble());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not confirm payment: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }

  /// Records a payment against an already-existing invoice's balance
  /// (add_payment.php) — used when this screen was opened from the
  /// Invoice Details screen's "Balance Payment" button, instead of
  /// creating a brand new sale.
  Future<void> _confirmSettlement() async {
    setState(() => _saving = true);

    try {
      final cash = double.tryParse(_cashCtrl.text) ?? 0;
      final upi = double.tryParse(_upiCtrl.text) ?? 0;
      final tendered = cash + upi;

      if (tendered <= 0) {
        _failSettlement('Enter an amount to record.');
        return;
      }

      if (tendered > widget.totalAmount + 0.01) {
        _failSettlement(
          'Amount cannot be greater than the balance due '
          '(₹${widget.totalAmount.toStringAsFixed(2)}).',
        );
        return;
      }

      final saleId = widget.existingSaleId!;

      if (cash > 0) {
        await ref.read(addPaymentUseCaseProvider)(
          saleId: saleId,
          paymentMethod: 'CASH',
          amount: cash,
        );
      }
      if (upi > 0) {
        await ref.read(addPaymentUseCaseProvider)(
          saleId: saleId,
          paymentMethod: 'UPI',
          amount: upi,
        );
      }

      if (!mounted) return;
      setState(() => _saving = false);

      // The invoice's balance just changed — refresh customer +
      // dashboard receivable totals everywhere. The invoice itself
      // gets refreshed by the caller (Invoice Details screen) once we
      // pop back to it after the success animation.
      ref.invalidate(rawCustomersProvider);
      ref.invalidate(allCustomersProvider);
      ref.read(dashboardProvider.notifier).refresh();

      _showSuccessOverlay(saleId, tendered.toDouble());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not record payment: '
              '${e.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
        setState(() => _saving = false);
      }
    }
  }

  void _failSettlement(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingProvider);
    final paymentState = ref.watch(paymentProvider);

    final cash = double.tryParse(_cashCtrl.text) ?? 0;
    final upi = double.tryParse(_upiCtrl.text) ?? 0;
    final tendered = cash + upi;
    final change = tendered > widget.totalAmount
        ? tendered - widget.totalAmount
        : 0;
    final balanceDue = tendered < widget.totalAmount
        ? widget.totalAmount - tendered
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
                    _isSettlingBalance ? 'BALANCE DUE' : 'TOTAL PAYABLE',
                    style: AppTextStyles.small.copyWith(
                      color: Colors.white70,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: R.sp(context, AppSpacing.xs)),
                  Text(
                    '₹${widget.totalAmount.toStringAsFixed(2)}',
                    style: AppTextStyles.heading.copyWith(
                      color: Colors.white,
                      fontSize: R.fs(context, 30),
                    ),
                  ),
                  SizedBox(height: R.sp(context, AppSpacing.xs)),
                  Text(
                    _isSettlingBalance
                        ? (widget.existingInvoiceNumber != null &&
                                  widget.existingInvoiceNumber!.isNotEmpty
                              ? 'Invoice ${widget.existingInvoiceNumber}'
                              : 'Outstanding balance')
                        : 'incl GST (${billingState.tax.toStringAsFixed(2)})',
                    style: AppTextStyles.small.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            SizedBox(height: R.sp(context, AppSpacing.lg)),
            Text(
              'Customer',
              style: AppTextStyles.small.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: R.sp(context, AppSpacing.xs)),
            _isSettlingBalance
                ? Container(
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
                          widget.existingCustomerName ?? 'Walk-in Customer',
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
                  )
                : GestureDetector(
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
                      paymentState.selectedCustomerName ?? 'Walk-in Customer',
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
                  'Cash tendered ₹${cash.toStringAsFixed(2)}',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Change ₹${change.toStringAsFixed(2)}',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (balanceDue > 0) ...[
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
                      '₹${balanceDue.toStringAsFixed(2)}',
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
                      onPressed: _saving
                          ? null
                          : (_isSettlingBalance
                                ? _confirmSettlement
                                : _confirmAndPrint),
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
                              _isSettlingBalance
                                  ? 'Confirm Payment'
                                  : 'Confirm & print invoice',
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

class _SuccessAnimationWidget extends StatefulWidget {
  final double paidAmount;
  final VoidCallback onAnimationComplete;

  const _SuccessAnimationWidget({
    required this.paidAmount,
    required this.onAnimationComplete,
  });

  @override
  State<_SuccessAnimationWidget> createState() =>
      _SuccessAnimationWidgetState();
}

class _SuccessAnimationWidgetState extends State<_SuccessAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _checkScale;
  late Animation<double> _containerScale;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _containerScale = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.4, curve: Curves.fastOutSlowIn),
    );

    _checkScale = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.3, 0.7, curve: Curves.elasticOut),
    );

    _animCtrl.forward();

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) widget.onAnimationComplete();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _containerScale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animCtrl,
                    builder: (context, child) {
                      return Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFF4CAF50,
                          ).withOpacity((1.0 - _animCtrl.value) * 0.2),
                        ),
                      );
                    },
                  ),
                  ScaleTransition(
                    scale: _checkScale,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Sale Confirmed!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Payment received successfully',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '₹${widget.paidAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey[400]!,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Generating invoice...',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
