// lib/features/receivable/presentation/screens/receivable_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../customers/presentation/provider/customer_provider.dart';
import '../../../reports/presentation/widgets/report_shared_widgets.dart';
import 'receivable_details_screen.dart';

/// RECEIVABLE SCREEN
/// ─────────────────
/// Lists every customer with a "Due" / "Settled" indication, plus a
/// running total.
///
/// DATA FLOW: this reads from [allCustomersProvider] — the exact same
/// source your Customers screen already uses — so the amount shown here
/// for every customer is guaranteed to match the Customers screen
/// exactly (currentBalance straight from customers.php). The Reports
/// feature's own `receivables` action returns unaggregated data that
/// doesn't reconcile with the real ledger, so this screen intentionally
/// does not use it for the list — only the detail screen still uses
/// reports.php, for the invoice breakdown that isn't available anywhere
/// else.
class ReceivableScreen extends ConsumerStatefulWidget {
  const ReceivableScreen({super.key});

  @override
  ConsumerState<ReceivableScreen> createState() => _ReceivableScreenState();
}

class _ReceivableScreenState extends ConsumerState<ReceivableScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _dueOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(allCustomersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Receivable from Customers',
          style: TextStyle(
            fontSize: R.fs(context, 18),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ),
      body: SafeArea(
        child: customersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('Could not load customers.', style: const TextStyle(color: AppColors.textSecondary)),
          ),
          data: (allCustomers) {
            final totalReceivable = allCustomers.fold<double>(0.0, (sum, c) => sum + c.currentBalance);

            final filtered = allCustomers.where((c) {
              final matchesQuery = _query.isEmpty ||
                  c.customerName.toLowerCase().contains(_query.toLowerCase()) ||
                  c.phone.replaceAll(RegExp(r'\s+'), '').contains(_query);
              final matchesDue = !_dueOnly || c.currentBalance > 0;
              return matchesQuery && matchesDue;
            }).toList();

            return Column(
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
                      TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: 'Search customer name or phone...',
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
                      Row(
                        children: [
                          _StatCard(
                            label: 'Customers',
                            value: '${allCustomers.length}',
                            icon: Icons.people_outline,
                          ),
                          SizedBox(width: R.sp(context, 12)),
                          _StatCard(
                            label: 'Total Receivable',
                            value: formatRupee(totalReceivable),
                            icon: Icons.account_balance_wallet_outlined,
                            valueColor: AppColors.primary,
                          ),
                        ],
                      ),
                      SizedBox(height: R.sp(context, 12)),
                      Row(
                        children: [
                          _FilterChip(label: 'All', selected: !_dueOnly, onTap: () => setState(() => _dueOnly = false)),
                          SizedBox(width: R.sp(context, 8)),
                          _FilterChip(label: 'Due', selected: _dueOnly, onTap: () => setState(() => _dueOnly = true)),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            allCustomers.isEmpty ? 'No customers found yet.' : 'No matches.',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async => ref.invalidate(allCustomersProvider),
                          child: ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                              R.sp(context, 16),
                              0,
                              R.sp(context, 16),
                              R.sp(context, 24),
                            ),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => SizedBox(height: R.sp(context, 10)),
                            itemBuilder: (context, index) => _ReceivableCustomerRow(customer: filtered[index]),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReceivableCustomerRow extends StatelessWidget {
  final CustomerModel customer;
  const _ReceivableCustomerRow({required this.customer});

  @override
  Widget build(BuildContext context) {
    final hasDue = customer.currentBalance > 0;
    final name = customer.customerName.trim().isEmpty ? 'Customer' : customer.customerName.trim();
    final parts = name.split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name[0].toUpperCase();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReceivableDetailsScreen(
            customerId: (customer.id ?? 0).toString(),
            customerName: customer.customerName,
            phone: customer.phone,
            currentBalance: customer.currentBalance,
          ),
        ),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: R.sp(context, 14), vertical: R.sp(context, 12)),
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
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.brandGradient),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(fontSize: R.fs(context, 13), fontWeight: FontWeight.w600, color: Colors.white),
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
                    style: TextStyle(fontSize: R.fs(context, 14), fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (customer.phone.isNotEmpty) ...[
                    SizedBox(height: R.sp(context, 2)),
                    Text(customer.phone, style: TextStyle(fontSize: R.fs(context, 12), color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatRupee(customer.currentBalance),
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

  const _StatCard({required this.label, required this.value, required this.icon, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: R.sp(context, 16), vertical: R.sp(context, 14)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(R.radius(context, 16)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
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
                    style: TextStyle(fontSize: R.fs(context, 11), color: AppColors.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  ),
                  SizedBox(height: R.sp(context, 6)),
                  Text(
                    value,
                    style: TextStyle(fontSize: R.fs(context, 18), fontWeight: FontWeight.bold, color: valueColor ?? AppColors.textPrimaryDark),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(R.sp(context, 8)),
              decoration: BoxDecoration(color: (valueColor ?? AppColors.primary).withValues(alpha: 0.08), shape: BoxShape.circle),
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
