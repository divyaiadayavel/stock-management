// lib/features/services/presentation/screens/provider_recharge_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../settings/service_management/data/models/service_provider_model.dart';
import '../../../settings/service_management/domain/entities/provider_question.dart';
import '../../../settings/service_management/domain/enums/provider_field_type.dart';
import '../../data/models/provider_recharge_model.dart';
import '../providers/provider_recharge_provider.dart';
import '../widgets/provider_dynamic_field.dart';
import 'provider_recharge_review_screen.dart';

/// SCREEN 6 — "<Provider> recharge"
///
/// Available balance + the provider's questions + Review.
class _PaymentSheetResult {
  final String status;
  final double amount;

  const _PaymentSheetResult({required this.status, required this.amount});
}

class _PaymentAmountSheet extends StatefulWidget {
  final String status;
  final double totalAmount;
  final double? initialAmount;
  const _PaymentAmountSheet({
    required this.status,
    required this.totalAmount,
    required this.initialAmount,
  });

  @override
  State<_PaymentAmountSheet> createState() => _PaymentAmountSheetState();
}

class _PaymentAmountSheetState extends State<_PaymentAmountSheet> {
  late final TextEditingController _controller;
  String? _error;

  bool get _isPartial => widget.status == 'PARTIAL';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialAmount == null
          ? ''
          : widget.initialAmount!.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final value = double.tryParse(_controller.text.trim());

    if (value == null || value < 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }

    if (value > widget.totalAmount + 0.0001) {
      setState(
        () => _error =
            'Amount cannot exceed ₹${widget.totalAmount.toStringAsFixed(2)}.',
      );
      return;
    }

    if (_isPartial && (value <= 0 || value >= widget.totalAmount)) {
      setState(
        () => _error =
            'Enter an amount greater than ₹0 and less than '
            '₹${widget.totalAmount.toStringAsFixed(2)}.',
      );
      return;
    }

    Navigator.of(
      context,
    ).pop(_PaymentSheetResult(status: widget.status, amount: value));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              R.sp(context, 20),
              R.sp(context, 18),
              R.sp(context, 20),
              R.sp(context, 18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPartial ? 'Partial payment' : 'Pending payment',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: R.fs(context, 17),
                    color: const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: R.sp(context, 5)),
                Text(
                  _isPartial
                      ? 'Recharge amount: ₹${widget.totalAmount.toStringAsFixed(2)}. Enter the amount received now.'
                      : 'Recharge amount: ₹${widget.totalAmount.toStringAsFixed(2)}. Enter ₹0 if no payment was received.',
                  style: TextStyle(
                    fontSize: R.fs(context, 12.5),
                    color: const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
                SizedBox(height: R.sp(context, 14)),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _confirm(),
                  decoration: InputDecoration(
                    labelText: 'Amount received now',
                    prefixText: '₹ ',
                    errorText: _error,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                ),
                SizedBox(height: R.sp(context, 14)),
                SizedBox(height: R.sp(context, 16)),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProviderRechargeFormScreen extends ConsumerStatefulWidget {
  final int providerId;

  /// When set, this screen opens in "settle balance" mode instead of the
  /// normal new-recharge flow: the original recharge's details are shown
  /// read-only, and the only thing that can be entered is how much of the
  /// remaining balance is being paid now. Used by Provider Reports'
  /// "Balance Payment" button.
  final ProviderRechargeModel? existingRecharge;

  const ProviderRechargeFormScreen({
    super.key,
    required this.providerId,
    this.existingRecharge,
  });

  @override
  ConsumerState<ProviderRechargeFormScreen> createState() =>
      _ProviderRechargeFormScreenState();
}

class _ProviderRechargeFormScreenState
    extends ConsumerState<ProviderRechargeFormScreen> {
  // ─── Settle-balance mode only ───
  bool _settleIsPartial = false;
  double _settleAmount = 0.0;
  String _settleMethod = 'CASH';
  bool _settleSubmitting = false;

  @override
  void initState() {
    super.initState();

    if (widget.existingRecharge != null) {
      _settleAmount = widget.existingRecharge!.balanceAmount;
      return;
    }

    // A fresh form every time the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(providerFormAnswersProvider.notifier).reset();
    });
  }

  static String money(double value) {
    final whole = value.toStringAsFixed(2).split('.').first;
    final buffer = StringBuffer();

    for (var i = 0; i < whole.length; i++) {
      buffer.write(whole[i]);

      final remaining = whole.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
    }

    return '₹${buffer.toString()}';
  }

  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;

    return text
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  bool _isPaymentField(ProviderQuestionEntity question) {
    final label = question.label.trim().toLowerCase();
    return label == 'payment status' ||
        label == 'payment method' ||
        label.replaceAll('_', ' ') == 'payment status' ||
        label.replaceAll('_', ' ') == 'payment method';
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade700,
        content: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  double _amountFrom(
    List<ProviderQuestionEntity> questions,
    Map<int, Object?> answers,
  ) {
    for (final q in questions) {
      if (q.type != ProviderFieldType.amount) continue;

      final raw = answers[q.id]?.toString().trim() ?? '';

      return double.tryParse(raw) ?? 0.0;
    }

    return 0.0;
  }

  // Payment is selected here (before Review). Review is now a read-only
  // confirmation screen, so the partial amount dialog never opens there.
  String _paymentStatus = 'PAID';
  String _paymentMethod = 'CASH';
  double _paidAmount = 0.0;

  void _setPaymentStatus(String status) {
    if (status == 'PARTIAL' || status == 'PENDING') {
      _openPaymentAmountSheet(status);
      return;
    }

    // Paid Now: no amount-entry widget. The full recharge amount is paid.
    setState(() {
      _paymentStatus = 'PAID';
      _paidAmount = _currentAmount();
    });
  }

  double get _displayPaidAmount =>
      _paymentStatus == 'PAID' ? _currentAmount() : _paidAmount;

  double _currentAmount() {
    final providerAsync = ref.read(
      userProviderDetailProvider(widget.providerId),
    );
    final provider = providerAsync.valueOrNull;
    if (provider == null) return 0.0;
    return _amountFrom(
      provider.questions,
      ref.read(providerFormAnswersProvider),
    );
  }

  Future<void> _openPaymentAmountSheet(String status) async {
    final amount = _currentAmount();

    if (amount <= 0) {
      _snack('Enter a valid recharge amount first.');
      return;
    }

    final result = await showModalBottomSheet<_PaymentSheetResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentAmountSheet(
        status: status,
        totalAmount: amount,
        initialAmount: _paymentStatus == status
            ? _paidAmount
            : (status == 'PENDING' ? 0 : null),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _paymentStatus = result.status;
      _paidAmount = result.amount;
    });
  }

  Widget _methodChip(String value, String label) {
    final isSelected = _paymentMethod == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMethod = value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: R.sp(context, 10)),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.10)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(R.radius(context, 9)),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: R.fs(context, 12),
              fontWeight: FontWeight.w700,
              color: isSelected ? AppColors.primary : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String value, String label) {
    final isSelected = _paymentStatus == value;
    final color = value == 'PAID'
        ? const Color(0xFF2E7D32)
        : value == 'PARTIAL'
        ? const Color(0xFFE65100)
        : const Color(0xFFC62828);

    return Expanded(
      child: GestureDetector(
        onTap: () => _setPaymentStatus(value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: R.sp(context, 10)),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.12)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(R.radius(context, 9)),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: R.fs(context, 12),
              fontWeight: FontWeight.w700,
              color: isSelected ? color : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  bool _validate(ServiceProviderModel provider) {
    final answers = ref.read(providerFormAnswersProvider);

    for (final q in provider.questions) {
      if (_isPaymentField(q)) continue;

      final value = answers[q.id];

      final isEmpty =
          value == null ||
          (value is String && value.trim().isEmpty) ||
          (value is List && value.isEmpty);

      if (q.required && isEmpty) {
        _snack('"${q.label}" is required.');
        return false;
      }

      if (isEmpty) continue;

      // Same rule the field applies live, run again here in case a
      // bad value got in without triggering it (paste, autofill).
      final fieldError = validateProviderAnswer(q, value);

      if (fieldError != null) {
        _snack(fieldError);
        return false;
      }
    }

    final amount = _amountFrom(provider.questions, answers);

    if (amount <= 0) {
      _snack('Enter a valid recharge amount.');
      return false;
    }

    if (amount > provider.balance) {
      _snack(
        'Amount exceeds the provider balance (${money(provider.balance)}).',
      );
      return false;
    }

    if (_paymentStatus == 'PAID') {
      _paidAmount = amount;
    } else if (_paymentStatus == 'PARTIAL' && _paidAmount >= amount) {
      _snack('Enter a partial amount less than the recharge amount.');
      return false;
    }

    return true;
  }

  // ─── Settle-balance mode ───

  Future<void> _pickSettlePartialAmount() async {
    final balanceDue = widget.existingRecharge!.balanceAmount;

    final result = await showModalBottomSheet<_PaymentSheetResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentAmountSheet(
        status: 'PARTIAL',
        totalAmount: balanceDue,
        initialAmount: _settleIsPartial ? _settleAmount : null,
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _settleIsPartial = true;
      _settleAmount = result.amount;
    });
  }

  Future<void> _submitSettlePayment() async {
    final r = widget.existingRecharge!;

    if (_settleAmount <= 0) {
      _snack('Enter an amount to pay.');
      return;
    }

    if (_settleAmount > r.balanceAmount + 0.01) {
      _snack(
        'Amount cannot exceed the balance due (${money(r.balanceAmount)}).',
      );
      return;
    }

    if (r.id == null) return;

    setState(() => _settleSubmitting = true);

    try {
      final updated = await ref.read(addProviderRechargePaymentUseCaseProvider)(
        rechargeId: r.id!,
        paymentMethod: _settleMethod,
        amount: _settleAmount,
      );

      ref.invalidate(providerRechargeHistoryProvider);

      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (e) {
      _snack(
        'Could not record payment: '
        '${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) setState(() => _settleSubmitting = false);
    }
  }

  Widget _settleChip({
    required bool isSelected,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: R.sp(context, 10)),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.12)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(R.radius(context, 9)),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: R.fs(context, 12),
              fontWeight: FontWeight.w700,
              color: isSelected ? color : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _lockedRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: R.sp(context, 6)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: R.fs(context, 12.5),
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Text(
            value.isEmpty ? '—' : value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: R.fs(context, 12.5),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettleBalanceView(BuildContext context) {
    final r = widget.existingRecharge!;
    final hPad = R.hPad(context, base: 20);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ───
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: hPad.left,
                vertical: R.sp(context, 12),
              ),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.black87,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Pay balance — ${_capitalizeWords(r.providerName)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        fontSize: R.fs(context, 18),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  hPad.left,
                  0,
                  hPad.left,
                  R.sp(context, 20),
                ),
                children: [
                  // ─── Original recharge, read-only ───
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: R.sp(context, 16),
                      vertical: R.sp(context, 14),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(
                        R.radius(context, 12),
                      ),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: R.icon(context, 14),
                              color: const Color(0xFF94A3B8),
                            ),
                            SizedBox(width: R.sp(context, 6)),
                            Text(
                              r.invoiceNumber?.isNotEmpty == true
                                  ? r.invoiceNumber!
                                  : 'Recharge details (locked)',
                              style: TextStyle(
                                fontSize: R.fs(context, 12.5),
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: R.sp(context, 8)),
                        ...r.answerModels.map(
                          (a) => _lockedRow(a.label, a.value),
                        ),
                        _lockedRow('Recharge amount', money(r.amount)),
                        _lockedRow('Paid so far', money(r.paidAmount)),
                      ],
                    ),
                  ),

                  SizedBox(height: R.sp(context, 14)),

                  // ─── Balance due ───
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: R.sp(context, 14),
                      vertical: R.sp(context, 12),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC62828).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(
                        R.radius(context, 10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Balance due',
                          style: TextStyle(
                            fontSize: R.fs(context, 13),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFC62828),
                          ),
                        ),
                        Text(
                          money(r.balanceAmount),
                          style: TextStyle(
                            fontSize: R.fs(context, 16),
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFC62828),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: R.sp(context, 16)),

                  // ─── How much is being paid now (the only editable part) ───
                  Text(
                    'Amount to pay now',
                    style: TextStyle(
                      fontSize: R.fs(context, 13),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: R.sp(context, 8)),
                  Row(
                    children: [
                      _settleChip(
                        isSelected: !_settleIsPartial,
                        label: 'Full balance (${money(r.balanceAmount)})',
                        color: const Color(0xFF2E7D32),
                        onTap: () => setState(() {
                          _settleIsPartial = false;
                          _settleAmount = r.balanceAmount;
                        }),
                      ),
                      SizedBox(width: R.sp(context, 8)),
                      _settleChip(
                        isSelected: _settleIsPartial,
                        label: 'Partial',
                        color: const Color(0xFFE65100),
                        onTap: _pickSettlePartialAmount,
                      ),
                    ],
                  ),

                  if (_settleIsPartial) ...[
                    SizedBox(height: R.sp(context, 10)),
                    _lockedRow('Paying now', money(_settleAmount)),
                    _lockedRow(
                      'Still remaining after this',
                      money(r.balanceAmount - _settleAmount),
                    ),
                  ],

                  SizedBox(height: R.sp(context, 16)),

                  Text(
                    'Payment method',
                    style: TextStyle(
                      fontSize: R.fs(context, 13),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: R.sp(context, 8)),
                  Row(
                    children: [
                      _methodChip('CASH', 'Cash'),
                      SizedBox(width: R.sp(context, 8)),
                      _methodChip('UPI', 'UPI'),
                    ],
                  ),
                ],
              ),
            ),

            // ─── Pay now ───
            Padding(
              padding: EdgeInsets.fromLTRB(
                hPad.left,
                R.sp(context, 8),
                hPad.left,
                R.sp(context, 16),
              ),
              child: GestureDetector(
                onTap: _settleSubmitting ? null : _submitSettlePayment,
                child: Container(
                  width: double.infinity,
                  height: R.sp(context, 52),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(R.radius(context, 10)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _settleSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Pay Now (${money(_settleAmount)})',
                          style: TextStyle(
                            fontSize: R.fs(context, 16),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.existingRecharge != null) {
      return _buildSettleBalanceView(context);
    }

    final providerAsync = ref.watch(
      userProviderDetailProvider(widget.providerId),
    );

    final hPad = R.hPad(context, base: 20);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: providerAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            ),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad.left),
              child: Text(
                'Failed to load provider: $e',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: R.fs(context, 14),
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
          data: (provider) {
            // Payment status/method are rendered once in the bottom payment
            // section. Do not render them again as dynamic provider fields.
            final questions = provider.questions
                .where((q) => !_isPaymentField(q))
                .toList();

            return Column(
              children: [
                // ─── Header ───
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: hPad.left,
                    vertical: R.sp(context, 12),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                          size: 24,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _capitalizeWords(provider.name),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                            fontSize: R.fs(context, 20),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── Balance strip ───
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad.left),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: R.sp(context, 14),
                      vertical: R.sp(context, 12),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(
                        R.radius(context, 10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Available balance',
                          style: TextStyle(
                            fontSize: R.fs(context, 13),
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          money(provider.balance),
                          style: TextStyle(
                            fontSize: R.fs(context, 15),
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: R.sp(context, 14)),

                // ─── Questions ───
                Expanded(
                  child: questions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No questions configured for this provider',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: R.fs(context, 15),
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: EdgeInsets.fromLTRB(
                            hPad.left,
                            0,
                            hPad.left,
                            R.sp(context, 20),
                          ),
                          children: questions.asMap().entries.map((entry) {
                            final i = entry.key;
                            final question = entry.value;

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: i == questions.length - 1 ? 0 : 20,
                              ),
                              child: ProviderDynamicField(
                                key: ValueKey(
                                  'pq_${question.id ?? question.localId}',
                                ),
                                question: question,
                                initialValue: ref.read(
                                  providerFormAnswersProvider,
                                )[question.id],
                                onChanged: (value) {
                                  if (question.id != null) {
                                    ref
                                        .read(
                                          providerFormAnswersProvider.notifier,
                                        )
                                        .setAnswer(question.id!, value);
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                ),

                // ─── Payment ───
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    hPad.left,
                    R.sp(context, 8),
                    hPad.left,
                    R.sp(context, 12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment status',
                        style: TextStyle(
                          fontSize: R.fs(context, 13),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: R.sp(context, 8)),
                      Row(
                        children: [
                          _statusChip('PAID', 'Paid Now'),
                          SizedBox(width: R.sp(context, 8)),
                          _statusChip('PARTIAL', 'Partial'),
                          SizedBox(width: R.sp(context, 8)),
                          _statusChip('PENDING', 'Pending'),
                        ],
                      ),
                    ],
                  ),
                ),

                // ─── Payment method ───
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    hPad.left,
                    R.sp(context, 2),
                    hPad.left,
                    R.sp(context, 8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment method',
                        style: TextStyle(
                          fontSize: R.fs(context, 13),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: R.sp(context, 8)),
                      Row(
                        children: [
                          _methodChip('CASH', 'Cash'),
                          SizedBox(width: R.sp(context, 8)),
                          _methodChip('UPI', 'UPI'),
                        ],
                      ),
                    ],
                  ),
                ),

                // ─── Review ───
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    hPad.left,
                    R.sp(context, 8),
                    hPad.left,
                    R.sp(context, 16),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      if (!_validate(provider)) return;

                      final answers = ref.read(providerFormAnswersProvider);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProviderRechargeReviewScreen(
                            provider: provider,
                            amount: _amountFrom(questions, answers),
                            paymentStatus: _paymentStatus,
                            paidAmount: _displayPaidAmount,
                            paymentMethod: _paymentMethod,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: R.sp(context, 52),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(
                          R.radius(context, 10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        'Review',
                        style: TextStyle(
                          fontSize: R.fs(context, 16),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
