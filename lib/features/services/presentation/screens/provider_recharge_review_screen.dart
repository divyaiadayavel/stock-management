// lib/features/services/presentation/screens/provider_recharge_review_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../settings/service_management/data/models/service_provider_model.dart';
import '../../../settings/service_management/domain/enums/provider_field_type.dart';
import '../../data/models/provider_recharge_answer_model.dart';
import '../../data/models/provider_recharge_model.dart';
import '../providers/provider_recharge_provider.dart';
import 'provider_recharge_receipt_screen.dart';

/// SCREEN 7 — "Review recharge"
///
/// Summary rows, balance before → after, a confirmation checkbox, and
/// "Complete recharge" (the call that actually deducts the balance).
class ProviderRechargeReviewScreen extends ConsumerStatefulWidget {
  final ServiceProviderModel provider;
  final double amount;
  final String paymentStatus;
  final double paidAmount;
  final String paymentMethod;

  /// Passed through to the backend so the recharge is attributed to a
  /// user. Defaults to 1 to match the existing service-request flow.
  final int userId;

  const ProviderRechargeReviewScreen({
    super.key,
    required this.provider,
    required this.amount,
    this.paymentStatus = 'PAID',
    required this.paidAmount,
    this.paymentMethod = 'CASH',
    this.userId = 1,
  });

  @override
  ConsumerState<ProviderRechargeReviewScreen> createState() =>
      _ProviderRechargeReviewScreenState();
}

class _ProviderRechargeReviewScreenState
    extends ConsumerState<ProviderRechargeReviewScreen> {
  bool _confirmed = false;
  bool _submitting = false;

  // Payment is selected on the provider form. Review is read-only.
  late final String _paymentStatus = widget.paymentStatus;
  late final String _paymentMethod = widget.paymentMethod;
  late final double _paidAmount = widget.paidAmount;

  double get _balanceAmount =>
      (widget.amount - _paidAmount).clamp(0.0, double.infinity);

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

  String _display(Object? value) {
    if (value == null) return '—';

    if (value is List) {
      return value.isEmpty ? '—' : value.join(', ');
    }

    final text = value.toString().trim();

    return text.isEmpty ? '—' : text;
  }

  bool _isPaymentFieldLabel(String label) {
    final normalized = label.trim().toLowerCase().replaceAll('_', ' ');
    return normalized == 'payment status' || normalized == 'payment method';
  }

  Future<void> _submit() async {
    if (!_confirmed || _submitting) return;

    setState(() => _submitting = true);

    final answers = ref.read(providerFormAnswersProvider);

    final rechargeAnswers = widget.provider.questions
        .where((q) => !_isPaymentFieldLabel(q.label))
        .map((q) {
          final value = answers[q.id];

          String formatted = '';

          if (value is List) {
            formatted = value.join(', ');
          } else if (value != null) {
            formatted = value.toString();
          }

          return ProviderRechargeAnswerModel(
            questionId: q.id ?? 0,
            label: q.label,
            value: formatted,
          );
        })
        .toList();

    final recharge = ProviderRechargeModel(
      providerId: widget.provider.id ?? 0,
      providerName: widget.provider.name,
      categoryName: widget.provider.categoryName,
      userId: widget.userId,
      amount: widget.amount,
      paidAmount: _paidAmount,
      balanceAmount: _balanceAmount,
      paymentStatus: _paymentStatus,
      paymentMethod: _paidAmount > 0 ? _paymentMethod : '',
      answers: rechargeAnswers,
    );

    try {
      final result = await ref
          .read(providerRechargeSubmitProvider.notifier)
          .submit(recharge);

      if (!mounted) return;

      if (result == null) {
        final error = ref.read(providerRechargeSubmitProvider).error;

        throw Exception(error ?? 'Recharge could not be completed.');
      }

      // Keep the exact payment values selected on this screen for the
      // receipt/report UI. This also protects the client UI when an older
      // backend deployment does not return the new payment fields.
      final receiptRecharge = result.copyWith(
        paidAmount: _paidAmount,
        balanceAmount: _balanceAmount,
        paymentStatus: _paymentStatus,
        paymentMethod: _paidAmount > 0 ? _paymentMethod : '',
      );

      ref.read(providerFormAnswersProvider.notifier).reset();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ProviderRechargeReceiptScreen(recharge: receiptRecharge),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            '$e'.replaceFirst('Exception: ', ''),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Widget _row(String label, String value, {bool emphasise = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: R.sp(context, 9)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: R.fs(context, 13),
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: R.fs(context, emphasise ? 14.5 : 13.5),
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = R.hPad(context, base: 20);

    final answers = ref.watch(providerFormAnswersProvider);

    final balanceAfter = widget.provider.balance - widget.amount;

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
                      'Review recharge',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        fontSize: R.fs(context, 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Summary ───
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  hPad.left,
                  R.sp(context, 4),
                  hPad.left,
                  R.sp(context, 20),
                ),
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: R.sp(context, 16),
                      vertical: R.sp(context, 6),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        R.radius(context, 12),
                      ),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _row('Provider', widget.provider.name, emphasise: true),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ...widget.provider.questions
                            .where((q) => !_isPaymentFieldLabel(q.label))
                            .map((q) {
                              final value = q.type == ProviderFieldType.amount
                                  ? money(
                                      double.tryParse(
                                            answers[q.id]?.toString() ?? '0',
                                          ) ??
                                          0,
                                    )
                                  : _display(answers[q.id]);

                              return Column(
                                children: [
                                  _row(q.label, value),
                                  const Divider(
                                    height: 1,
                                    color: Color(0xFFF1F5F9),
                                  ),
                                ],
                              );
                            }),
                        _row('Amount', money(widget.amount), emphasise: true),
                      ],
                    ),
                  ),

                  SizedBox(height: R.sp(context, 16)),

                  // ─── Balance before → after ───
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: R.sp(context, 16),
                      vertical: R.sp(context, 14),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(
                        R.radius(context, 12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Balance before → after',
                            style: TextStyle(
                              fontSize: R.fs(context, 13),
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Text(
                          '${money(widget.provider.balance)} → '
                          '${money(balanceAfter)}',
                          style: TextStyle(
                            fontSize: R.fs(context, 13.5),
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: R.sp(context, 16)),

                  // ─── Payment summary (read-only) ───
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: R.sp(context, 16),
                      vertical: R.sp(context, 14),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        R.radius(context, 12),
                      ),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
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
                        SizedBox(height: R.sp(context, 10)),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _paymentStatus == 'PAID'
                                    ? 'Paid Now'
                                    : _paymentStatus == 'PARTIAL'
                                    ? 'Partial'
                                    : 'Pending',
                                style: TextStyle(
                                  fontSize: R.fs(context, 14),
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            if (_paidAmount > 0)
                              Text(
                                _paymentMethod == 'UPI' ? 'UPI' : 'Cash',
                                style: TextStyle(
                                  fontSize: R.fs(context, 13),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: R.sp(context, 10)),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        SizedBox(height: R.sp(context, 8)),
                        _row('Amount received now', money(_paidAmount)),
                        if (_balanceAmount > 0.01)
                          _row(
                            'Balance amount',
                            money(_balanceAmount),
                            emphasise: true,
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: R.sp(context, 16)),

                  // ─── Confirmation ───
                  GestureDetector(
                    onTap: () => setState(() => _confirmed = !_confirmed),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: R.sp(context, 14),
                        vertical: R.sp(context, 13),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(
                          R.radius(context, 12),
                        ),
                        border: Border.all(
                          color: _confirmed
                              ? AppColors.primary
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: Checkbox(
                              value: _confirmed,
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              onChanged: (v) =>
                                  setState(() => _confirmed = v ?? false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'I confirm the recharge details above are correct '
                              'and the amount will be deducted from the provider '
                              'balance.',
                              style: TextStyle(
                                fontSize: R.fs(context, 12.5),
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF475569),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Complete recharge ───
            Padding(
              padding: EdgeInsets.fromLTRB(
                hPad.left,
                R.sp(context, 4),
                hPad.left,
                R.sp(context, 16),
              ),
              child: Opacity(
                opacity: _confirmed ? 1 : 0.5,
                child: GestureDetector(
                  onTap: _submit,
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
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          )
                        : Text(
                            'Complete recharge',
                            style: TextStyle(
                              fontSize: R.fs(context, 16),
                              fontWeight: FontWeight.w700,
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
    );
  }
}
