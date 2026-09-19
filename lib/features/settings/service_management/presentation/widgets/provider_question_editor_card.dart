// lib/features/settings/service_management/presentation/widgets/provider_question_editor_card.dart

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../../../core/utils/validators.dart';
import '../../data/models/provider_question_model.dart';
import '../../domain/enums/provider_field_type.dart';

/// One editable row in the "Recharge questions" list.
///
/// Collapsed it shows `label` + `type · required`; tapping the kebab opens
/// the inline editor for label, required flag and choice options.
class ProviderQuestionEditorCard extends StatefulWidget {
  final ProviderQuestionModel question;
  final bool autoFocus;
  final ValueChanged<ProviderQuestionModel> onChanged;
  final VoidCallback onDelete;

  const ProviderQuestionEditorCard({
    super.key,
    required this.question,
    required this.onChanged,
    required this.onDelete,
    this.autoFocus = false,
  });

  @override
  State<ProviderQuestionEditorCard> createState() =>
      _ProviderQuestionEditorCardState();
}

class _ProviderQuestionEditorCardState
    extends State<ProviderQuestionEditorCard> {
  late final TextEditingController _labelController;
  late List<TextEditingController> _optionControllers;

  bool _expanded = false;

  @override
  void initState() {
    super.initState();

    _labelController = TextEditingController(text: widget.question.label);

    _optionControllers = widget.question.options
        .map((o) => TextEditingController(text: o))
        .toList();

    _expanded = widget.autoFocus || widget.question.label.trim().isEmpty;
  }

  @override
  void dispose() {
    _labelController.dispose();

    for (final c in _optionControllers) {
      c.dispose();
    }

    super.dispose();
  }

  void _emit({
    String? label,
    bool? required,
    List<String>? options,
  }) {
    widget.onChanged(
      widget.question.copyWith(
        label: label,
        required: required,
        options: options,
      ),
    );
  }

  IconData get _typeIcon {
    switch (widget.question.type) {
      case ProviderFieldType.shortText:
        return Icons.short_text_rounded;
      case ProviderFieldType.paragraph:
        return Icons.notes_rounded;
      case ProviderFieldType.number:
        return Icons.pin_rounded;
      case ProviderFieldType.amount:
        return Icons.currency_rupee_rounded;
      case ProviderFieldType.choice:
        return Icons.radio_button_checked_rounded;
      case ProviderFieldType.date:
        return Icons.calendar_today_rounded;
    }
  }

  InputDecoration _fieldDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: R.fs(context, 13),
        color: const Color(0xFF94A3B8),
      ),
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: EdgeInsets.symmetric(
        horizontal: R.sp(context, 12),
        vertical: R.sp(context, 11),
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
      errorStyle: TextStyle(fontSize: R.fs(context, 11)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final cardRadius = R.radius(context, 12);

    return Container(
      margin: EdgeInsets.only(bottom: R.sp(context, 10)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ─── Collapsed header row ───
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: R.sp(context, 12),
              vertical: R.sp(context, 12),
            ),
            child: Row(
              children: [
                Container(
                  width: R.sp(context, 34),
                  height: R.sp(context, 34),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(R.radius(context, 8)),
                  ),
                  child: Icon(
                    _typeIcon,
                    size: 18,
                    color: const Color(0xFF2563EB),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q.label.trim().isEmpty ? 'Untitled question' : q.label,
                        style: TextStyle(
                          fontSize: R.fs(context, 14),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        q.type == ProviderFieldType.choice
                            ? '${q.type.label} · ${q.options.join(" / ")}'
                            : '${q.type.label} · ${q.required ? "required" : "optional"}',
                        style: TextStyle(
                          fontSize: R.fs(context, 11.5),
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
              ],
            ),
          ),

          // ─── Expanded editor ───
          if (_expanded) ...[
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: EdgeInsets.fromLTRB(
                R.sp(context, 12),
                R.sp(context, 12),
                R.sp(context, 12),
                R.sp(context, 12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _labelController,
                    autofocus: widget.autoFocus,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    style: TextStyle(
                      fontSize: R.fs(context, 14),
                      color: const Color(0xFF0F172A),
                    ),
                    decoration: _fieldDecoration(context, 'Question label'),
                    validator: (v) => Validators.validateQuestionLabel(v ?? ''),
                    onChanged: (v) => _emit(label: v),
                  ),

                  if (q.type.hasOptions) ...[
                    SizedBox(height: R.sp(context, 12)),
                    Text(
                      'Options',
                      style: TextStyle(
                        fontSize: R.fs(context, 12.5),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: R.sp(context, 6)),
                    ..._optionControllers.asMap().entries.map((entry) {
                      final i = entry.key;

                      return Padding(
                        padding: EdgeInsets.only(bottom: R.sp(context, 8)),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: entry.value,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                style: TextStyle(
                                  fontSize: R.fs(context, 13.5),
                                  color: const Color(0xFF0F172A),
                                ),
                                decoration: _fieldDecoration(
                                  context,
                                  'Option ${i + 1}',
                                ),
                                validator: (v) => Validators.validateChoiceOption(
                                  v ?? '',
                                  fieldName: 'Option ${i + 1}',
                                ),
                                onChanged: (_) => _emit(
                                  options: _optionControllers
                                      .map((c) => c.text)
                                      .toList(),
                                ),
                              ),
                            ),
                            if (_optionControllers.length > 1)
                              IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Color(0xFF94A3B8),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _optionControllers.removeAt(i).dispose();
                                  });

                                  _emit(
                                    options: _optionControllers
                                        .map((c) => c.text)
                                        .toList(),
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _optionControllers.add(TextEditingController());
                        });
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Add option',
                            style: TextStyle(
                              fontSize: R.fs(context, 13),
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: R.sp(context, 6)),

                  Row(
                    children: [
                      Switch(
                        value: q.required,
                        activeThumbColor: AppColors.primary,
                        activeTrackColor: AppColors.primary.withValues(
                          alpha: 0.3,
                        ),
                        inactiveThumbColor: const Color(0xFFF8FAFC),
                        inactiveTrackColor: const Color(0xFFCBD5E1),
                        onChanged: (v) => _emit(required: v),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        q.required ? 'Required (On)' : 'Required (Off)',
                        style: TextStyle(
                          fontSize: R.fs(context, 13),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: widget.onDelete,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Colors.red,
                        ),
                        label: Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: R.fs(context, 13),
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
