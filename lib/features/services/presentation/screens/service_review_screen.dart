import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../settings/service_management/data/models/service_model.dart';
import '../../../settings/service_management/domain/entities/service_question.dart';
import '../../../settings/service_management/domain/enums/question_type.dart';
import '../../data/models/service_answer_model.dart';
import '../../data/models/service_request_model.dart';
import '../providers/services_provider.dart';
import '../widgets/submission_success_dialog.dart';
import 'service_receipt_screen.dart';


class ServiceReviewScreen extends ConsumerStatefulWidget {
  final ServiceModel service;

  // Amount entered by the user for this particular service request.
  final double enteredAmount;

  const ServiceReviewScreen({
    super.key,
    required this.service,
    required this.enteredAmount,
  });

  @override
  ConsumerState<ServiceReviewScreen> createState() =>
      _ServiceReviewScreenState();
}

class _ServiceReviewScreenState
    extends ConsumerState<ServiceReviewScreen> {
  bool _confirmed = false;
  bool _isSubmitting = false;

  String _capitalize(String text) {
    if (text.isEmpty) return text;

    return text[0].toUpperCase() +
        text.substring(1);
  }

  String _displayValue(Object? value) {
    if (value == null) return '—';

    if (value is List) {
      return value.isEmpty
          ? '—'
          : value.join(', ');
    }

    final text = value.toString().trim();

    return text.isEmpty ? '—' : text;
  }

  bool _isCustomerDetail(
    ServiceQuestionEntity q,
  ) {
    final lower = q.label.toLowerCase();

    return lower.contains('name') ||
        lower.contains('phone') ||
        lower.contains('mobile') ||
        lower.contains('email') ||
        lower.contains('contact') ||
        lower.contains('customer') ||
        lower.contains('user');
  }

  Future<void> _submit() async {
    if (!_confirmed || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final answers =
        ref.read(serviceFormAnswersProvider);

    final requestAnswers =
        widget.service.questions.map((q) {
      final val = answers[q.id];

      String formattedVal = '';

      if (val is List) {
        formattedVal = val.join(', ');
      } else if (val != null) {
        formattedVal = val.toString();
      }

      return ServiceAnswerModel(
        questionId: q.id ?? 0,
        label: q.label,
        value: formattedVal,
      );
    }).toList();

    // ─── Build service request ─────────────────────────────
    //
    // The amount comes from the USER'S current request.
    //
    // Admin only controls chargeEnabled.
    // Admin does NOT define the amount.
final request = ServiceRequestModel(
  userId: 1,
  serviceId: widget.service.id ?? 0,
  serviceName: widget.service.name,
  categoryName: widget.service.categoryName,
  answers: requestAnswers,
  amount: widget.service.chargeEnabled
      ? widget.enteredAmount
      : 0.0,
  chargeEnabled: widget.service.chargeEnabled,
);

    try {
      final result = await ref
          .read(serviceSubmitProvider.notifier)
          .submit(request);

      if (!mounted) return;

      if (result == null) {
        throw Exception(
          'Service request could not be submitted.',
        );
      }

      final finalRequest = result;

      // Clear current form answers after successful submission.
      ref
          .read(
            serviceFormAnswersProvider.notifier,
          )
          .reset();

      await showSubmissionSuccessDialog(
        context,
        invoiceNumber:
            finalRequest.invoiceNumber ??
                'Generated',
        onViewReceipt: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ServiceReceiptScreen(
                request: finalRequest,
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor:
              Colors.red.shade700,
          content: Text(
            'Error: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildServiceChargeCard(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFBBF7D0),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.currency_rupee_rounded,
              color: Color(0xFF16A34A),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Service Charge',
                  style: TextStyle(
                    fontSize:
                        R.fs(context, 14),
                    fontWeight:
                        FontWeight.w700,
                    color:
                        const Color(0xFF166534),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Amount entered for this request',
                  style: TextStyle(
                    fontSize:
                        R.fs(context, 12),
                    fontWeight:
                        FontWeight.w500,
                    color:
                        const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '₹ ${widget.enteredAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize:
                  R.fs(context, 17),
              fontWeight:
                  FontWeight.w800,
              color:
                  const Color(0xFF15803D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoChargeCard(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.money_off_rounded,
              color: Color(0xFF64748B),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No service charge',
              style: TextStyle(
                fontSize:
                    R.fs(context, 14),
                fontWeight:
                    FontWeight.w600,
                color:
                    const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final answers =
        ref.watch(
      serviceFormAnswersProvider,
    );

    final hPad = R.hPad(
      context,
      base: 20,
    );

    final customerQuestions =
        widget.service.questions
            .where(_isCustomerDetail)
            .toList();

    final transactionQuestions =
        widget.service.questions
            .where(
              (q) => !_isCustomerDetail(q),
            )
            .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ───────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: hPad.left,
                vertical: R.sp(context, 12),
              ),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.black87,
                      size: 24,
                    ),
                    onPressed: () =>
                        Navigator.pop(context),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Review Your Details',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w700,
                        color:
                            const Color(0xFF0F172A),
                        fontSize:
                            R.fs(context, 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Body ────────────────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  hPad.left,
                  4,
                  hPad.left,
                  20,
                ),
                children: [
                  // ─── Service Charge ────────────────────
                  if (widget.service.chargeEnabled) ...[
                    _buildServiceChargeCard(
                      context,
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (!widget.service.chargeEnabled) ...[
                    _buildNoChargeCard(
                      context,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ─── Customer Details ────────────────
                  if (customerQuestions.isNotEmpty) ...[
                    _buildSectionCard(
                      context,
                      title: 'Customer Details',
                      questions:
                          customerQuestions,
                      answers: answers,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ─── Transaction Details ─────────────
                  if (transactionQuestions.isNotEmpty) ...[
                    _buildSectionCard(
                      context,
                      title:
                          customerQuestions.isEmpty
                              ? 'Service Details'
                              : 'Transaction Details',
                      questions:
                          transactionQuestions,
                      answers: answers,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ─── Invoice Info ─────────────────────
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFF0FDF4),
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                      border: Border.all(
                        color:
                            const Color(0xFFBBF7D0),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding:
                              const EdgeInsets.all(
                            6,
                          ),
                          decoration:
                              const BoxDecoration(
                            color:
                                Color(0xFF16A34A),
                            shape:
                                BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons
                                .receipt_long_rounded,
                            size: 16,
                            color:
                                Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                'Invoice Number',
                                style: TextStyle(
                                  fontSize:
                                      R.fs(
                                    context,
                                    14,
                                  ),
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                  color:
                                      const Color(
                                    0xFF15803D,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 2,
                              ),
                              Text(
                                'Will be auto-generated on submission',
                                style: TextStyle(
                                  fontSize:
                                      R.fs(
                                    context,
                                    12,
                                  ),
                                  fontWeight:
                                      FontWeight
                                          .w500,
                                  color:
                                      const Color(
                                    0xFF16A34A,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ─── Confirmation ─────────────────────
                  InkWell(
                    onTap: () {
                      setState(() {
                        _confirmed =
                            !_confirmed;
                      });
                    },
                    borderRadius:
                        BorderRadius.circular(8),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration:
                                BoxDecoration(
                              color: _confirmed
                                  ? const Color(
                                      0xFF2563EB,
                                    )
                                  : Colors.white,
                              borderRadius:
                                  BorderRadius.circular(
                                6,
                              ),
                              border: Border.all(
                                color: _confirmed
                                    ? const Color(
                                        0xFF2563EB,
                                      )
                                    : const Color(
                                        0xFFCBD5E1,
                                      ),
                                width: 1.5,
                              ),
                            ),
                            child: _confirmed
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color:
                                        Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'I confirm that the above details are correct.',
                              style: TextStyle(
                                fontSize:
                                    R.fs(
                                  context,
                                  13,
                                ),
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    const Color(
                                  0xFF0F172A,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),

            // ─── Bottom Actions ─────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                hPad.left,
                8,
                hPad.left,
                R.sp(context, 16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pop(context),
                      child: Container(
                        height: 50,
                        alignment:
                            Alignment.center,
                        decoration:
                            BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                          border: Border.all(
                            color:
                                const Color(
                              0xFF93C5FD,
                            ),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            fontSize:
                                R.fs(
                              context,
                              15,
                            ),
                            fontWeight:
                                FontWeight.w700,
                            color:
                                const Color(
                              0xFF2563EB,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _confirmed &&
                              !_isSubmitting
                          ? _submit
                          : null,
                      child: Container(
                        height: 50,
                        alignment:
                            Alignment.center,
                        decoration:
                            BoxDecoration(
                          gradient:
                              _confirmed &&
                                      !_isSubmitting
                                  ? AppColors
                                      .brandGradient
                                  : null,
                          color:
                              _confirmed &&
                                      !_isSubmitting
                                  ? null
                                  : const Color(
                                      0xFFCBD5E1,
                                    ),
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                          boxShadow:
                              _confirmed &&
                                      !_isSubmitting
                                  ? [
                                      BoxShadow(
                                        color: Colors
                                            .black
                                            .withValues(
                                          alpha:
                                              0.08,
                                        ),
                                        blurRadius:
                                            8,
                                        offset:
                                            const Offset(
                                          0,
                                          3,
                                        ),
                                      ),
                                    ]
                                  : null,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2.2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : Text(
                                'Submit',
                                style:
                                    TextStyle(
                                  fontSize:
                                      R.fs(
                                    context,
                                    15,
                                  ),
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                  color:
                                      Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required List<ServiceQuestionEntity>
        questions,
    required Map<int, Object?> answers,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration:
                const BoxDecoration(
              color: Color(0xFFEFF6FF),
              borderRadius:
                  BorderRadius.only(
                topLeft:
                    Radius.circular(10),
                topRight:
                    Radius.circular(10),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize:
                    R.fs(context, 14),
                fontWeight:
                    FontWeight.w700,
                color:
                    const Color(0xFF2563EB),
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            child: Column(
              children: questions
                  .map((q) {
                final answer =
                    answers[q.id];

                String display;

                if (q.type ==
                    QuestionType.fileUpload) {
                  display = answer == null
                      ? '—'
                      : answer
                          .toString()
                          .split(
                            RegExp(
                              r'[/\\]',
                            ),
                          )
                          .last;
                } else if (q.label
                        .toLowerCase()
                        .contains('phone') ||
                    q.label
                        .toLowerCase()
                        .contains('mobile')) {
                  final raw =
                      _displayValue(answer);

                  display =
                      raw.startsWith('+91') ||
                              raw == '—'
                          ? raw
                          : '+91 $raw';
                } else if (q.label
                            .toLowerCase()
                            .contains(
                              'amount',
                            ) ||
                    q.label
                        .toLowerCase()
                        .contains('price')) {
                  final raw =
                      _displayValue(answer);

                  display = raw == '—'
                      ? '—'
                      : '₹ $raw';
                } else {
                  display =
                      _displayValue(answer);
                }

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          _capitalize(
                            q.label,
                          ),
                          style:
                              TextStyle(
                            fontSize:
                                R.fs(
                              context,
                              13,
                            ),
                            fontWeight:
                                FontWeight
                                    .w500,
                            color:
                                const Color(
                              0xFF64748B,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        flex: 6,
                        child: Text(
                          _capitalize(
                            display,
                          ),
                          style:
                              TextStyle(
                            fontSize:
                                R.fs(
                              context,
                              13,
                            ),
                            fontWeight:
                                FontWeight
                                    .w700,
                            color:
                                const Color(
                              0xFF0F172A,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}