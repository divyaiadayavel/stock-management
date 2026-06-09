import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_colors.dart';
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
    _nameCtrl     = TextEditingController(text: staff?.name  ?? '');
    _emailCtrl    = TextEditingController(text: staff?.email ?? '');
    _phoneCtrl    = TextEditingController(text: staff?.phone ?? '');
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
      id:       widget.staffUser?.id,
      name:     _nameCtrl.text.trim(),
      role:     _selectedRole,
      email:    _emailCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
      phone:    _phoneCtrl.text.trim(),
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _isEditing ? 'Edit Staff User' : 'Add Staff User',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isSaving ? null : _saveStaffUser,
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isEditing ? 'Save Changes' : 'Add Staff User',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
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
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
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
              const SizedBox(height: 20),
              _sectionTitle('Access'),
              _panel(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
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
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      _roleDescription(_selectedRole),
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
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
                  const SizedBox(height: 10),
                  SwitchListTile.adaptive(
                    value: _isActive,
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.primary,
                    title: const Text(
                      'Active Account',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      _isActive
                          ? 'User can sign in and use assigned access'
                          : 'User is blocked from staff access',
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
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _panel({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
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
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
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