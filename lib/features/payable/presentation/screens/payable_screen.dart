// lib/features/payable/presentation/screens/payable_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../reports/presentation/widgets/report_shared_widgets.dart';
import '../../../suppliers/domain/entities/supplier.dart';
import '../../../suppliers/presentation/providers/supplier_provider.dart';
import 'payable_details_screen.dart';

/// PAYABLE SCREEN
/// ──────────────
/// Lists every supplier with a "Due" / "Settled" indication, plus a
/// running total.
///
/// DATA FLOW: this reads from [suppliersNotifierProvider] — the exact
/// same source your Suppliers screen already uses — so the amount shown
/// here for every supplier is guaranteed to match the Suppliers screen
/// exactly (currentBalance straight from suppliers.php). The Reports
/// feature's own `purchases`/`receivables` actions return unaggregated
/// data that doesn't reconcile with the real ledger, so this screen
/// intentionally does not use them for the list — only the detail
/// screen still uses reports.php, for the purchase-order breakdown that
/// isn't available anywhere else.
class PayableScreen extends ConsumerStatefulWidget {
  const PayableScreen({super.key});

  @override
  ConsumerState<PayableScreen> createState() => _PayableScreenState();
}

class _PayableScreenState extends ConsumerState<PayableScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _dueOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(suppliersNotifierProvider.notifier).fetchAllSuppliers(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(suppliersNotifierProvider);
    final allSuppliers = state.suppliers;

    final totalPayable = allSuppliers.fold<double>(0.0, (sum, s) => sum + s.currentBalance);

    final filtered = allSuppliers.where((s) {
      final matchesQuery = _query.isEmpty ||
          s.supplierName.toLowerCase().contains(_query.toLowerCase()) ||
          (s.phone ?? '').replaceAll(RegExp(r'\s+'), '').contains(_query);
      final matchesDue = !_dueOnly || s.currentBalance > 0;
      return matchesQuery && matchesDue;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Payable to Suppliers',
          style: TextStyle(
            fontSize: R.fs(context, 18),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                R.sp(context, 16),
                R.sp(context, 4),
                R.sp(context, 16),
                R.sp(context, 12),
              ),
              child: Column(
                children: [
                  // ── Search bar ──
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search supplier name or phone...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(vertical: R.sp(context, 12)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(R.radius(context, 12)),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(R.radius(context, 12)),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  SizedBox(height: R.sp(context, 12)),

                  // ── Total summary cards ──
                  Row(
                    children: [
                      _StatCard(
                        label: 'Suppliers',
                        value: '${allSuppliers.length}',
                        icon: Icons.local_shipping_outlined,
                      ),
                      SizedBox(width: R.sp(context, 12)),
                      _StatCard(
                        label: 'Total Payable',
                        value: formatRupee(totalPayable),
                        icon: Icons.account_balance_wallet_outlined,
                        valueColor: AppColors.primary,
                      ),
                    ],
                  ),
                  SizedBox(height: R.sp(context, 12)),

                  // ── All / Due filter ──
                  Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: !_dueOnly,
                        onTap: () => setState(() => _dueOnly = false),
                      ),
                      SizedBox(width: R.sp(context, 8)),
                      _FilterChip(
                        label: 'Due',
                        selected: _dueOnly,
                        onTap: () => setState(() => _dueOnly = true),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: state.isLoading && allSuppliers.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Text(
                            allSuppliers.isEmpty ? 'No suppliers found yet.' : 'No matches.',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            await ref
                                .read(suppliersNotifierProvider.notifier)
                                .fetchAllSuppliers(refresh: true);
                          },
                          child: ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                              R.sp(context, 16),
                              0,
                              R.sp(context, 16),
                              R.sp(context, 24),
                            ),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => SizedBox(height: R.sp(context, 10)),
                            itemBuilder: (context, index) => _PayableSupplierRow(
                              supplier: filtered[index],
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

class _PayableSupplierRow extends StatelessWidget {
  final Supplier supplier;
  const _PayableSupplierRow({required this.supplier});

  @override
  Widget build(BuildContext context) {
    final hasDue = supplier.currentBalance > 0;
    final name = supplier.supplierName.trim().isEmpty ? 'Supplier' : supplier.supplierName.trim();
    final parts = name.split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name[0].toUpperCase();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PayableDetailsScreen(
            supplierId: supplier.id.toString(),
            supplierName: supplier.supplierName,
            phone: supplier.phone ?? '',
            currentBalance: supplier.currentBalance,
          ),
        ),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: R.sp(context, 14),
          vertical: R.sp(context, 12),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(R.radius(context, 12)),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: R.fluid(context, 44, 56),
              height: R.fluid(context, 44, 56),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.brandGradient,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: R.fs(context, 13),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: R.sp(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: R.fs(context, 14),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((supplier.phone ?? '').isNotEmpty) ...[
                    SizedBox(height: R.sp(context, 2)),
                    Text(
                      supplier.phone!,
                      style: TextStyle(fontSize: R.fs(context, 12), color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatRupee(supplier.currentBalance),
                  style: TextStyle(
                    fontSize: R.fs(context, 14),
                    fontWeight: FontWeight.w700,
                    color: hasDue ? AppColors.orange : AppColors.textPrimaryDark,
                  ),
                ),
                SizedBox(height: R.sp(context, 4)),
                ReportBadge.auto(hasDue ? 'Due' : 'Settled'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: R.sp(context, 16), vertical: R.sp(context, 14)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(R.radius(context, 16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: R.fs(context, 11),
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: R.sp(context, 6)),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: R.fs(context, 18),
                      fontWeight: FontWeight.bold,
                      color: valueColor ?? AppColors.textPrimaryDark,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(R.sp(context, 8)),
              decoration: BoxDecoration(
                color: (valueColor ?? AppColors.primary).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: R.icon(context, 18), color: valueColor ?? AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: R.sp(context, 18), vertical: R.sp(context, 8)),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.brandGradient : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(R.radius(context, 50)),
          border: Border.all(color: selected ? Colors.transparent : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimaryDark,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: R.fs(context, 13),
          ),
        ),
      ),
    );
  }
}
