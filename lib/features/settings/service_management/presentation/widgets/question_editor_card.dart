// lib/features/settings/service_management/presentation/widgets/question_editor_card.dart

import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../../../core/utils/validators.dart';
import '../../data/models/service_question_model.dart';
import '../../domain/enums/question_type.dart';
import 'question_type_picker_sheet.dart';

/// A single editable question row inside the "Add Service" builder.
class QuestionEditorCard extends StatefulWidget {
  final ServiceQuestionModel question;
  final int index;
  final ValueChanged<ServiceQuestionModel> onChanged;
  final VoidCallback onDelete;
  final bool autoFocus;

  const QuestionEditorCard({
    super.key,
    required this.question,
    required this.index,
    required this.onChanged,
    required this.onDelete,
    this.autoFocus = false,
  });

  @override
  State<QuestionEditorCard> createState() => _QuestionEditorCardState();
}

class _QuestionEditorCardState extends State<QuestionEditorCard> {
  late TextEditingController _labelController;
  late List<TextEditingController> _optionControllers;
  late FocusNode _labelFocusNode;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.question.label);
    _labelFocusNode = FocusNode();

    _optionControllers = widget.question.options
        .map((o) => TextEditingController(text: o))
        .toList();
    if (_optionControllers.isEmpty && widget.question.type.hasOptions) {
      _optionControllers.add(TextEditingController());
    }

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _labelFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _labelFocusNode.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      widget.question.copyWith(
        label: _labelController.text,
        options: _optionControllers
            .map((c) => c.text)
            .where((t) => t.trim().isNotEmpty)
            .toList(),
      ),
    );
  }

  Future<void> _changeType() async {
    final picked = await showQuestionTypePicker(context);
    if (picked == null) return;
    setState(() {
      if (picked.hasOptions && _optionControllers.isEmpty) {
        _optionControllers.add(TextEditingController());
      }
    });
    widget.onChanged(
      widget.question.copyWith(
        type: picked,
        options: picked.hasOptions
            ? _optionControllers.map((c) => c.text).toList()
            : [],
      ),
    );
  }

  String _getTypeTitle(QuestionType type) {
    switch (type.name.toLowerCase()) {
      case 'short_answer':
      case 'shortanswer':
        return 'Single-line text';
      case 'paragraph':
        return 'Long text';
      case 'multiple_choice':
      case 'multiplechoice':
        return 'Choose one';
      case 'checkboxes':
        return 'Choose multiple';
      case 'dropdown':
        return 'Select from list';
      case 'date':
        return 'Select date';
      case 'time':
        return 'Select time';
      case 'file_upload':
      case 'fileupload':
        return 'Upload file';
      default:
        return type.name;
    }
  }

  IconData _getTypeIcon(QuestionType type) {
    switch (type.name.toLowerCase()) {
      case 'short_answer':
      case 'shortanswer':
        return Icons.short_text_rounded;
      case 'paragraph':
        return Icons.subject_rounded;
      case 'multiple_choice':
      case 'multiplechoice':
        return Icons.radio_button_checked_rounded;
      case 'checkboxes':
        return Icons.check_box_rounded;
      case 'dropdown':
        return Icons.keyboard_arrow_down_rounded;
      case 'date':
        return Icons.calendar_month_rounded;
      case 'time':
        return Icons.access_time_rounded;
      case 'file_upload':
      case 'fileupload':
        return Icons.file_upload_outlined;
      default:
        return Icons.tune;
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final cardRadius = R.radius(context, 10);
    final pad = R.sp(context, 12);

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(R.radius(context, 8)),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header: Index, Label, Delete ─────────────────────────
          Row(
            children: [
              Container(
                width: R.sp(context, 26),
                height: R.sp(context, 26),
                decoration: const BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${widget.index}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: R.fs(context, 12),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _labelController,
                  focusNode: _labelFocusNode,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: TextStyle(
                    fontSize: R.fs(context, 14),
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Question label (e.g. Full Name)',
                    hintStyle: TextStyle(
                      fontSize: R.fs(context, 13),
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.normal,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: R.sp(context, 10),
                      vertical: R.sp(context, 8),
                    ),
                    filled: true,
                    fillColor: AppColors.surface2,
                    enabledBorder: inputBorder.copyWith(
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: inputBorder.copyWith(
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.2,
                      ),
                    ),
                    errorBorder: inputBorder.copyWith(
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                    focusedErrorBorder: inputBorder.copyWith(
                      borderSide: const BorderSide(
                        color: Colors.redAccent,
                        width: 1.2,
                      ),
                    ),
                    errorStyle: TextStyle(fontSize: R.fs(context, 10.5)),
                  ),
                  validator: (v) => Validators.validateQuestionLabel(v ?? ''),
                  onChanged: (_) => _emit(),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.red.shade400,
                  size: R.icon(context, 20),
                ),
                onPressed: widget.onDelete,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ─── Question Type Selector Button ────────────────────────
          InkWell(
            onTap: _changeType,
            borderRadius: BorderRadius.circular(R.radius(context, 8)),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: R.sp(context, 12),
                vertical: R.sp(context, 10),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(R.radius(context, 8)),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getTypeIcon(q.type),
                        size: R.icon(context, 16),
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getTypeTitle(q.type),
                        style: TextStyle(
                          fontSize: R.fs(context, 13),
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey.shade600,
                    size: R.icon(context, 20),
                  ),
                ],
              ),
            ),
          ),

          // ─── Choice Options ───────────────────────────────────────
          if (q.type.hasOptions) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                'Options',
                style: TextStyle(
                  fontSize: R.fs(context, 12),
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            ..._optionControllers.asMap().entries.map((entry) {
              final i = entry.key;
              final controller = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: R.sp(context, 6)),
                child: Row(
                  children: [
                    Container(
                      width: R.sp(context, 20),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}.',
                        style: TextStyle(
                          fontSize: R.fs(context, 12),
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        style: TextStyle(
                          fontSize: R.fs(context, 13),
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Option ${i + 1}',
                          hintStyle: TextStyle(
                            fontSize: R.fs(context, 13),
                            color: Colors.grey.shade400,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: R.sp(context, 10),
                            vertical: R.sp(context, 8),
                          ),
                          filled: true,
                          fillColor: AppColors.surface2,
                          enabledBorder: inputBorder.copyWith(
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: inputBorder.copyWith(
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.2,
                            ),
                          ),
                          errorBorder: inputBorder.copyWith(
                            borderSide: const BorderSide(color: Colors.redAccent),
                          ),
                          focusedErrorBorder: inputBorder.copyWith(
                            borderSide: const BorderSide(
                              color: Colors.redAccent,
                              width: 1.2,
                            ),
                          ),
                          errorStyle: TextStyle(fontSize: R.fs(context, 10.5)),
                        ),
                        validator: (v) => Validators.validateChoiceOption(
                          v ?? '',
                          fieldName: 'Option ${i + 1}',
                        ),
                        onChanged: (_) => _emit(),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.close,
                        size: R.icon(context, 16),
                        color: Colors.grey.shade500,
                      ),
                      onPressed: () {
                        setState(() => _optionControllers.removeAt(i));
                        _emit();
                      },
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 4),
            InkWell(
              onTap: () => setState(
                () => _optionControllers.add(TextEditingController()),
              ),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: R.sp(context, 6),
                  vertical: R.sp(context, 4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: R.icon(context, 14),
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Add option',
                      style: TextStyle(
                        fontSize: R.fs(context, 12),
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),

          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 8),

          // ─── Required Switch ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: R.icon(context, 16),
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Required Field',
                    style: TextStyle(
                      fontSize: R.fs(context, 13),
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Switch.adaptive(
                value: q.required,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                onChanged: (v) => widget.onChanged(q.copyWith(required: v)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
