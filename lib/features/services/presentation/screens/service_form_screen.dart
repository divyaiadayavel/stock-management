import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/dynamic_question_field.dart';
import '../../../settings/service_management/domain/entities/service_question.dart';
import '../../../settings/service_management/domain/enums/question_type.dart';
import '../providers/services_provider.dart';
import 'service_review_screen.dart';

class ServiceFormScreen extends ConsumerStatefulWidget {
  final int serviceId;

  const ServiceFormScreen({super.key, required this.serviceId});

  @override
  ConsumerState<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends ConsumerState<ServiceFormScreen> {
  final TextEditingController _chargeController = TextEditingController();

  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;

    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;

          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  @override
  void dispose() {
    _chargeController.dispose();
    super.dispose();
  }

  double? _parseCharge() {
    final text = _chargeController.text.trim();

    if (text.isEmpty) {
      return null;
    }

    final amount = double.tryParse(text);

    if (amount == null || amount <= 0) {
      return null;
    }

    return amount;
  }

  bool _validateAll(List<ServiceQuestionEntity> questions, bool chargeEnabled) {
    // ─── Validate service charge ───────────────────────────
    if (chargeEnabled) {
      final chargeError = Validators.validateServiceCharge(
        _chargeController.text,
      );

      if (chargeError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(
              chargeError,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );

        return false;
      }
    }

    // ─── Validate required questions ───────────────────────
    final answers = ref.read(serviceFormAnswersProvider);

    for (final q in questions) {
      final value = answers[q.id];

      final isEmpty =
          value == null ||
          (value is String && value.trim().isEmpty) ||
          (value is List && value.isEmpty);

      if (q.required && isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(
              '"${q.label}" is required.',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );

        return false;
      }

      if (isEmpty) continue;

      // Text-typed answers (short_answer / paragraph) get the same
      // rule the field itself applies live — picked by what the
      // label is actually asking for (name / phone / plan / amount
      // / generic text). Choice-based types (multiple_choice,
      // checkboxes, dropdown, date, time, file_upload) are picked
      // from a fixed set, so the required check above is all they
      // need.
      if (value is String) {
        final isParagraph = q.type == QuestionType.paragraph;

        final textError = isParagraph
            ? validateServiceParagraphAnswer(q, value)
            : validateServiceShortAnswer(q, value);

        if (textError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red.shade700,
              content: Text(
                textError,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );

          return false;
        }
      }
    }

    return true;
  }

  Widget _buildServiceChargeField(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service Charge',
                      style: TextStyle(
                        fontSize: R.fs(context, 14),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF166534),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Enter the charge for this request',
                      style: TextStyle(
                        fontSize: R.fs(context, 12),
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          TextFormField(
            controller: _chargeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: TextStyle(
              fontSize: R.fs(context, 16),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'Enter amount',
              hintStyle: TextStyle(
                fontSize: R.fs(context, 14),
                color: const Color(0xFF94A3B8),
              ),
              prefixText: '₹ ',
              prefixStyle: TextStyle(
                fontSize: R.fs(context, 16),
                fontWeight: FontWeight.w700,
                color: const Color(0xFF475569),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: R.sp(context, 14),
                vertical: R.sp(context, 13),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD1FAE5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF16A34A),
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Colors.redAccent,
                  width: 1.5,
                ),
              ),
              errorStyle: TextStyle(fontSize: R.fs(context, 11.5)),
            ),
            validator: (v) => Validators.validateServiceCharge(v ?? ''),
          ),
        ],
      ),
    );
  }

  Widget _buildNoChargeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No service charge',
                  style: TextStyle(
                    fontSize: R.fs(context, 14),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'This service does not require a charge.',
                  style: TextStyle(
                    fontSize: R.fs(context, 12),
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final serviceAsync = ref.watch(userServiceDetailProvider(widget.serviceId));

    final hPad = R.hPad(context, base: 20);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: serviceAsync.when(
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
                'Failed to load service: $e',
                style: TextStyle(
                  fontSize: R.fs(context, 14),
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          data: (service) {
            final questions = service.questions;

            final title = _capitalizeWords(
              service.name.isEmpty ? 'Service Form' : service.name,
            );

            return Column(
              children: [
                // ─── Header ───────────────────────────────
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
                          title,
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

                const SizedBox(height: 8),

                // ─── Form ─────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(hPad.left, 8, hPad.left, 20),
                    children: [
                      // ─── Service Charge ────────────────
                      if (service.chargeEnabled) ...[
                        _buildServiceChargeField(context),
                        const SizedBox(height: 22),
                      ],

                      if (!service.chargeEnabled) ...[
                        _buildNoChargeCard(context),
                        const SizedBox(height: 22),
                      ],

                      // ─── Questions ─────────────────────
                      if (questions.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.assignment_turned_in_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No questions configured for this service',
                                  style: TextStyle(
                                    fontSize: R.fs(context, 15),
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...questions.asMap().entries.map((entry) {
                          final i = entry.key;
                          final question = entry.value;

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: i == questions.length - 1 ? 0 : 22,
                            ),
                            child: DynamicQuestionField(
                              index: i + 1,
                              question: question,
                              initialValue: ref.watch(
                                serviceFormAnswersProvider,
                              )[question.id],
                              onChanged: (value) {
                                if (question.id != null) {
                                  ref
                                      .read(serviceFormAnswersProvider.notifier)
                                      .setAnswer(question.id!, value);
                                }
                              },
                            ),
                          );
                        }),
                    ],
                  ),
                ),

                // ─── Review Button ───────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    hPad.left,
                    8,
                    hPad.left,
                    R.sp(context, 16),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      if (!_validateAll(questions, service.chargeEnabled)) {
                        return;
                      }

                      final enteredAmount = service.chargeEnabled
                          ? (_parseCharge() ?? 0.0)
                          : 0.0;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ServiceReviewScreen(
                            service: service,
                            enteredAmount: enteredAmount,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(10),
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
