import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../auth/presentation/controllers/access_policy.dart';
import '../../../domain/entities/staff_user.dart';
import '../../providers/settings_provider.dart';
import 'staff_user_form_screen.dart';

enum StaffStatusFilter { all, active, inactive }

class UserRolesScreen extends ConsumerStatefulWidget {
  const UserRolesScreen({super.key});

  @override
  ConsumerState<UserRolesScreen> createState() => _UserRolesScreenState();
}

class _UserRolesScreenState extends ConsumerState<UserRolesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  String _selectedRole = 'All';
  StaffStatusFilter _statusFilter = StaffStatusFilter.all;

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
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          title: Text(
            'Delete Staff User',
            style: AppTextStyles.cardValue.copyWith(
              fontSize: 18,
              fontFamily: AppTextStyles.fontDisplay,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Remove ${staff.name} from staff access?',
            style: AppTextStyles.small.copyWith(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: AppTextStyles.button.copyWith(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: AppColors.textWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
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
      _statusFilter = StaffStatusFilter.all;
    });
  }

  bool get _hasActiveFilter {
    return _searchCtrl.text.trim().isNotEmpty ||
        _selectedRole != 'All' ||
        _statusFilter != StaffStatusFilter.all;
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
        backgroundColor: isError ? AppColors.red : AppColors.textPrimaryDark,
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
      backgroundColor: AppColors.background,
      body: staffState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(message: _cleanError(error), onRetry: _reload),
        data: (staff) {
          final filteredStaff = _filteredStaff(staff);
          final roles = _availableRoles(staff);

          return SafeArea(
            child: RefreshIndicator(
              onRefresh: _reload,
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm, AppSpacing.screenPadding, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                alignment: Alignment.centerLeft,
                                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimaryDark, size: 24),
                                onPressed: () => Navigator.maybePop(context),
                              ),
                              Text(
                                'Staff Access',
                                style: AppTextStyles.cardValue.copyWith(
                                  fontSize: 22,
                                  fontFamily: AppTextStyles.fontDisplay,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimaryDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
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

                  // Filters & Search
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyFilterDelegate(
                      child: Container(
                        color: AppColors.background,
                        padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.md, AppSpacing.screenPadding, AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildSearchField(),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDropdownFilter<StaffStatusFilter>(
                                    value: _statusFilter,
                                    items: [
                                      const DropdownMenuItem(value: StaffStatusFilter.all, child: Text('All Status')),
                                      const DropdownMenuItem(value: StaffStatusFilter.active, child: Text('Active Only')),
                                      const DropdownMenuItem(value: StaffStatusFilter.inactive, child: Text('Inactive Only')),
                                    ],
                                    onChanged: (val) => setState(() => _statusFilter = val!),
                                    icon: Icons.filter_list_rounded,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: _buildDropdownFilter<String>(
                                    value: _selectedRole,
                                    items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r == 'All' ? 'All Roles' : r))).toList(),
                                    onChanged: (val) => setState(() => _selectedRole = val!),
                                    icon: Icons.badge_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      minHeight: 124.0,
                      maxHeight: 124.0,
                    ),
                  ),

                  // List
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm, AppSpacing.screenPadding, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSectionHeader(filteredStaff.length),
                        const SizedBox(height: AppSpacing.sm),
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
                              onStatusChanged: (value) => _toggleStaffStatus(item, value, staff),
                              onDelete: () => _confirmDelete(item, staff),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.lg),
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
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // FIX: Rely on valueOrNull so it properly only shows when we have data
      floatingActionButton: staffState.valueOrNull != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
                onPressed: () => _openStaffForm(),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                label: Text(
                  'Add Staff User',
                  style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchCtrl,
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.search,
      style: AppTextStyles.cardValue.copyWith(fontFamily: AppTextStyles.fontBody, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Search staff...',
        hintStyle: AppTextStyles.small.copyWith(fontSize: 14),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
        suffixIcon: _searchCtrl.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() {});
                },
              ),
        filled: true,
        fillColor: AppColors.surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdownFilter<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required IconData icon,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 20),
                style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(int count) {
    return Row(
      children: [
        Text(
          '$count Staff',
          style: AppTextStyles.small.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (_hasActiveFilter)
          TextButton(
            onPressed: _clearFilters,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('Clear Filters', style: AppTextStyles.button.copyWith(fontSize: 13, color: AppColors.primary)),
          ),
      ],
    );
  }

  List<StaffUser> _filteredStaff(List<StaffUser> staff) {
    final query = _searchCtrl.text.trim().toLowerCase();

    return staff.where((item) {
      final matchesRole = _selectedRole == 'All' || item.role == _selectedRole;
      final matchesStatus = switch (_statusFilter) {
        StaffStatusFilter.all => true,
        StaffStatusFilter.active => item.isActive,
        StaffStatusFilter.inactive => !item.isActive,
      };
      final matchesQuery = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.email.toLowerCase().contains(query) ||
          item.phone.toLowerCase().contains(query);

      return matchesRole && matchesStatus && matchesQuery;
    }).toList()
      ..sort((a, b) {
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
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'ST';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
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
        return AppColors.cyan;
      default:
        return AppColors.textSecondary;
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

// ── Components ─────────────────────────────────────────────────────────────

class _StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;

  _StickyFilterDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant _StickyFilterDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight || minHeight != oldDelegate.minHeight || child != oldDelegate.child;
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
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: AppColors.surface2, shape: BoxShape.circle),
                child: const Icon(Icons.groups_2_rounded, color: AppColors.primary, size: AppSizes.iconMd),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Access',
                      style: AppTextStyles.cardValue.copyWith(
                        fontSize: 16,
                        fontFamily: AppTextStyles.fontDisplay,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$active active of $total staff',
                      style: AppTextStyles.small.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: _MiniMetric(label: 'Active', value: active.toString(), color: AppColors.green)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _MiniMetric(label: 'Inactive', value: inactive.toString(), color: AppColors.textSecondary)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _MiniMetric(label: 'Admins', value: admins.toString(), color: AppColors.orange)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTextStyles.cardValue.copyWith(color: color, fontSize: 18, fontFamily: AppTextStyles.fontDisplay)),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.small.copyWith(color: color.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600)),
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
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.cardPadding, 0, AppSpacing.cardPadding, AppSpacing.cardPadding),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: roleColor.withOpacity(0.1),
            child: Text(initials, style: AppTextStyles.cardValue.copyWith(color: roleColor, fontSize: 14)),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  staff.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardValue.copyWith(fontSize: 16, fontFamily: AppTextStyles.fontDisplay, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(width: 8, height: 8, decoration: BoxDecoration(color: staff.isActive ? AppColors.green : AppColors.textSecondary, shape: BoxShape.circle)),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(staff.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.small.copyWith(fontSize: 13)),
          ),
          children: [
            Divider(color: AppColors.borderStrong, height: 1),
            const SizedBox(height: AppSpacing.md),
            if (staff.phone.trim().isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.phone_iphone_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(staff.phone, style: AppTextStyles.small.copyWith(fontSize: 13)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: roleColor.withOpacity(0.1), borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, color: roleColor, size: 13),
                      const SizedBox(width: 5),
                      Text(staff.role, style: AppTextStyles.small.copyWith(color: roleColor, fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(staff.isActive ? 'Active' : 'Inactive', style: AppTextStyles.small.copyWith(fontSize: 12)),
                    const SizedBox(width: 6),
                    SizedBox(
                      height: 28,
                      width: 44,
                      child: Transform.scale(
                        scale: 0.75,
                        child: Switch.adaptive(
                          value: staff.isActive,
                          activeThumbColor: AppColors.textWhite,
                          activeTrackColor: AppColors.primary,
                          inactiveThumbColor: AppColors.textWhite,
                          inactiveTrackColor: AppColors.borderStrong,
                          onChanged: onStatusChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
              child: Text(roleDescription, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppTextStyles.small.copyWith(fontSize: 12, height: 1.3)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                      side: const BorderSide(color: AppColors.borderStrong),
                      backgroundColor: AppColors.card,
                      foregroundColor: AppColors.textPrimaryDark,
                    ),
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text('Edit', style: AppTextStyles.button.copyWith(fontSize: 13, color: AppColors.textPrimaryDark)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                      backgroundColor: AppColors.red.withOpacity(0.06),
                      foregroundColor: AppColors.red,
                      side: BorderSide.none,
                    ),
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: Text('Delete', style: AppTextStyles.button.copyWith(fontSize: 13, color: AppColors.red)),
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
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppSizes.cardRadius)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding),
          childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.cardPadding, 0, AppSpacing.cardPadding, AppSpacing.lg),
          leading: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: AppColors.surface2, shape: BoxShape.circle),
            child: const Icon(Icons.gavel_rounded, color: AppColors.primary, size: AppSizes.iconMd),
          ),
          title: Text(
            'Permissions Guide',
            style: AppTextStyles.cardValue.copyWith(fontSize: 16, fontFamily: AppTextStyles.fontDisplay, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
          ),
          subtitle: Text(
            RoleAccessPolicy.allowAllRolesTemporarily ? 'Temporary unlimited access enabled' : 'View system rules by roles',
            style: AppTextStyles.small.copyWith(fontSize: 13),
          ),
          children: roles
              .map((role) => Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(color: roleColor(role).withOpacity(0.1), shape: BoxShape.circle),
                          child: Icon(roleIcon(role), color: roleColor(role), size: 14),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(role, style: AppTextStyles.cardValue.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark)),
                              const SizedBox(height: 2),
                              Text(roleDescription(role), style: AppTextStyles.small.copyWith(fontSize: 12, height: 1.3)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xxl),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppSizes.cardRadius)),
      child: Column(
        children: [
          Icon(hasStaff ? Icons.manage_search_rounded : Icons.person_add_disabled_rounded, color: AppColors.borderStrong, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(hasStaff ? 'No Matches Found' : 'No Staff Found', textAlign: TextAlign.center, style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimaryDark)),
          const SizedBox(height: AppSpacing.xs),
          Text(hasStaff ? 'Try adjusting your filters.' : 'Add staff to get started.', textAlign: TextAlign.center, style: AppTextStyles.small.copyWith(fontSize: 13, height: 1.4)),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        title: Text(
          'Staff Access',
          style: AppTextStyles.cardValue.copyWith(fontSize: 22, fontFamily: AppTextStyles.fontDisplay, fontWeight: FontWeight.w700, color: AppColors.textPrimaryDark),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, color: AppColors.red, size: 48),
              const SizedBox(height: AppSpacing.md),
              Text('Failed to load staff', style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: AppSpacing.xs),
              Text(message, textAlign: TextAlign.center, style: AppTextStyles.small.copyWith(fontSize: 13)),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.textWhite, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd))),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text('Try Again', style: AppTextStyles.button.copyWith(fontSize: 14, color: AppColors.textWhite)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}