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
      ref
          .read(suppliersNotifierProvider.notifier)
          .fetchAllSuppliers(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildHighlightedText(
    String text,
    String query,
    TextStyle baseStyle,
    TextStyle highlightStyle,
  ) {
    if (query.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase().trim();

    if (lowerQuery.isEmpty || !lowerText.contains(lowerQuery)) {
      return Text(
        text,
        style: baseStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final List<TextSpan> spans = [];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        break;
      }

      if (index > start) {
        spans.add(
          TextSpan(text: text.substring(start, index), style: baseStyle),
        );
      }

      final matchEnd = index + lowerQuery.length;
      spans.add(
        TextSpan(text: text.substring(index, matchEnd), style: highlightStyle),
      );
      start = matchEnd;
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(suppliersNotifierProvider);
    final allSuppliers = state.suppliers;

    final totalPayable = allSuppliers.fold<double>(
      0.0,
      (sum, s) => sum + s.currentBalance,
    );

    final filtered = allSuppliers.where((s) {
      final matchesQuery =
          _query.isEmpty ||
          s.supplierName.toLowerCase().contains(_query.toLowerCase()) ||
          (s.phone ?? '').replaceAll(RegExp(r'\s+'), '').contains(_query);
      final matchesDue = !_dueOnly || s.currentBalance > 0;
      return matchesQuery && matchesDue;
    }).toList();

    final hPad = R.hPad(context).left;

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
                hPad,
                R.sp(context, 4),
                hPad,
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
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: R.sp(context, 12),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          R.radius(context, 12),
                        ),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          R.radius(context, 12),
                        ),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          R.radius(context, 12),
                        ),
                        borderSide: const BorderSide(
                          color: AppColors.cyan,
                          width: 1.5,
                        ),
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
                        label: 'Payable',
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
                        allSuppliers.isEmpty
                            ? 'No suppliers found yet.'
                            : 'No matches.',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await ref
                            .read(suppliersNotifierProvider.notifier)
                            .fetchAllSuppliers(refresh: true);
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          hPad,
                          0,
                          hPad,
                          R.sp(context, 24),
                        ),
                        child: _ResponsiveGrid(
                          columns: R.gridCols(
                            context,
                            phone: 1,
                            tablet: 2,
                            desktop: 3,
                          ),
                          spacing: R.sp(context, 12),
                          runSpacing: R.sp(context, 10),
                          children: [
                            for (final s in filtered)
                              _PayableSupplierRow(
                                key: ValueKey(s.id),
                                supplier: s,
                                query: _query,
                                buildHighlightedText: _buildHighlightedText,
                              ),
                          ],
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
  final String query;
  final Widget Function(String, String, TextStyle, TextStyle)
  buildHighlightedText;

  const _PayableSupplierRow({
    super.key,
    required this.supplier,
    required this.query,
    required this.buildHighlightedText,
  });

  @override
  Widget build(BuildContext context) {
    final hasDue = supplier.currentBalance > 0;
    final name = supplier.supplierName.trim().isEmpty
        ? 'Supplier'
        : supplier.supplierName.trim();
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
                  buildHighlightedText(
                    name,
                    query,
                    TextStyle(
                      fontSize: R.fs(context, 14),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryDark,
                    ),
                    TextStyle(
                      fontSize: R.fs(context, 14),
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  if ((supplier.phone ?? '').isNotEmpty) ...[
                    SizedBox(height: R.sp(context, 2)),
                    Text(
                      supplier.phone!,
                      style: TextStyle(
                        fontSize: R.fs(context, 12),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      formatRupee(supplier.currentBalance),
                      style: TextStyle(
                        fontSize: R.fs(context, 14),
                        fontWeight: FontWeight.w700,
                        color: hasDue
                            ? AppColors.orange
                            : AppColors.textPrimaryDark,
                      ),
                    ),
                  ),
                  SizedBox(height: R.sp(context, 4)),
                  ReportBadge.auto(hasDue ? 'Due' : 'Settled'),
                ],
              ),
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
        padding: EdgeInsets.symmetric(
          horizontal: R.sp(context, 16),
          vertical: R.sp(context, 14),
        ),
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
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: R.fs(context, 18),
                        fontWeight: FontWeight.bold,
                        color: valueColor ?? AppColors.textPrimaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(R.sp(context, 8)),
              decoration: BoxDecoration(
                color: (valueColor ?? AppColors.primary).withValues(
                  alpha: 0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: R.icon(context, 18),
                color: valueColor ?? AppColors.primary,
              ),
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

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: R.sp(context, 18),
          vertical: R.sp(context, 8),
        ),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.brandGradient : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(R.radius(context, 50)),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.border,
          ),
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

class _ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int columns;
  final double spacing;
  final double runSpacing;

  const _ResponsiveGrid({
    required this.children,
    required this.columns,
    required this.spacing,
    required this.runSpacing,
  });

  @override
  Widget build(BuildContext context) {
    if (columns <= 1) {
      return Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: runSpacing),
            children[i],
          ],
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
