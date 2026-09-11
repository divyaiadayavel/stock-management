// lib/features/settings/service_management/presentation/screens/add_edit_service_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../data/models/service_model.dart';
import '../../data/models/service_question_model.dart';
import '../../domain/enums/question_type.dart';
import '../providers/service_management_provider.dart';
import '../widgets/question_editor_card.dart';
import 'preview_service_screen.dart';

class AddEditServiceScreen extends ConsumerStatefulWidget {
  final int? presetCategoryId;
  final String? presetCategoryName;
  final int? existingServiceId;

  const AddEditServiceScreen({
    super.key,
    this.presetCategoryId,
    this.presetCategoryName,
    this.existingServiceId,
  });

  @override
  ConsumerState<AddEditServiceScreen> createState() =>
      _AddEditServiceScreenState();
}

class _AddEditServiceScreenState extends ConsumerState<AddEditServiceScreen> {
  final _nameController = TextEditingController();

  int? _categoryId;
  String? _categoryName;

  List<ServiceQuestionModel> _questions = [];
  String? _newlyAddedLocalId;

  bool _loadedExisting = false;

  // New service: charge is enabled by default.
  bool _chargeEnabled = true;

  @override
  void initState() {
    super.initState();

    _categoryId = widget.presetCategoryId;
    _categoryName = widget.presetCategoryName;
  }

  @override
  void dispose() {
    _nameController.dispose();

    super.dispose();
  }

  void _hydrateFromExisting(ServiceModel service) {
    if (_loadedExisting) return;

    _loadedExisting = true;

    _nameController.text = service.name;

    _categoryId = service.categoryId;
    _categoryName = service.categoryName;

    _questions = List.of(service.questionModels);

    _chargeEnabled = service.chargeEnabled;
  }

  // ─────────────────────────────────────────────────────────────
  // ADD QUESTION
  // ─────────────────────────────────────────────────────────────
  Future<void> _addQuestion() async {
    final type = await _showQuestionTypePicker();

    if (type == null) return;

    final newId = 'new_${DateTime.now().microsecondsSinceEpoch}';

    setState(() {
      _newlyAddedLocalId = newId;
      _questions.add(
        ServiceQuestionModel(
          localId: newId,
          label: '',
          type: type,
          required: true,
          options: type.hasOptions ? const ['Option 1'] : const [],
          order: _questions.length,
        ),
      );
    });

    // Reset newly added ID after frame to prevent focus stealing on subsequent typing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _newlyAddedLocalId = null;
        });
      }
    });
  }

  // ─────────────────────────────────────────────────────────────
  // QUESTION TYPE LOOKUP
  // ─────────────────────────────────────────────────────────────
  QuestionType? _questionType(String wantedName) {
    final wanted = wantedName
        .replaceAll('_', '')
        .replaceAll('-', '')
        .toLowerCase();

    for (final type in QuestionType.values) {
      final current = type.name
          .replaceAll('_', '')
          .replaceAll('-', '')
          .toLowerCase();

      if (current == wanted) {
        return type;
      }
    }

    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // QUESTION TYPE PICKER
  // ─────────────────────────────────────────────────────────────
  Future<QuestionType?> _showQuestionTypePicker() async {
    return showModalBottomSheet<QuestionType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _QuestionTypePickerSheet(responsive: R, findType: _questionType);
      },
    );
  }

  Future<void> _confirmDeleteQuestion(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(R.radius(context, 16)),
        ),
        title: Text(
          'Delete question?',
          style: TextStyle(
            fontSize: R.fs(context, 18),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to remove this question?',
          style: TextStyle(
            fontSize: R.fs(context, 13),
            color: Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _questions.removeAt(index);
      });
    }
  }

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty && _categoryId != null;

  ServiceModel _buildDraft() {
    return ServiceModel(
      id: widget.existingServiceId,
      name: _nameController.text.trim(),
      categoryId: _categoryId,
      categoryName: _categoryName ?? '',
      questions: _questions,
      chargeEnabled: _chargeEnabled,
    );
  }

  Future<void> _save() async {
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a service name and choose a category.'),
        ),
      );
      return;
    }

    final draft = _buildDraft();

    final ops = ref.read(serviceOperationsProvider.notifier);

    final success = widget.existingServiceId == null
        ? (await ops.saveNewService(draft)) != null
        : await ops.saveExistingService(draft);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save service. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hPad = R.hPad(context, base: 16);

    final isEditing = widget.existingServiceId != null;

    Widget content = _buildForm();

    if (widget.existingServiceId != null && !_loadedExisting) {
      final detailAsync = ref.watch(
        serviceDetailProvider(widget.existingServiceId!),
      );

      content = detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2.5,
          ),
        ),
        error: (e, _) => Center(
          child: Text(
            'Failed to load service: $e',
            style: TextStyle(
              fontSize: R.fs(context, 14),
              color: Colors.grey.shade700,
            ),
          ),
        ),
        data: (service) {
          _hydrateFromExisting(service);
          return _buildForm();
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ─────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: hPad.left,
                vertical: R.sp(context, 10),
              ),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Service' : 'Add Service',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                        fontSize: R.fs(context, 18),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (!_isValid) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Enter a service name and choose a category first.',
                            ),
                          ),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PreviewServiceScreen(service: _buildDraft()),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: R.sp(context, 12),
                        vertical: R.sp(context, 6),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(
                          R.radius(context, 8),
                        ),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: R.icon(context, 15),
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Preview',
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
              ),
            ),

            const SizedBox(height: 6),

            // ─── Main Form ──────────────────────────────────
            Expanded(child: content),

            // ─── Bottom Actions ──────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                hPad.left,
                R.sp(context, 6),
                hPad.left,
                R.sp(context, 14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _addQuestion,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: R.sp(context, 12),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          R.radius(context, 10),
                        ),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Add Question',
                            style: TextStyle(
                              fontSize: R.fs(context, 13),
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  GestureDetector(
                    onTap: _save,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: R.sp(context, 14),
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(
                          R.radius(context, 10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          isEditing ? 'Update Service' : 'Save Service',
                          style: TextStyle(
                            fontSize: R.fs(context, 14),
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
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);

    final hPad = R.hPad(context, base: 16);

    final labelStyle = TextStyle(
      fontSize: R.fs(context, 13),
      fontWeight: FontWeight.w600,
      color: const Color(0xFF0F172A),
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(R.radius(context, 10)),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    );

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: hPad.left),
      children: [
        const SizedBox(height: 6),

        // ─── Service Name ───────────────────────────────────
        Text('Service Name', style: labelStyle),

        const SizedBox(height: 6),

        TextField(
          controller: _nameController,
          style: TextStyle(
            fontSize: R.fs(context, 14),
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: 'Enter service name',
            hintStyle: TextStyle(
              fontSize: R.fs(context, 14),
              color: const Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: R.sp(context, 14),
              vertical: R.sp(context, 12),
            ),
            enabledBorder: inputBorder,
            focusedBorder: inputBorder.copyWith(
              borderSide: const BorderSide(
                color: AppColors.cyanDim,
                width: 1.5,
              ),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: 16),

        // ─── Category ───────────────────────────────────────
        Text('Category', style: labelStyle),

        const SizedBox(height: 6),

        categoriesAsync.when(
          loading: () => const LinearProgressIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface2,
          ),
          error: (e, _) => Text(
            'Failed to load categories: $e',
            style: TextStyle(
              fontSize: R.fs(context, 12),
              color: Colors.red.shade400,
            ),
          ),
          data: (categories) => DropdownButtonFormField<int>(
            initialValue: categories.any((c) => c.id == _categoryId)
                ? _categoryId
                : null,
            style: TextStyle(
              fontSize: R.fs(context, 14),
              color: const Color(0xFF0F172A),
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF64748B),
            ),
            decoration: InputDecoration(
              hintText: 'Select category',
              hintStyle: TextStyle(
                fontSize: R.fs(context, 14),
                color: const Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: R.sp(context, 14),
                vertical: R.sp(context, 12),
              ),
              enabledBorder: inputBorder,
              focusedBorder: inputBorder.copyWith(
                borderSide: const BorderSide(
                  color: AppColors.cyanDim,
                  width: 1.5,
                ),
              ),
            ),
            items: categories
                .map<DropdownMenuItem<int>>(
                  (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                )
                .toList(),
            onChanged: (id) {
              final match = categories.firstWhere((c) => c.id == id);

              setState(() {
                _categoryId = id;
                _categoryName = match.name;
              });
            },
          ),
        ),

        const SizedBox(height: 16),

        // ─── Service Charge Configuration ─────────────────────
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: R.sp(context, 14),
            vertical: R.sp(context, 12),
          ),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(R.radius(context, 10)),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _chargeEnabled
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.currency_rupee_rounded,
                  size: 19,
                  color: _chargeEnabled
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Service Charge', style: labelStyle),
                    const SizedBox(height: 3),
                    Text(
                      _chargeEnabled
                          ? 'User must enter the charge for each request'
                          : 'No charge will be collected for this service',
                      style: TextStyle(
                        fontSize: R.fs(context, 11),
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: _chargeEnabled,
                activeTrackColor: AppColors.primary,
                onChanged: (enabled) {
                  setState(() {
                    _chargeEnabled = enabled;
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ─── Questions ──────────────────────────────────────
        Text('Questions', style: labelStyle),

        const SizedBox(height: 8),

        if (_questions.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: R.sp(context, 32),
              horizontal: R.sp(context, 16),
            ),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(R.radius(context, 12)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: R.icon(context, 48),
                  color: const Color(0xFF94A3B8),
                ),
                const SizedBox(height: 12),
                Text(
                  'No questions added yet',
                  style: TextStyle(
                    fontSize: R.fs(context, 15),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add questions to build your service form.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: R.fs(context, 12),
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          )
        else
          ..._questions.asMap().entries.map((entry) {
            final i = entry.key;
            final q = entry.value;
            final isNew = q.localId == _newlyAddedLocalId;

            return Padding(
              padding: EdgeInsets.only(bottom: R.sp(context, 10)),
              child: QuestionEditorCard(
                key: ValueKey(q.localId),
                index: i + 1,
                question: q,
                autoFocus: isNew,
                onChanged: (updated) {
                  setState(() {
                    _questions[i] = updated;
                  });
                },
                onDelete: () => _confirmDeleteQuestion(i),
              ),
            );
          }),

        const SizedBox(height: 16),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// QUESTION TYPE PICKER SHEET
// ═══════════════════════════════════════════════════════════════

class _QuestionTypePickerSheet extends StatefulWidget {
  final dynamic responsive;
  final QuestionType? Function(String name) findType;

  const _QuestionTypePickerSheet({
    required this.responsive,
    required this.findType,
  });

  @override
  State<_QuestionTypePickerSheet> createState() =>
      _QuestionTypePickerSheetState();
}

class _QuestionTypePickerSheetState extends State<_QuestionTypePickerSheet> {
  int? _expandedIndex;

  List<_QuestionTypeInfo> get _questionTypes => [
    _QuestionTypeInfo(
      key: 'short_answer',
      title: 'Single-line text',
      bestFor: 'Names, phone numbers, emails',
      icon: Icons.short_text_rounded,
      example: const _ShortAnswerExample(),
    ),
    _QuestionTypeInfo(
      key: 'paragraph',
      title: 'Long text',
      bestFor: 'Addresses, descriptions, comments',
      icon: Icons.subject_rounded,
      example: const _ParagraphExample(),
    ),
    _QuestionTypeInfo(
      key: 'multiple_choice',
      title: 'Choose one',
      bestFor: 'Gender, type selection, yes/no',
      icon: Icons.radio_button_checked_rounded,
      example: const _MultipleChoiceExample(),
    ),
    _QuestionTypeInfo(
      key: 'checkboxes',
      title: 'Choose multiple',
      bestFor: 'Documents, preferences, multiple selections',
      icon: Icons.check_box_rounded,
      example: const _CheckboxExample(),
    ),
    _QuestionTypeInfo(
      key: 'dropdown',
      title: 'Select from list',
      bestFor: 'Category, state, type',
      icon: Icons.keyboard_arrow_down_rounded,
      example: const _DropdownExample(),
    ),
    _QuestionTypeInfo(
      key: 'date',
      title: 'Select date',
      bestFor: 'Birth date, appointment date',
      icon: Icons.calendar_month_rounded,
      example: const _DateExample(),
    ),
    _QuestionTypeInfo(
      key: 'time',
      title: 'Select time',
      bestFor: 'Appointment time, schedule',
      icon: Icons.access_time_rounded,
      example: const _TimeExample(),
    ),
    _QuestionTypeInfo(
      key: 'file_upload',
      title: 'Upload file',
      bestFor: 'ID proof, images, documents',
      icon: Icons.file_upload_outlined,
      example: const _FileUploadExample(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final types = _questionTypes;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // TOP HANDLE
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose question type',
                          style: TextStyle(
                            fontSize: R.fs(context, 19),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Select the type of answer you want from the user.',
                          style: TextStyle(
                            fontSize: R.fs(context, 12),
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // QUESTION TYPES
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: types.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = types[index];
                  final isExpanded = _expandedIndex == index;

                  return _QuestionTypeCard(
                    item: item,
                    isExpanded: isExpanded,
                    onExpand: () {
                      setState(() {
                        _expandedIndex = isExpanded ? null : index;
                      });
                    },
                    onSelect: () {
                      final type = widget.findType(item.key);

                      if (type != null) {
                        Navigator.pop(context, type);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// QUESTION TYPE DATA
// ═══════════════════════════════════════════════════════════════

class _QuestionTypeInfo {
  final String key;
  final String title;
  final String bestFor;
  final IconData icon;
  final Widget example;

  const _QuestionTypeInfo({
    required this.key,
    required this.title,
    required this.bestFor,
    required this.icon,
    required this.example,
  });
}

// ═══════════════════════════════════════════════════════════════
// QUESTION TYPE CARD
// ═══════════════════════════════════════════════════════════════

class _QuestionTypeCard extends StatelessWidget {
  final _QuestionTypeInfo item;
  final bool isExpanded;
  final VoidCallback onExpand;
  final VoidCallback onSelect;

  const _QuestionTypeCard({
    required this.item,
    required this.isExpanded,
    required this.onExpand,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? AppColors.primary.withValues(alpha: 0.35)
              : const Color(0xFFE2E8F0),
          width: isExpanded ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isExpanded ? 0.045 : 0.025),
            blurRadius: isExpanded ? 10 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // MAIN TYPE ROW
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onSelect,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ICON
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      item.icon,
                      color: const Color(0xFF475569),
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // TITLE + BEST FOR
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: R.fs(context, 15),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Best for: ',
                                  style: TextStyle(
                                    fontSize: R.fs(context, 10.5),
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                TextSpan(
                                  text: item.bestFor,
                                  style: TextStyle(
                                    fontSize: R.fs(context, 10.5),
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  // DOWN / UP ARROW
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onExpand,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 24,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // EXPANDED EXAMPLE
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Example',
                    style: TextStyle(
                      fontSize: R.fs(context, 11),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  item.example,
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EXAMPLES
// ═══════════════════════════════════════════════════════════════

class _ShortAnswerExample extends StatelessWidget {
  const _ShortAnswerExample();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const Icon(
            Icons.person_outline_rounded,
            size: 19,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(width: 9),
          Text(
            'Enter your name',
            style: TextStyle(
              fontSize: R.fs(context, 12),
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParagraphExample extends StatelessWidget {
  const _ParagraphExample();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      alignment: Alignment.topLeft,
      child: Text(
        'Enter your address, description or comments',
        style: TextStyle(
          fontSize: R.fs(context, 12),
          height: 1.35,
          color: const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}

class _MultipleChoiceExample extends StatelessWidget {
  const _MultipleChoiceExample();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _radioRow('Male', true, context),
        const SizedBox(height: 7),
        _radioRow('Female', false, context),
        const SizedBox(height: 7),
        _radioRow('Other', false, context),
      ],
    );
  }

  Widget _radioRow(String text, bool selected, BuildContext context) {
    return Row(
      children: [
        Icon(
          selected
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 20,
          color: selected ? AppColors.primary : const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 9),
        Text(
          text,
          style: TextStyle(
            fontSize: R.fs(context, 12),
            color: const Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}

class _CheckboxExample extends StatelessWidget {
  const _CheckboxExample();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _checkRow('ID Proof', true, context),
        const SizedBox(height: 7),
        _checkRow('PAN Card', true, context),
        const SizedBox(height: 7),
        _checkRow('Driving License', false, context),
        const SizedBox(height: 7),
        _checkRow('Voter ID', false, context),
      ],
    );
  }

  Widget _checkRow(String text, bool selected, BuildContext context) {
    return Row(
      children: [
        Icon(
          selected
              ? Icons.check_box_rounded
              : Icons.check_box_outline_blank_rounded,
          size: 20,
          color: selected ? AppColors.primary : const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 9),
        Text(
          text,
          style: TextStyle(
            fontSize: R.fs(context, 12),
            color: const Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}

class _DropdownExample extends StatelessWidget {
  const _DropdownExample();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Select an option',
              style: TextStyle(
                fontSize: R.fs(context, 12),
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: Color(0xFF64748B),
          ),
        ],
      ),
    );
  }
}

class _DateExample extends StatelessWidget {
  const _DateExample();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: Color(0xFF64748B),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'DD/MM/YYYY',
              style: TextStyle(
                fontSize: R.fs(context, 12),
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: Color(0xFF64748B),
          ),
        ],
      ),
    );
  }
}

class _TimeExample extends StatelessWidget {
  const _TimeExample();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time_rounded,
            size: 19,
            color: Color(0xFF64748B),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '10:30 AM',
              style: TextStyle(
                fontSize: R.fs(context, 12),
                color: const Color(0xFF475569),
              ),
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: Color(0xFF64748B),
          ),
        ],
      ),
    );
  }
}

class _FileUploadExample extends StatelessWidget {
  const _FileUploadExample();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF93C5FD)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_upload_outlined,
            size: 23,
            color: AppColors.primary,
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to upload',
            style: TextStyle(
              fontSize: R.fs(context, 11.5),
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'PDF, JPG, PNG',
            style: TextStyle(
              fontSize: R.fs(context, 9.5),
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
