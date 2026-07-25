import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../domain/entities/staff_user.dart';
import '../../providers/settings_provider.dart';

class AddRoleScreen extends ConsumerStatefulWidget {
  const AddRoleScreen({super.key, this.staffUser});

  final StaffUser? staffUser;

  @override
  ConsumerState<AddRoleScreen> createState() => _AddRoleScreenState();
}

class _AddRoleScreenState extends ConsumerState<AddRoleScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _passwordCtrl;

  static const List<String> _baseRoles = [
    'Admin',
    'Manager',
    'Cashier',
    'Salesperson',
    'Inventory Staff',
  ];

  late String _selectedRole;
  late bool _isActive;
  bool _isSaving = false;

  bool get _isEditing => widget.staffUser != null;

  List<String> get _roleOptions {
    if (_baseRoles.contains(_selectedRole)) return _baseRoles;
    return [..._baseRoles, _selectedRole];
  }

  @override
  void initState() {
    super.initState();
    final staff = widget.staffUser;
    _nameCtrl = TextEditingController(text: staff?.name ?? '');
    _emailCtrl = TextEditingController(text: staff?.email ?? '');
    _phoneCtrl = TextEditingController(text: staff?.phone ?? '');
    _passwordCtrl = TextEditingController();
    _selectedRole = (staff?.role.trim().isNotEmpty ?? false)
        ? staff!.role
        : 'Cashier';
    _isActive = staff?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveStaffUser() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final staff = StaffUser(
      id: widget.staffUser?.id,
      name: _nameCtrl.text.trim(),
      role: _selectedRole,
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      isActive: _isActive,
    );

    try {
      // ← staffControllerProvider, not settingsControllerProvider
      final controller = ref.read(staffControllerProvider.notifier);
      final success = _isEditing
          ? await controller.updateStaffUser(staff)
          : await controller.addStaffUser(staff);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Staff updated' : 'Staff added'),
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showError('Unable to save staff user');
      }
    } catch (e) {
      if (!mounted) return;
      _showError(_cleanError(e));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.red),
    );
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

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
          _isEditing ? 'Edit Staff User' : 'Add Staff User',
          style: AppTextStyles.cardValue.copyWith(
            fontSize: 22,
            fontFamily: AppTextStyles.fontDisplay,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
            onPressed: _isSaving ? null : _saveStaffUser,
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.textWhite,
                    ),
                  )
                : Text(
                    _isEditing ? 'Save Changes' : 'Add Staff User',
                    style: AppTextStyles.button.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textWhite,
                    ),
                  ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Staff Details'),
              _panel(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.next,
                    style: AppTextStyles.cardValue.copyWith(fontFamily: AppTextStyles.fontBody, fontSize: 15),
                    decoration: _fieldDecoration(
                      label: 'Full Name',
                      icon: Icons.person_outline,
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) return 'Name is required';
                      if (value!.trim().length < 2) return 'Enter a valid name';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: AppTextStyles.cardValue.copyWith(fontFamily: AppTextStyles.fontBody, fontSize: 15),
                    decoration: _fieldDecoration(
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                    ),
                    validator: (value) {
                      final email = (value ?? '').trim();
                      if (email.isEmpty) return 'Email is required';
                      final valid =
                          RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
                      return valid ? null : 'Enter a valid email';
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    style: AppTextStyles.cardValue.copyWith(fontFamily: AppTextStyles.fontBody, fontSize: 15),
                    decoration: _fieldDecoration(
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                    ),
                    validator: (value) {
                      final digits =
                          (value ?? '').replaceAll(RegExp(r'\D'), '');
                      if (digits.isEmpty) return 'Phone number is required';
                      if (digits.length < 10 || digits.length > 15) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _sectionTitle('Access'),
              _panel(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    style: AppTextStyles.cardValue.copyWith(fontFamily: AppTextStyles.fontBody, fontSize: 15),
                    decoration: _fieldDecoration(
                      label: 'Assign Role',
                      icon: Icons.badge_outlined,
                    ),
                    items: _roleOptions
                        .map((role) =>
                            DropdownMenuItem(value: role, child: Text(role)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedRole = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      _roleDescription(_selectedRole),
                      style: AppTextStyles.small.copyWith(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    style: AppTextStyles.cardValue.copyWith(fontFamily: AppTextStyles.fontBody, fontSize: 15),
                    decoration: _fieldDecoration(
                      label: _isEditing ? 'New Password' : 'Password',
                      icon: Icons.lock_outline,
                      helperText: _isEditing
                          ? 'Leave empty to keep current password'
                          : null,
                    ),
                    validator: (value) {
                      final password = value ?? '';
                      if (!_isEditing && password.isEmpty) {
                        return 'Password is required';
                      }
                      if (password.isNotEmpty && password.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile.adaptive(
                    value: _isActive,
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.textWhite,
                    activeTrackColor: AppColors.primary,
                    inactiveThumbColor: AppColors.textWhite,
                    inactiveTrackColor: AppColors.borderStrong,
                    title: Text(
                      'Active Account',
                      style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    subtitle: Text(
                      _isActive
                          ? 'User can sign in and use assigned access'
                          : 'User is blocked from staff access',
                      style: AppTextStyles.small,
                    ),
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTextStyles.cardValue.copyWith(
          fontSize: 17,
          fontFamily: AppTextStyles.fontDisplay,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
        ),
      ),
    );
  }

  Widget _panel({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surface2,
      labelStyle: AppTextStyles.small.copyWith(fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.red, width: 1.0),
      ),
    );
  }

  String _roleDescription(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Full control over settings, reports, stock, and billing.';
      case 'manager':
        return 'Can manage stock, sales, customers, and daily reports.';
      case 'cashier':
        return 'Focused access for billing and payment collection.';
      case 'salesperson':
        return 'Can create sales and work with customer records.';
      case 'inventory staff':
        return 'Can receive stock, adjust quantities, and scan products.';
      default:
        return 'Custom staff role.';
    }
  }
}