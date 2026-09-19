// lib/core/widgets/dynamic_question_field.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../features/settings/service_management/domain/entities/service_question.dart';
import '../../features/settings/service_management/domain/enums/question_type.dart';
import '../constants/app_colors.dart';
import '../utils/responsive_helper.dart';
import '../utils/validators.dart';

class DynamicQuestionField extends StatefulWidget {
  final int index;
  final ServiceQuestionEntity question;
  final Object? initialValue;
  final bool enabled;
  final ValueChanged<Object?> onChanged;

  const DynamicQuestionField({
    super.key,
    required this.index,
    required this.question,
    this.initialValue,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  State<DynamicQuestionField> createState() => _DynamicQuestionFieldState();
}

/// Shared with [ServiceFormScreen] so the same rule that blocks the
/// field as you type also blocks the "Review" button if a bad value
/// slipped through (paste, autofill, etc).
///
/// Every rule lives in Validators, picked by what the question is
/// actually asking for: a "name"-ish label needs a capitalised,
/// letters-only name of at least 3 letters; a "phone"-ish label
/// needs exactly 10 digits with no spaces; a "plan"-ish label allows
/// alphanumeric; an "amount"-ish label must be a number greater than
/// 0 (0 is never accepted).
String? validateServiceShortAnswer(ServiceQuestionEntity q, Object? rawValue) {
  final value = rawValue?.toString() ?? '';
  final label = q.label.toLowerCase();

  if (label.contains('phone') ||
      label.contains('mobile') ||
      label.contains('contact')) {
    return q.required
        ? Validators.validatePhone(value, fieldName: q.label)
        : Validators.validateOptionalPhone(value, fieldName: q.label);
  }

  if (label.contains('email') || label.contains('mail')) {
    return q.required
        ? Validators.validateEmail(value)
        : Validators.validateOptionalEmail(value);
  }

  if (label.contains('amount') ||
      label.contains('price') ||
      label.contains('fee') ||
      label.contains('cost')) {
    return Validators.validateCustomerAmount(
      value,
      fieldName: q.label,
      required: q.required,
    );
  }

  if (label.contains('plan')) {
    // Plan names/descriptions are alphanumeric ("199 Unlimited"),
    // unlike a person's name, so this gets its own rule.
    return Validators.validatePlanName(
      value,
      fieldName: q.label,
      required: q.required,
    );
  }

  if (label.contains('name') ||
      label.contains('customer') ||
      label.contains('user')) {
    // Optional name field left blank is fine; once they start
    // typing, the usual capital-letter / 3-letter name rule applies.
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
}

/// Same idea as [validateServiceShortAnswer], for paragraph answers.
String? validateServiceParagraphAnswer(
  ServiceQuestionEntity q,
  Object? rawValue,
) {
  return Validators.validateParagraphAnswer(
    rawValue?.toString() ?? '',
    fieldName: q.label,
    required: q.required,
  );
}

class _DynamicQuestionFieldState extends State<DynamicQuestionField> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.initialValue?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant DynamicQuestionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _textController.text = widget.initialValue?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Widget? _getPrefixIcon(String label, QuestionType type) {
    final lower = label.toLowerCase();

    if (lower.contains('name') ||
        lower.contains('user') ||
        lower.contains('customer')) {
      return const Icon(
        Icons.person_outline_rounded,
        size: 20,
        color: Color(0xFF64748B),
      );
    }
    if (lower.contains('phone') ||
        lower.contains('mobile') ||
        lower.contains('contact')) {
      return Container(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.phone_outlined,
              size: 19,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            const Text(
              '+91',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 10),
            Container(height: 18, width: 1, color: const Color(0xFFCBD5E1)),
          ],
        ),
      );
    }
    if (lower.contains('email') || lower.contains('mail')) {
      return const Icon(
        Icons.mail_outline_rounded,
        size: 20,
        color: Color(0xFF64748B),
      );
    }
    if (lower.contains('amount') ||
        lower.contains('price') ||
        lower.contains('fee') ||
        lower.contains('cost')) {
      return const Icon(
        Icons.currency_rupee_rounded,
        size: 20,
        color: Color(0xFF64748B),
      );
    }
    if (lower.contains('url') ||
        lower.contains('link') ||
        lower.contains('website')) {
      return const Icon(Icons.link_rounded, size: 20, color: Color(0xFF64748B));
    }
    if (type == QuestionType.date) {
      return const Icon(
        Icons.calendar_today_outlined,
        size: 19,
        color: Color(0xFF64748B),
      );
    }
    if (type == QuestionType.time) {
      return const Icon(
        Icons.access_time_rounded,
        size: 20,
        color: Color(0xFF64748B),
      );
    }
    if (type == QuestionType.fileUpload) {
      return const Icon(
        Icons.upload_file_outlined,
        size: 22,
        color: Color(0xFF2563EB),
      );
    }

    return null;
  }

  Future<void> _pickFile() async {
    if (!widget.enabled) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path;
        if (path != null) {
          widget.onChanged(path);
        }
      }
    } catch (_) {
      // Catch file picker platform exceptions
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final formattedLabel = _capitalize(
      q.label.isEmpty ? 'Untitled Field' : q.label,
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Prominent Question Label ───
        RichText(
          text: TextSpan(
            text: formattedLabel,
            style: TextStyle(
              fontSize: R.fs(context, 16),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
            ),
            children: [
              if (q.required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ─── Input Widget ───
        _buildInputField(context, q, formattedLabel, inputBorder),
      ],
    );
  }

  Widget _buildInputField(
    BuildContext context,
    ServiceQuestionEntity q,
    String formattedLabel,
    OutlineInputBorder border,
  ) {
    final prefix = _getPrefixIcon(q.label, q.type);

    final errorBorder = border.copyWith(
      borderSide: const BorderSide(color: Colors.redAccent),
    );
    final focusedErrorBorder = border.copyWith(
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
    );

    switch (q.type) {
      case QuestionType.shortAnswer:
        return TextFormField(
          controller: _textController,
          enabled: widget.enabled,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          keyboardType: q.label.toLowerCase().contains('phone') ||
                  q.label.toLowerCase().contains('mobile') ||
                  q.label.toLowerCase().contains('contact')
              ? TextInputType.phone
              : q.label.toLowerCase().contains('email')
                  ? TextInputType.emailAddress
                  : TextInputType.text,
          style: TextStyle(
            fontSize: R.fs(context, 15),
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: 'Enter ${q.label.toLowerCase()}',
            hintStyle: TextStyle(
              fontSize: R.fs(context, 15),
              color: const Color(0xFF94A3B8),
            ),
            prefixIcon: prefix != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: prefix,
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(
                color: AppColors.cyanDim,
                width: 1.5,
              ),
            ),
            errorBorder: errorBorder,
            focusedErrorBorder: focusedErrorBorder,
            errorStyle: TextStyle(fontSize: R.fs(context, 11.5)),
          ),
          validator: (v) => validateServiceShortAnswer(q, v),
          onChanged: widget.onChanged,
        );

      case QuestionType.paragraph:
        return TextFormField(
          controller: _textController,
          enabled: widget.enabled,
          maxLines: 4,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: TextStyle(
            fontSize: R.fs(context, 15),
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: 'Enter ${q.label.toLowerCase()} (optional)',
            hintStyle: TextStyle(
              fontSize: R.fs(context, 15),
              color: const Color(0xFF94A3B8),
            ),
            contentPadding: const EdgeInsets.all(16),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(
                color: AppColors.cyanDim,
                width: 1.5,
              ),
            ),
            errorBorder: errorBorder,
            focusedErrorBorder: focusedErrorBorder,
            errorStyle: TextStyle(fontSize: R.fs(context, 11.5)),
          ),
          validator: (v) => validateServiceParagraphAnswer(q, v),
          onChanged: widget.onChanged,
        );

      case QuestionType.multipleChoice:
        final selected = widget.initialValue?.toString() ?? '';
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 24,
            runSpacing: 12,
            children: q.options.map((opt) {
              final formattedOpt = _capitalize(opt);
              final isSelected = selected.toLowerCase() == opt.toLowerCase();

              return InkWell(
                onTap: widget.enabled ? () => widget.onChanged(opt) : null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFCBD5E1),
                            width: isSelected ? 6.5 : 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        formattedOpt,
                        style: TextStyle(
                          fontSize: R.fs(context, 15),
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );

      case QuestionType.checkboxes:
        final selectedList = widget.initialValue is List
            ? List<String>.from(widget.initialValue as List)
            : <String>[];
        return Column(
          children: q.options.map((opt) {
            final formattedOpt = _capitalize(opt);
            final isSelected = selectedList.contains(opt);
            return InkWell(
              onTap: widget.enabled
                  ? () {
                      final updated = List<String>.from(selectedList);
                      if (isSelected) {
                        updated.remove(opt);
                      } else {
                        updated.add(opt);
                      }
                      widget.onChanged(updated);
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: 24,
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFCBD5E1),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      formattedOpt,
                      style: TextStyle(
                        fontSize: R.fs(context, 15),
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );

      case QuestionType.dropdown:
        return DropdownButtonFormField<String>(
          initialValue: q.options.contains(widget.initialValue)
              ? widget.initialValue?.toString()
              : null,
          style: TextStyle(
            fontSize: R.fs(context, 15),
            color: const Color(0xFF0F172A),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF64748B),
          ),
          decoration: InputDecoration(
            hintText: 'Select option',
            hintStyle: TextStyle(
              fontSize: R.fs(context, 15),
              color: const Color(0xFF94A3B8),
            ),
            prefixIcon: prefix != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: prefix,
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(
                color: AppColors.cyanDim,
                width: 1.5,
              ),
            ),
          ),
          items: q.options
              .map(
                (o) => DropdownMenuItem(value: o, child: Text(_capitalize(o))),
              )
              .toList(),
          onChanged: widget.enabled ? widget.onChanged : null,
        );

      case QuestionType.date:
      case QuestionType.time:
        return InkWell(
          onTap: widget.enabled
              ? () async {
                  if (q.type == QuestionType.date) {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      widget.onChanged(
                        picked.toIso8601String().split('T').first,
                      );
                    }
                  } else {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      widget.onChanged(picked.format(context));
                    }
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            ),
            child: Row(
              children: [
                if (prefix != null) ...[prefix, const SizedBox(width: 12)],
                Expanded(
                  child: Text(
                    widget.initialValue?.toString() ??
                        (q.type == QuestionType.date
                            ? 'Select date'
                            : 'Select time'),
                    style: TextStyle(
                      fontSize: R.fs(context, 15),
                      color: widget.initialValue != null
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case QuestionType.fileUpload:
        final selectedPath = widget.initialValue?.toString() ?? '';
        final hasFile = selectedPath.isNotEmpty;
        final fileName = hasFile
            ? selectedPath.split(RegExp(r'[/\\]')).last
            : '';

        return InkWell(
          onTap: _pickFile,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: hasFile ? const Color(0xFFF1F5F9) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasFile
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasFile
                      ? Icons.file_present_rounded
                      : Icons.upload_file_outlined,
                  size: 22,
                  color: const Color(0xFF2563EB),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasFile ? fileName : 'Upload attachment',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: R.fs(context, 15),
                      fontWeight: hasFile ? FontWeight.w600 : FontWeight.w500,
                      color: hasFile
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                if (hasFile && widget.enabled)
                  GestureDetector(
                    onTap: () => widget.onChanged(null),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ),
        );
    }
  }
}
