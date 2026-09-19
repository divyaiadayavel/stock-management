// lib/features/services/presentation/widgets/provider_dynamic_field.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/validators.dart';
import '../../../settings/service_management/domain/entities/provider_question.dart';
import '../../../settings/service_management/domain/enums/provider_field_type.dart';

/// Renders one provider question as an input. Mirrors the role
/// `DynamicQuestionField` plays for services, but for [ProviderFieldType]
/// so the existing widget keeps working untouched.
class ProviderDynamicField extends StatefulWidget {
  final ProviderQuestionEntity question;
  final Object? initialValue;
  final ValueChanged<Object?> onChanged;

  const ProviderDynamicField({
    super.key,
    required this.question,
    required this.onChanged,
    this.initialValue,
  });

  @override
  State<ProviderDynamicField> createState() => _ProviderDynamicFieldState();
}

/// Shared with [ProviderRechargeFormScreen] so the same rule that
/// blocks the field as you type also blocks the "Review" button if
/// a bad value slipped through (paste, autofill, etc).
///
/// Same idea as the services form: every rule lives in Validators,
/// picked by what the question is actually asking for. A "mobile"/
/// "phone" label needs exactly 10 digits, a "name"/"customer" label
/// needs a capitalised, letters-only name, a "plan" label allows
/// alphanumeric, and every amount field must be greater than 0 — 0
/// is never accepted.
String? validateProviderAnswer(ProviderQuestionEntity q, Object? rawValue) {
  final value = rawValue?.toString() ?? '';
  final label = q.label.toLowerCase();

  bool isPhoneLabel() =>
      label.contains('phone') ||
      label.contains('mobile') ||
      label.contains('contact');

  bool isNameLabel() =>
      label.contains('name') ||
      label.contains('customer') ||
      label.contains('user');

  switch (q.type) {
    case ProviderFieldType.amount:
      // An amount question exists to be deducted from the balance —
      // 0 is never meaningful here, so it's always required.
      return Validators.validateCustomerAmount(
        value,
        fieldName: q.label,
        required: true,
      );

    case ProviderFieldType.number:
      if (isPhoneLabel()) {
        return q.required
            ? Validators.validatePhone(value, fieldName: q.label)
            : Validators.validateOptionalPhone(value, fieldName: q.label);
      }

      return q.required
          ? Validators.validateRequiredInteger(value, fieldName: q.label)
          : Validators.validateOptionalInteger(value, fieldName: q.label);

    case ProviderFieldType.paragraph:
      return Validators.validateParagraphAnswer(
        value,
        fieldName: q.label,
        required: q.required,
      );

    case ProviderFieldType.shortText:
      if (isPhoneLabel()) {
        return q.required
            ? Validators.validatePhone(value, fieldName: q.label)
            : Validators.validateOptionalPhone(value, fieldName: q.label);
      }

      if (label.contains('plan')) {
        return Validators.validatePlanName(
          value,
          fieldName: q.label,
          required: q.required,
        );
      }

      if (isNameLabel()) {
        // Optional name field left blank is fine; once they start
        // typing, the name must contain letters (with supported spaces,
        // hyphens, or apostrophes). Lowercase input is allowed.
        if (!q.required && Validators.normalizeText(value).isEmpty) {
          return null;
        }

        return Validators.validateName(value, fieldName: q.label);
      }

      return Validators.validateShortAnswer(
        value,
        fieldName: q.label,
        required: q.required,
      );

    case ProviderFieldType.choice:
    case ProviderFieldType.date:
      // Chip-picked and date-picked values aren't typed, so there's
      // no format to check — required-ness is enforced on submit.
      return null;
  }
}

class _ProviderDynamicFieldState extends State<ProviderDynamicField> {
  late final TextEditingController _controller;

  String? _selected;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialValue?.toString() ?? '',
    );

    if (widget.question.type == ProviderFieldType.choice) {
      _selected = widget.initialValue?.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String hint, {String? prefixText}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: R.fs(context, 14),
        color: const Color(0xFF94A3B8),
      ),
      prefixText: prefixText,
      prefixStyle: TextStyle(
        fontSize: R.fs(context, 15),
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
        borderRadius: BorderRadius.circular(R.radius(context, 10)),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.radius(context, 10)),
        borderSide: const BorderSide(color: AppColors.cyanDim, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.radius(context, 10)),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.radius(context, 10)),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      errorStyle: TextStyle(fontSize: R.fs(context, 11.5)),
    );
  }

  bool _isNameField(String label) {
    final lower = label.toLowerCase();
    return lower.contains('name') ||
        lower.contains('customer') ||
        lower.contains('user');
  }

  List<TextInputFormatter>? _inputFormattersFor(String label) {
    if (!_isNameField(label)) return null;

    // Lowercase is allowed while typing. Only valid name characters are
    // accepted; capitalisation is handled only when displayed on invoices.
    return [
      FilteringTextInputFormatter.allow(
      RegExp(r"[A-Za-z0-9\s'\-]"),
    ),
    ];
  }

  Widget _textField({
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    int maxLines = 1,
    String? prefixText,
    bool validate = true,
  }) {
    return TextFormField(
      controller: _controller,
      keyboardType: keyboardType,
      inputFormatters: formatters ?? _inputFormattersFor(widget.question.label),
      maxLines: maxLines,
      autovalidateMode:
          validate ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
      style: TextStyle(
        fontSize: R.fs(context, 14),
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A),
      ),
      decoration: _decoration(hint, prefixText: prefixText),
      validator: validate
          ? (v) => validateProviderAnswer(widget.question, v)
          : null,
      onChanged: widget.onChanged,
    );
  }

  Widget _choiceChips() {
    return Wrap(
      spacing: R.sp(context, 8),
      runSpacing: R.sp(context, 8),
      children: widget.question.options.map((option) {
        final selected = _selected == option;

        // Green for a settled payment, brand blue everywhere else —
        // matching the mock's "Paid now" / "Cash" pills.
        final isPositive = option.toLowerCase().contains('paid') ||
            option.toLowerCase() == 'cash';

        final activeColor =
            isPositive ? const Color(0xFF16A34A) : AppColors.primary;

        return GestureDetector(
          onTap: () {
            setState(() => _selected = option);
            widget.onChanged(option);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(
              horizontal: R.sp(context, 16),
              vertical: R.sp(context, 9),
            ),
            decoration: BoxDecoration(
              color: selected ? activeColor : Colors.white,
              borderRadius: BorderRadius.circular(R.radius(context, 20)),
              border: Border.all(
                color: selected ? activeColor : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              option,
              style: TextStyle(
                fontSize: R.fs(context, 13),
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) return;

    final text = '${picked.day.toString().padLeft(2, '0')}/'
        '${picked.month.toString().padLeft(2, '0')}/'
        '${picked.year}';

    _controller.text = text;

    widget.onChanged(text);
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;

    Widget field;

    switch (q.type) {
      case ProviderFieldType.choice:
        field = _choiceChips();
        break;

      case ProviderFieldType.amount:
        field = _textField(
          hint: 'amount',
          prefixText: '₹ ',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          formatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
        );
        break;

      case ProviderFieldType.number:
        field = _textField(
          hint: q.label.toLowerCase().contains('phone') ||
                  q.label.toLowerCase().contains('mobile') ||
                  q.label.toLowerCase().contains('contact')
              ? '10-digit number'
              : 'Enter number',
          keyboardType: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly],
        );
        break;

      case ProviderFieldType.paragraph:
        field = _textField(hint: 'Enter details', maxLines: 3);
        break;

      case ProviderFieldType.date:
        field = GestureDetector(
          onTap: _pickDate,
          child: AbsorbPointer(
            child: _textField(hint: 'dd/mm/yyyy', validate: false),
          ),
        );
        break;

      case ProviderFieldType.shortText:
        field = _textField(hint: 'Enter ${q.label.toLowerCase()}');
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: R.sp(context, 6)),
          child: Text(
            q.required ? q.label : '${q.label} (optional)',
            style: TextStyle(
              fontSize: R.fs(context, 13),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
          ),
        ),
        field,
      ],
    );
  }
}
