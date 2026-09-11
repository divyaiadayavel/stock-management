import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../providers/settings_provider.dart';

// ─── CONSTANTS ──────────────────────────────────────────────────────────────
const String _statusActive = 'ACTIVE';
const String _statusInactive = 'INACTIVE';

const List<List<Color>> _avatarPalettes = [
  [Color(0xFF1B3A8C), Color(0xFF00C8F8)],
  [Color(0xFFFF6B6B), Color(0xFFFFA53E)],
  [Color(0xFF11998E), Color(0xFF38EF7D)],
  [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
  [Color(0xFFF857A6), Color(0xFFFF5858)],
  [Color(0xFF00B4DB), Color(0xFF0083B0)],
  [Color(0xFFF7971E), Color(0xFFFFD200)],
];

List<Color> _gradientForKey(String key) {
  if (key.trim().isEmpty) return _avatarPalettes.first;
  final index = key.hashCode.abs() % _avatarPalettes.length;
  return _avatarPalettes[index];
}

// ─── SCREEN ──────────────────────────────────────────────────────────────────
class CustomizeScreen extends ConsumerStatefulWidget {
  const CustomizeScreen({super.key});

  @override
  ConsumerState<CustomizeScreen> createState() => _CustomizeScreenState();
}

class _CustomizeScreenState extends ConsumerState<CustomizeScreen> {
  int _selectedTab = 0; // 0 = Categories, 1 = Units

  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _units = [];

  @override
  void initState() {
    super.initState();
    _loadData(showLoading: true);
  }

  // ─── DATA LOADING ──────────────────────────────────────────────────────────
  Future<void> _loadData({bool showLoading = false}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }
    try {
      final repo = ref.read(settingsRepositoryProvider);
      _categories = await repo.getAllCategories();
      _units = await repo.getAllUnits();

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar(e.toString());
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.red : AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }

  // ─── REPOSITORY WRAPPERS ───────────────────────────────────────────────────
  Future<void> _addCategory(Map<String, dynamic> data) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.addCategory(
      categoryName: data['category_name'] as String,
      description: data['description'] as String,
      displayOrder: data['display_order'] as int,
    );
    await _loadData(showLoading: false);
  }

  Future<void> _updateCategory(int id, Map<String, dynamic> data) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.updateCategory(
      id: id,
      categoryName: data['category_name'] as String,
      description: data['description'] as String,
      displayOrder: data['display_order'] as int,
    );
    await _loadData(showLoading: false);
  }

  Future<void> _toggleCategoryStatus(int id, bool enable) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.toggleCategoryStatus(
      id: id,
      status: enable ? _statusActive : _statusInactive,
    );
    await _loadData(showLoading: false);
  }

  Future<void> _deleteCategory(int id) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.deleteCategory(id);
    await _loadData(showLoading: false);
  }

  Future<void> _addUnit(Map<String, dynamic> data) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.addUnit(
      unitName: data['unit_name'] as String,
      shortName: data['short_name'] as String,
      description: data['description'] as String,
    );
    await _loadData(showLoading: false);
  }

  Future<void> _updateUnit(int id, Map<String, dynamic> data) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.updateUnit(
      id: id,
      unitName: data['unit_name'] as String,
      shortName: data['short_name'] as String,
      description: data['description'] as String,
    );
    await _loadData(showLoading: false);
  }

  Future<void> _toggleUnitStatus(int id, bool enable) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.toggleUnitStatus(
      id: id,
      status: enable ? _statusActive : _statusInactive,
    );
    await _loadData(showLoading: false);
  }

  Future<void> _deleteUnit(int id) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.deleteUnit(id);
    await _loadData(showLoading: false);
  }

  // ─── UI HANDLERS ──────────────────────────────────────────────────────────
  Future<void> _handleToggleCategory(int id, bool enable) async {
    try {
      await _toggleCategoryStatus(id, enable);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Could not update category status.');
    }
  }

  Future<void> _handleDeleteCategory(int id) async {
    try {
      await _deleteCategory(id);
      if (!mounted) return;
      _showSnackBar('Category deleted', isError: false);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Could not delete category.');
    }
  }

  Future<void> _handleToggleUnit(int id, bool enable) async {
    try {
      await _toggleUnitStatus(id, enable);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Could not update unit status.');
    }
  }

  Future<void> _handleDeleteUnit(int id) async {
    try {
      await _deleteUnit(id);
      if (!mounted) return;
      _showSnackBar('Unit deleted', isError: false);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Could not delete unit.');
    }
  }

  // ─── UI COMPONENTS ─────────────────────────────────────────────────────────
  Widget _buildGradientButton({
    required String label,
    IconData? icon,
    required VoidCallback? onPressed,
    bool isLoading = false,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    double borderRadius = AppSizes.radiusMd,
  }) {
    final disabled = onPressed == null;
    return Container(
      decoration: BoxDecoration(
        gradient: disabled ? null : AppColors.brandGradient,
        color: disabled ? AppColors.borderStrong.withOpacity(0.4) : null,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: disabled
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF1B3A8C).withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onPressed,
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusToggle({
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!isEnabled),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 44,
        height: 24,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isEnabled ? AppColors.brandGradient : null,
          color: isEnabled ? null : AppColors.borderStrong.withOpacity(0.35),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: isEnabled ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── EDIT/ADD BOTTOM SHEET ─────────────────────────────────────────
  void _showFormSheet({
    required String title,
    required List<Widget> Function(
      void Function(void Function()) setSheetState,
      String? errorText,
      void Function(String?) setError,
    ) fieldsBuilder,
    required String saveLabel,
    required Future<bool> Function() onSave,
    bool isEdit = false,
    VoidCallback? onDelete,
  }) {
    bool isSaving = false;
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setSheetState) {
            Future<void> handleSave() async {
              setSheetState(() => isSaving = true);
              final success = await onSave();
              if (!mounted) return;
              if (success) {
                Navigator.pop(ctx2);
              } else {
                setSheetState(() => isSaving = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx2).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.md,
                      AppSpacing.xl,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag Indicator
                        Center(
                          child: Container(
                            width: 32,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.borderStrong.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Sheet Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              title,
                              style: AppTextStyles.cardValue.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                fontFamily: AppTextStyles.fontDisplay,
                              ),
                            ),
                            InkWell(
                              onTap: isSaving ? null : () => Navigator.pop(ctx2),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.surface2,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        // Fields
                        ...fieldsBuilder(
                          setSheetState,
                          errorText,
                          (val) => setSheetState(() => errorText = val),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        // Action Buttons: Delete & Save
                        Row(
                          children: [
                            if (isEdit && onDelete != null) ...[
                              InkWell(
                                onTap: isSaving
                                    ? null
                                    : () async {
                                        final confirm = await _showDeleteDialog(
                                          _selectedTab == 0 ? 'Category' : 'Unit',
                                        );
                                        if (confirm == true) {
                                          if (!mounted) return;
                                          Navigator.pop(ctx2);
                                          onDelete();
                                        }
                                      },
                                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.red.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                    border: Border.all(
                                      color: AppColors.red.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppColors.red,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Delete',
                                        style: AppTextStyles.button.copyWith(
                                          color: AppColors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                            ],
                            Expanded(
                              child: _buildGradientButton(
                                label: saveLabel,
                                isLoading: isSaving,
                                onPressed: isSaving ? null : handleSave,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCleanTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? errorText,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      autofocus: false,
      onChanged: onChanged,
      style: AppTextStyles.cardValue.copyWith(
        fontFamily: AppTextStyles.fontBody,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        errorText: errorText,
        filled: true,
        fillColor: AppColors.surface2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.red),
        ),
      ),
    );
  }

  // ─── FORM ENTRY POINTS ─────────────────────────────────────────────────────
  void _showCategoryDialog({
    String title = 'Add Category',
    Map<String, dynamic>? initialData,
    int? id,
  }) {
    final nameCtrl = TextEditingController(text: initialData?['category_name'] ?? '');
    final descCtrl = TextEditingController(text: initialData?['description'] ?? '');
    final orderCtrl = TextEditingController(
      text: (initialData?['display_order'] ?? 0).toString(),
    );
    final isEdit = id != null;

    _showFormSheet(
      title: title,
      isEdit: isEdit,
      onDelete: isEdit ? () => _handleDeleteCategory(id) : null,
      saveLabel: isEdit ? 'Save Changes' : 'Create Category',
      fieldsBuilder: (setSheetState, errorText, setError) => [
        _buildCleanTextField(
          controller: nameCtrl,
          label: 'Category Name',
          errorText: errorText,
          onChanged: (_) {
            if (errorText != null) setError(null);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        _buildCleanTextField(
          controller: descCtrl,
          label: 'Description',
        ),
        const SizedBox(height: AppSpacing.md),
        _buildCleanTextField(
          controller: orderCtrl,
          label: 'Display Order',
          keyboardType: TextInputType.number,
        ),
      ],
      onSave: () async {
        final name = nameCtrl.text.trim();
        if (name.isEmpty) {
          _showSnackBar('Category name is required');
          return false;
        }
        try {
          final data = {
            'category_name': name,
            'description': descCtrl.text.trim(),
            'display_order': int.tryParse(orderCtrl.text.trim()) ?? 0,
          };
          if (isEdit) {
            await _updateCategory(id, data);
          } else {
            await _addCategory(data);
          }
          if (!mounted) return false;
          _showSnackBar('Category ${isEdit ? 'updated' : 'added'}', isError: false);
          return true;
        } catch (e) {
          if (!mounted) return false;
          _showSnackBar('Failed to save. Try again.');
          return false;
        }
      },
    );
  }

  void _showUnitDialog({
    String title = 'Add Unit',
    Map<String, dynamic>? initialData,
    int? id,
  }) {
    final nameCtrl = TextEditingController(text: initialData?['unit_name'] ?? '');
    final shortCtrl = TextEditingController(text: initialData?['short_name'] ?? '');
    final descCtrl = TextEditingController(text: initialData?['description'] ?? '');
    final isEdit = id != null;

    _showFormSheet(
      title: title,
      isEdit: isEdit,
      onDelete: isEdit ? () => _handleDeleteUnit(id) : null,
      saveLabel: isEdit ? 'Save Changes' : 'Create Unit',
      fieldsBuilder: (setSheetState, errorText, setError) => [
        _buildCleanTextField(
          controller: nameCtrl,
          label: 'Unit Name',
          errorText: errorText,
          onChanged: (_) {
            if (errorText != null) setError(null);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        _buildCleanTextField(
          controller: shortCtrl,
          label: 'Short Name (e.g. kg, pcs)',
        ),
        const SizedBox(height: AppSpacing.md),
        _buildCleanTextField(
          controller: descCtrl,
          label: 'Description',
        ),
      ],
      onSave: () async {
        final name = nameCtrl.text.trim();
        if (name.isEmpty) {
          _showSnackBar('Unit name is required');
          return false;
        }
        try {
          final data = {
            'unit_name': name,
            'short_name': shortCtrl.text.trim(),
            'description': descCtrl.text.trim(),
          };
          if (isEdit) {
            await _updateUnit(id, data);
          } else {
            await _addUnit(data);
          }
          if (!mounted) return false;
          _showSnackBar('Unit ${isEdit ? 'updated' : 'added'}', isError: false);
          return true;
        } catch (e) {
          if (!mounted) return false;
          _showSnackBar('Failed to save. Try again.');
          return false;
        }
      },
    );
  }

  // ─── DELETE CONFIRMATION DIALOG ──────────────────────────────────────────
  Future<bool?> _showDeleteDialog(String type) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          title: Text(
            'Delete $type?',
            style: AppTextStyles.cardValue.copyWith(
              fontSize: 17,
              fontFamily: AppTextStyles.fontDisplay,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this $type? This action cannot be undone.',
            style: AppTextStyles.cardValue.copyWith(
              fontFamily: AppTextStyles.fontBody,
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ─── LIST CARD ITEM ────────────────────────────────────────────────────────
  Widget _buildItemCard({
    Key? key,
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
    required bool isEnabled,
    required VoidCallback onEdit,
    required ValueChanged<bool> onToggle,
  }) {
    final avatarColors = _gradientForKey(title);

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Avatar with Gradient
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isEnabled
                        ? LinearGradient(
                            colors: avatarColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isEnabled ? null : AppColors.surface2,
                  ),
                  child: Icon(
                    icon,
                    color: isEnabled ? Colors.white : AppColors.textSecondary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Titles
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.cardValue.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surface2,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badge,
                                style: AppTextStyles.small.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Switch Toggle
                _buildStatusToggle(isEnabled: isEnabled, onChanged: onToggle),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── EMPTY STATE ───────────────────────────────────────────────────────────
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onAdd,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.cardValue.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.small.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildGradientButton(
              label: buttonLabel,
              icon: Icons.add,
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB BODY ──────────────────────────────────────────────────────────────
  Widget _buildTabBody({
    required bool isEmpty,
    required int itemCount,
    required Widget emptyState,
    required Widget Function(int index) itemBuilder,
    required Future<void> Function() onRefresh,
  }) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: emptyState,
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                100,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => itemBuilder(index),
                  childCount: itemCount,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return _buildTabBody(
      isEmpty: _categories.isEmpty,
      itemCount: _categories.length,
      onRefresh: () => _loadData(showLoading: false),
      emptyState: _buildEmptyState(
        icon: Icons.category_outlined,
        title: 'No categories yet',
        subtitle: 'Add a category to start organizing your products',
        buttonLabel: 'Add Category',
        onAdd: () => _showCategoryDialog(),
      ),
      itemBuilder: (index) {
        final cat = _categories[index];
        final id = cat['id'] as int;
        final isEnabled =
            (cat['status'] ?? '').toString().toUpperCase() == _statusActive;
        return _buildItemCard(
          key: ValueKey('category_$id'),
          icon: Icons.category_outlined,
          title: (cat['category_name'] ?? '').toString(),
          subtitle: (cat['description'] ?? '').toString(),
          badge: cat['display_order'] != null ? '#${cat['display_order']}' : null,
          isEnabled: isEnabled,
          onEdit: () => _showCategoryDialog(
            title: 'Edit Category',
            initialData: cat,
            id: id,
          ),
          onToggle: (value) => _handleToggleCategory(id, value),
        );
      },
    );
  }

  Widget _buildUnitsTab() {
    return _buildTabBody(
      isEmpty: _units.isEmpty,
      itemCount: _units.length,
      onRefresh: () => _loadData(showLoading: false),
      emptyState: _buildEmptyState(
        icon: Icons.straighten,
        title: 'No units yet',
        subtitle: 'Add a unit to define how products are measured',
        buttonLabel: 'Add Unit',
        onAdd: () => _showUnitDialog(),
      ),
      itemBuilder: (index) {
        final unit = _units[index];
        final id = unit['id'] as int;
        final isEnabled =
            (unit['status'] ?? '').toString().toUpperCase() == _statusActive;
        return _buildItemCard(
          key: ValueKey('unit_$id'),
          icon: Icons.straighten,
          title: (unit['unit_name'] ?? '').toString(),
          subtitle: (unit['short_name'] ?? '').toString(),
          isEnabled: isEnabled,
          onEdit: () => _showUnitDialog(
            title: 'Edit Unit',
            initialData: unit,
            id: id,
          ),
          onToggle: (value) => _handleToggleUnit(id, value),
        );
      },
    );
  }

  // ─── SEGMENTED TAB CONTROL ────────────────────────────────────────────────
  Widget _buildSegmentedTabs() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: _segmentChip(
              label: 'Categories (${_categories.length})',
              selected: _selectedTab == 0,
              onTap: () => setState(() => _selectedTab = 0),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _segmentChip(
              label: 'Units (${_units.length})',
              selected: _selectedTab == 1,
              onTap: () => setState(() => _selectedTab = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? AppColors.brandGradient : null,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd - 2),
        ),
        child: Text(
          label,
          style: AppTextStyles.button.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        titleSpacing: 0,
        title: Text(
          'Customize Products',
          style: AppTextStyles.cardValue.copyWith(
            fontSize: 20,
            fontFamily: AppTextStyles.fontDisplay,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              0,
              AppSpacing.screenPadding,
              AppSpacing.sm,
            ),
            child: _buildSegmentedTabs(),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : IndexedStack(
              index: _selectedTab,
              children: [
                _buildCategoriesTab(),
                _buildUnitsTab(),
              ],
            ),
      floatingActionButton: _isLoading
          ? null
          : _buildGradientButton(
              label: _selectedTab == 0 ? 'Add Category' : 'Add Unit',
              icon: Icons.add,
              onPressed: () => _selectedTab == 0
                  ? _showCategoryDialog()
                  : _showUnitDialog(),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              borderRadius: 28,
            ),
    );
  }
}
