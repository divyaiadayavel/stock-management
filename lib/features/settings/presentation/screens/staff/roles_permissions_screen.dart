
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../auth/presentation/controllers/access_policy.dart';
import '../../../domain/entities/staff_user.dart';
import '../../providers/settings_provider.dart';
// import '../providers/staff_provider.dart';
import 'staff_user_form_screen.dart';

enum _StaffStatusFilter { all, active, inactive }

class UserRolesScreen extends ConsumerStatefulWidget {
  const UserRolesScreen({super.key});

  @override
  ConsumerState<UserRolesScreen> createState() => _UserRolesScreenState();
}

class _UserRolesScreenState extends ConsumerState<UserRolesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  String _selectedRole = 'All';
  _StaffStatusFilter _statusFilter = _StaffStatusFilter.all;

  static const List<String> _baseRoles = [
    'Admin',
    'Manager',
    'Cashier',
    'Salesperson',
    'Inventory Staff',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() {
    return ref.read(staffControllerProvider.notifier).reload();
  }

  Future<void> _openStaffForm([StaffUser? staff]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddRoleScreen(staffUser: staff)),
    );
  }

  Future<void> _toggleStaffStatus(
    StaffUser staff,
    bool isActive,
    List<StaffUser> allStaff,
  ) async {
    if (staff.id == null) {
      _showMessage('Unable to update this staff user', isError: true);
      return;
    }

    if (!isActive && _isLastActiveAdmin(staff, allStaff)) {
      _showMessage('Keep at least one active admin user', isError: true);
      return;
    }

    try {
      await ref
          .read(staffControllerProvider.notifier)
          .setStaffUserStatus(staff.id!, isActive);
      if (!mounted) return;
      _showMessage(isActive ? 'Staff activated' : 'Staff deactivated');
    } catch (e) {
      if (!mounted) return;
      _showMessage(_cleanError(e), isError: true);
    }
  }

  Future<void> _confirmDelete(StaffUser staff, List<StaffUser> allStaff) async {
    if (staff.id == null) {
      _showMessage('Unable to delete this staff user', isError: true);
      return;
    }

    if (_isLastActiveAdmin(staff, allStaff)) {
      _showMessage('Keep at least one active admin user', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Staff User',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text('Remove ${staff.name} from staff access?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(staffControllerProvider.notifier)
          .deleteStaffUser(staff.id!);
      if (!mounted) return;
      _showMessage('Staff deleted');
    } catch (e) {
      if (!mounted) return;
      _showMessage(_cleanError(e), isError: true);
    }
  }

  bool _isLastActiveAdmin(StaffUser staff, List<StaffUser> allStaff) {
    if (!_isAdmin(staff) || !staff.isActive) return false;

    return allStaff
        .where((item) => item.id != staff.id && item.isActive && _isAdmin(item))
        .isEmpty;
  }

  bool _isAdmin(StaffUser staff) {
    return staff.role.trim().toLowerCase() == 'admin';
  }

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() {
      _selectedRole = 'All';
      _statusFilter = _StaffStatusFilter.all;
    });
  }

  bool get _hasActiveFilter {
    return _searchCtrl.text.trim().isNotEmpty ||
        _selectedRole != 'All' ||
        _statusFilter != _StaffStatusFilter.all;
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: isError ? AppColors.red : Colors.grey.shade900,
      ),
    );
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final staffState = ref.watch(staffControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: staffState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: const Text('Staff Access'),
          ),
          body: _ErrorState(message: _cleanError(error), onRetry: _reload),
        ),
        data: (staff) {
          final filteredStaff = _filteredStaff(staff);
          final roles = _availableRoles(staff);

          return Stack(
            children: [
              // Styled Modern Header Background
              Container(
                height: 220,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFF1E40AF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
              ),
              SafeArea(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  color: AppColors.primary,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Modern Custom Header / App Bar
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                                    onPressed: () => Navigator.maybePop(context),
                                  ),
                                  const Text(
                                    'Staff Access',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 22,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _OverviewPanel(
                                total: staff.length,
                                active: staff.where((item) => item.isActive).length,
                                inactive: staff.where((item) => !item.isActive).length,
                                admins: staff.where(_isAdmin).length,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Persistent Modern Sticky Filter/Search Bar Panel
                      SliverAppBar(
                        pinned: true,
                        backgroundColor: const Color(0xFFF8F9FA),
                        automaticallyImplyLeading: false,
                        elevation: 0,
                        collapsedHeight: 124,
                        expandedHeight: 124,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Container(
                            color: const Color(0xFFF8F9FA),
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Column(
                              children: [
                                _buildSearchField(),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 38,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    children: [
                                      _buildStatusFilters(),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        child: VerticalDivider(width: 1, color: Colors.grey.shade300, indent: 6, endIndent: 6),
                                      ),
                                      _buildRoleHorizontalChips(roles),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Staff User List content
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildSectionHeader(filteredStaff.length),
                            const SizedBox(height: 8),
                            if (filteredStaff.isEmpty)
                              _EmptyState(hasStaff: staff.isNotEmpty)
                            else
                              ...filteredStaff.map(
                                (item) => _StaffUserCard(
                                  staff: item,
                                  roleColor: _roleColor(item.role),
                                  roleDescription: _roleDescription(item.role),
                                  initials: _initials(item.name),
                                  onEdit: () => _openStaffForm(item),
                                  onStatusChanged: (value) =>
                                      _toggleStaffStatus(item, value, staff),
                                  onDelete: () => _confirmDelete(item, staff),
                                ),
                              ),
                            const SizedBox(height: 16),
                            _RoleGuide(
                              roles: roles.where((role) => role != 'All').toList(),
                              roleColor: _roleColor,
                              roleIcon: _roleIcon,
                              roleDescription: _roleDescription,
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Floating Action Button Styled Layer
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFFF8F9FA).withOpacity(0.0), const Color(0xFFF8F9FA)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: AppColors.primary.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => _openStaffForm(),
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                        label: const Text(
                          'Add Staff User',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search name, phone or email...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
          suffixIcon: _searchCtrl.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.cancel_rounded, color: Colors.grey, size: 20),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {});
                  },
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilters() {
    return Row(
      children: [
        _statusChip('All', _StaffStatusFilter.all, Icons.done_all_rounded),
        const SizedBox(width: 8),
        _statusChip('Active', _StaffStatusFilter.active, Icons.check_circle_rounded),
        const SizedBox(width: 8),
        _statusChip('Inactive', _StaffStatusFilter.inactive, Icons.remove_circle_rounded),
      ],
    );
  }

  Widget _statusChip(String label, _StaffStatusFilter filter, IconData icon) {
    final selected = _statusFilter == filter;
    final color = selected ? AppColors.primary : Colors.grey.shade700;

    return ChoiceChip(
      avatar: Icon(icon, size: 14, color: color),
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary.withOpacity(0.12),
      side: BorderSide(
        color: selected ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
      ),
      elevation: selected ? 0 : 1,
      pressElevation: 0,
      shadowColor: Colors.black.withOpacity(0.1),
      labelStyle: TextStyle(color: color, fontWeight: selected ? FontWeight.bold : FontWeight.normal, fontSize: 13),
      onSelected: (_) => setState(() => _statusFilter = filter),
    );
  }

  Widget _buildRoleHorizontalChips(List<String> roles) {
    return Row(
      children: roles.map((role) {
        final selected = _selectedRole == role;
        final color = selected ? AppColors.primary : Colors.grey.shade700;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(role),
            selected: selected,
            showCheckmark: false,
            backgroundColor: Colors.white,
            selectedColor: AppColors.primary.withOpacity(0.12),
            side: BorderSide(
              color: selected ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
            ),
            elevation: selected ? 0 : 1,
            pressElevation: 0,
            shadowColor: Colors.black.withOpacity(0.1),
            labelStyle: TextStyle(color: color, fontWeight: selected ? FontWeight.bold : FontWeight.normal, fontSize: 13),
            onSelected: (_) => setState(() => _selectedRole = role),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(int count) {
    return Row(
      children: [
        Text(
          '$count Staff User${count == 1 ? '' : 's'}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        if (_hasActiveFilter)
          TextButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: const Text('Reset Filters', style: TextStyle(fontSize: 13)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
      ],
    );
  }

  List<StaffUser> _filteredStaff(List<StaffUser> staff) {
    final query = _searchCtrl.text.trim().toLowerCase();

    return staff.where((item) {
      final matchesRole = _selectedRole == 'All' || item.role == _selectedRole;
      final matchesStatus = switch (_statusFilter) {
        _StaffStatusFilter.all => true,
        _StaffStatusFilter.active => item.isActive,
        _StaffStatusFilter.inactive => !item.isActive,
      };
      final matchesQuery =
          query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.email.toLowerCase().contains(query) ||
          item.phone.toLowerCase().contains(query) ||
          item.role.toLowerCase().contains(query);

      return matchesRole && matchesStatus && matchesQuery;
    }).toList()..sort((a, b) {
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  List<String> _availableRoles(List<StaffUser> staff) {
    final roles = <String>{'All', ..._baseRoles};
    for (final item in staff) {
      final role = item.role.trim();
      if (role.isNotEmpty) roles.add(role);
    }
    return roles.toList();
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'ST';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppColors.primary;
      case 'manager':
        return AppColors.orange;
      case 'cashier':
        return AppColors.green;
      case 'salesperson':
        return Colors.deepPurple;
      case 'inventory staff':
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _roleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      case 'manager':
        return Icons.manage_accounts_outlined;
      case 'cashier':
        return Icons.point_of_sale_outlined;
      case 'salesperson':
        return Icons.person_search_outlined;
      case 'inventory staff':
        return Icons.inventory_2_outlined;
      default:
        return Icons.badge_outlined;
    }
  }

  String _roleDescription(String role) {
    final accessSummary = RoleAccessPolicy.accessSummary(role);

    switch (role.toLowerCase()) {
      case 'admin':
        return 'Full control over settings, stock, sales, reports, and staff. $accessSummary';
      case 'manager':
        return 'Manages operations, stock, customers, and reports. $accessSummary';
      case 'cashier':
        return 'Handles billing, invoices, and payment collection. $accessSummary';
      case 'salesperson':
        return 'Creates sales and manages customer interactions. $accessSummary';
      case 'inventory staff':
        return 'Receives stock, adjusts quantities, and scans products. $accessSummary';
      default:
        return 'Custom staff access. $accessSummary';
    }
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({
    required this.total,
    required this.active,
    required this.inactive,
    required this.admins,
  });

  final int total;
  final int active;
  final int inactive;
  final int admins;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.groups_2_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Team Access Overview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$active active of $total staff accounts',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'Active',
                  value: active.toString(),
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniMetric(
                  label: 'Inactive',
                  value: inactive.toString(),
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniMetric(
                  label: 'Admins',
                  value: admins.toString(),
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffUserCard extends StatelessWidget {
  const _StaffUserCard({
    required this.staff,
    required this.roleColor,
    required this.roleDescription,
    required this.initials,
    required this.onEdit,
    required this.onStatusChanged,
    required this.onDelete,
  });

  final StaffUser staff;
  final Color roleColor;
  final String roleDescription;
  final String initials;
  final VoidCallback onEdit;
  final ValueChanged<bool> onStatusChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: roleColor.withOpacity(0.1),
            child: Text(
              initials,
              style: TextStyle(
                color: roleColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  staff.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _StatusMiniIndicator(isActive: staff.isActive),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              staff.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
          children: [
            Divider(color: Colors.grey.shade100, height: 1),
            const SizedBox(height: 12),
            if (staff.phone.trim().isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.phone_iphone_rounded, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Text(
                    staff.phone,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                _RolePill(role: staff.role, color: roleColor),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      staff.isActive ? 'Active Status' : 'Inactive Status',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      height: 28,
                      width: 44,
                      child: Transform.scale(
                        scale: 0.75,
                        child: Switch.adaptive(
                          value: staff.isActive,
                          activeColor: AppColors.primary,
                          onChanged: onStatusChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                roleDescription,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.3),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
 Expanded(
  child: OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(color: Colors.grey.shade200),
      backgroundColor: Colors.white,
      foregroundColor: Colors.grey.shade700,
    ),
    onPressed: onEdit,
    icon: const Icon(Icons.edit_outlined, size: 16),
    label: const Text('Edit Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
  ),
),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: AppColors.red.withOpacity(0.04),
                      foregroundColor: AppColors.red,
                      side: BorderSide(color: AppColors.red.withOpacity(0.15)),
                    ),
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Delete', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusMiniIndicator extends StatelessWidget {
  const _StatusMiniIndicator({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: isActive ? AppColors.green : Colors.grey.shade400,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.role, required this.color});

  final String role;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            role,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleGuide extends StatelessWidget {
  const _RoleGuide({
    required this.roles,
    required this.roleColor,
    required this.roleIcon,
    required this.roleDescription,
  });

  final List<String> roles;
  final Color Function(String role) roleColor;
  final IconData Function(String role) roleIcon;
  final String Function(String role) roleDescription;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.gavel_rounded,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          title: const Text(
            'Permissions Guide',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Text(
            RoleAccessPolicy.allowAllRolesTemporarily
                ? 'Temporary unlimited access enabled'
                : 'View system rules by roles',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          children: roles
              .map(
                (role) => _RoleGuideRow(
                  role: role,
                  color: roleColor(role),
                  icon: roleIcon(role),
                  description: roleDescription(role),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _RoleGuideRow extends StatelessWidget {
  const _RoleGuideRow({
    required this.role,
    required this.color,
    required this.icon,
    required this.description,
  });

  final String role;
  final Color color;
  final IconData icon;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasStaff});

  final bool hasStaff;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(
            hasStaff ? Icons.manage_search_rounded : Icons.person_add_disabled_rounded,
            color: Colors.grey.shade300,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            hasStaff ? 'No Matches Found' : 'No Staff Members Registered',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 4),
          Text(
            hasStaff
                ? 'Try matching a different keyword, status configuration, or filter parameter.'
                : 'Register system users to control store level privileges and track assignments.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.red, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Failed to retrieve staff records',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Try Again', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

