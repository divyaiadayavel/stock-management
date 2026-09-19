// lib/features/settings/service_management/presentation/screens/add_provider_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../../../core/utils/validators.dart';
import '../../data/models/provider_question_model.dart';
import '../../data/models/service_provider_model.dart';
import '../../domain/enums/provider_field_type.dart';
import '../providers/service_management_provider.dart';
import '../providers/service_provider_provider.dart';
import '../widgets/provider_question_editor_card.dart';
import '../widgets/provider_question_type_sheet.dart';
import 'provider_preview_screen.dart';

/// SCREEN 2 — "Add / Edit provider"
///
/// One screen, matching the services builder: provider details
/// (name · category · description · load amount) AND the recharge
/// questions, with "Preview" up top and "Save/Update" at the bottom.
/// No separate wizard step in between — Preview is read-only,
/// Save is what actually persists the provider.
class AddProviderScreen extends ConsumerStatefulWidget {
  final int? presetCategoryId;
  final String? presetCategoryName;

  /// When set, the screen edits an existing provider instead of creating one.
  final int? existingProviderId;

  const AddProviderScreen({
    super.key,
    this.presetCategoryId,
    this.presetCategoryName,
    this.existingProviderId,
  });

  @override
  ConsumerState<AddProviderScreen> createState() => _AddProviderScreenState();
}

class _AddProviderScreenState extends ConsumerState<AddProviderScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _loadController = TextEditingController();

  int? _categoryId;
  String? _categoryName;

  List<ProviderQuestionModel> _questions = [];
  String? _newlyAddedLocalId;

  bool _hydrated = false;

  @override
  void initState() {
    super.initState();

    _categoryId = widget.presetCategoryId;
    _categoryName = widget.presetCategoryName;

    // A brand-new provider starts from the same default question set
    // the old wizard used to seed on its second step.
    if (widget.existingProviderId == null) {
      _questions = ProviderQuestionModel.defaults();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _loadController.dispose();
    super.dispose();
  }

  void _hydrate(ServiceProviderModel provider) {
    if (_hydrated) return;

    _hydrated = true;

    _nameController.text = provider.name;
    _descriptionController.text = provider.description;
    _loadController.text = provider.balance.toStringAsFixed(0);

    _categoryId = provider.categoryId;
    _categoryName = provider.categoryName;

    _questions = provider.questionModels.isNotEmpty
        ? List.of(provider.questionModels)
        : ProviderQuestionModel.defaults();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade700,
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ADD / DELETE QUESTION
  // ─────────────────────────────────────────────
  Future<void> _addQuestion() async {
    final type = await showProviderFieldTypePicker(context);

    if (type == null) return;

    final localId = 'new_${DateTime.now().microsecondsSinceEpoch}';

    setState(() {
      _newlyAddedLocalId = localId;

      _questions.add(
        ProviderQuestionModel(
          localId: localId,
          label: '',
          type: type,
          required: true,
          options: type.hasOptions ? const ['Option 1'] : const [],
          order: _questions.length,
        ),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _newlyAddedLocalId = null);
      }
    });
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
      setState(() => _questions.removeAt(index));
    }
  }

  // ─────────────────────────────────────────────
  // VALIDATION
  //
  // All field rules live in Validators so every screen in the
  // service-management area rejects the same input the same way.
  // ─────────────────────────────────────────────
  bool _validateQuestions() {
    for (final q in _questions) {
      final labelError = Validators.validateQuestionLabel(q.label);

      if (labelError != null) {
        _snack(labelError.replaceFirst('Question label', 'A question label'));
        return false;
      }

      if (q.type.hasOptions) {
        final optionsError = Validators.validateChoiceOptions(q.options);

        if (optionsError != null) {
          _snack('"${q.label.trim()}": $optionsError');
          return false;
        }
      }
    }

    final hasAmount = _questions.any(
      (q) => q.type == ProviderFieldType.amount,
    );

    if (!hasAmount) {
      _snack(
        'Add one Amount question — it is what gets deducted from the balance.',
      );
      return false;
    }

    return true;
  }

  List<ProviderQuestionModel> _cleanedQuestions() {
    return _questions.asMap().entries.map((e) {
      return e.value.copyWith(
        label: Validators.normalizeText(e.value.label),
        options: e.value.options
            .map(Validators.normalizeText)
            .where((o) => o.isNotEmpty)
            .toList(),
        order: e.key,
      );
    }).toList();
  }

  /// Validates everything and returns the draft, or null (after
  /// showing the relevant error) if something needs fixing first.
  ServiceProviderModel? _buildValidDraft(ServiceProviderModel? existing) {
    final nameError = Validators.validateProviderName(_nameController.text);

    if (nameError != null) {
      _snack(nameError);
      return null;
    }

    final name = Validators.normalizeText(_nameController.text);

    if (_categoryId == null) {
      _snack('Select a category.');
      return null;
    }

    final descriptionError = Validators.validateDescription(
      _descriptionController.text,
    );

    if (descriptionError != null) {
      _snack(descriptionError);
      return null;
    }

    double? load;

    if (existing == null) {
      final loadError = Validators.validateLoadAmount(
        _loadController.text,
        fieldName: 'Initial load amount',
      );

      if (loadError != null) {
        _snack(loadError);
        return null;
      }

      load = double.parse(_loadController.text.trim());
    }

    if (!_validateQuestions()) {
      return null;
    }

    return ServiceProviderModel(
      id: existing?.id,
      categoryId: _categoryId,
      categoryName: _categoryName ?? '',
      name: name,
      description: _descriptionController.text.trim(),
      // On edit the live balance is preserved; on create this is the
      // opening load amount.
      balance: existing?.balance ?? (load ?? 0),
      lowBalanceThreshold: existing?.lowBalanceThreshold ?? 500,
      questions: _cleanedQuestions(),
      status: existing?.status ?? 'ACTIVE',
    );
  }

  Future<void> _openPreview(ServiceProviderModel? existing) async {
    final draft = _buildValidDraft(existing);

    if (draft == null) return;

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderPreviewScreen(
          provider: draft,
          isEditing: existing != null,
        ),
      ),
    );
  }

  bool _saving = false;

  Future<void> _save(ServiceProviderModel? existing) async {
    if (_saving) return;

    final draft = _buildValidDraft(existing);

    if (draft == null) return;

    setState(() => _saving = true);

    final notifier = ref.read(providerOperationsProvider.notifier);

    final saved = existing != null
        ? await notifier.saveExistingProvider(draft)
        : await notifier.saveNewProvider(draft);

    if (!mounted) return;

    setState(() => _saving = false);

    if (saved == null) {
      final error = ref.read(providerOperationsProvider).error;

      _snack(
        error != null
            ? 'Could not save provider: $error'
            : 'Could not save provider.',
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF16A34A),
        content: Text(
          '${saved.name} saved.',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );

    Navigator.pop(context, saved);
  }

  // ─────────────────────────────────────────────
  // FIELD DECORATION
  // ─────────────────────────────────────────────
  InputDecoration _decoration(
    String hint, {
    String? prefixText,
    String? errorText,
  }) {
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
      errorText: errorText,
      errorStyle: TextStyle(fontSize: R.fs(context, 11.5)),
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
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: R.sp(context, 6)),
      child: Text(
        text,
        style: TextStyle(
          fontSize: R.fs(context, 13),
          fontWeight: FontWeight.w600,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = R.hPad(context, base: 20);

    // Only PROVIDER-type categories can hold a provider.
    final categoriesAsync = ref.watch(providerTypeCategoriesProvider);

    ServiceProviderModel? existing;

    if (widget.existingProviderId != null) {
      final detail = ref.watch(
        providerDetailProvider(widget.existingProviderId!),
      );

      if (detail.isLoading) {
        return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            ),
          ),
        );
      }

      existing = detail.asData?.value;

      if (existing != null) {
        _hydrate(existing);
      }
    }

    final isEditing = existing != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                      isEditing ? 'Edit provider' : 'Add provider',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        fontSize: R.fs(context, 20),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openPreview(existing),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: R.sp(context, 12),
                        vertical: R.sp(context, 7),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(R.radius(context, 20)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.visibility_outlined,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Preview',
                            style: TextStyle(
                              fontSize: R.fs(context, 12.5),
                              fontWeight: FontWeight.w700,
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

            // ─── Form ───
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  hPad.left,
                  R.sp(context, 4),
                  hPad.left,
                  R.sp(context, 20),
                ),
                children: [
                  Text(
                    'Provider details',
                    style: TextStyle(
                      fontSize: R.fs(context, 15),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),

                  SizedBox(height: R.sp(context, 14)),

                  _label('Provider name'),
                  TextFormField(
                    controller: _nameController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    style: TextStyle(
                      fontSize: R.fs(context, 14),
                      color: const Color(0xFF0F172A),
                    ),
                    decoration: _decoration('e.g. Jio recharge'),
                    validator: (v) => Validators.validateProviderName(v ?? ''),
                    onChanged: (_) => setState(() {}),
                  ),

                  SizedBox(height: R.sp(context, 16)),

                  _label('Category'),
                  categoriesAsync.when(
                    loading: () => Container(
                      height: R.sp(context, 50),
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(
                        horizontal: R.sp(context, 14),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(R.radius(context, 10)),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        'Loading categories…',
                        style: TextStyle(
                          fontSize: R.fs(context, 14),
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    error: (e, _) => Text(
                      'Failed to load categories: $e',
                      style: TextStyle(
                        fontSize: R.fs(context, 13),
                        color: Colors.red.shade700,
                      ),
                    ),
                    data: (categories) {
                      final ids = categories.map((c) => c.id).toSet();

                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: R.sp(context, 14),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(R.radius(context, 10)),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: ids.contains(_categoryId)
                                ? _categoryId
                                : null,
                            hint: Text(
                              'Select category',
                              style: TextStyle(
                                fontSize: R.fs(context, 14),
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF64748B),
                            ),
                            items: categories.map((c) {
                              return DropdownMenuItem<int>(
                                value: c.id,
                                child: Text(
                                  c.name,
                                  style: TextStyle(
                                    fontSize: R.fs(context, 14),
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value == null) return;

                              setState(() {
                                _categoryId = value;
                                _categoryName = categories
                                    .firstWhere((c) => c.id == value)
                                    .name;
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: R.sp(context, 16)),

                  _label('Description'),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    style: TextStyle(
                      fontSize: R.fs(context, 14),
                      color: const Color(0xFF0F172A),
                    ),
                    decoration: _decoration('Prepaid & postpaid top-ups'),
                    validator: (v) => Validators.validateDescription(v ?? ''),
                  ),

                  SizedBox(height: R.sp(context, 16)),

                  _label(
                    existing == null
                        ? 'Initial load amount'
                        : 'Current balance (read only)',
                  ),
                  TextFormField(
                    controller: _loadController,
                    enabled: existing == null,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    style: TextStyle(
                      fontSize: R.fs(context, 15),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                    decoration: _decoration('5,000', prefixText: '₹ '),
                    validator: existing == null
                        ? (v) => Validators.validateLoadAmount(
                              v ?? '',
                              fieldName: 'Initial load amount',
                            )
                        : null,
                  ),

                  if (existing != null) ...[
                    SizedBox(height: R.sp(context, 8)),
                    Text(
                      'Balance changes only through recharges and reloads.',
                      style: TextStyle(
                        fontSize: R.fs(context, 12),
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],

                  SizedBox(height: R.sp(context, 22)),

                  Text(
                    'Recharge questions',
                    style: TextStyle(
                      fontSize: R.fs(context, 15),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),

                  SizedBox(height: R.sp(context, 12)),

                  ..._questions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final question = entry.value;

                    return ProviderQuestionEditorCard(
                      key: ValueKey(question.localId),
                      question: question,
                      autoFocus: question.localId == _newlyAddedLocalId,
                      onChanged: (updated) {
                        // Fixed: this used to update the list without
                        // triggering a rebuild, so the Required
                        // switch (and any other edit) never actually
                        // stuck once you left the card.
                        setState(() {
                          _questions[index] = updated;
                        });
                      },
                      onDelete: () => _confirmDeleteQuestion(index),
                    );
                  }),

                  SizedBox(height: R.sp(context, 4)),

                  GestureDetector(
                    onTap: _addQuestion,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: R.sp(context, 14),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius:
                            BorderRadius.circular(R.radius(context, 12)),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Add question',
                            style: TextStyle(
                              fontSize: R.fs(context, 14),
                              fontWeight: FontWeight.w700,
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

            // ─── Save / Update ───
            Padding(
              padding: EdgeInsets.fromLTRB(
                hPad.left,
                R.sp(context, 8),
                hPad.left,
                R.sp(context, 16),
              ),
              child: GestureDetector(
                onTap: _saving ? null : () => _save(existing),
                child: Container(
                  width: double.infinity,
                  height: R.sp(context, 52),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(R.radius(context, 12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : Text(
                          isEditing ? 'Update provider' : 'Save provider',
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
}
