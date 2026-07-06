// =========================================================
// lib/features/inventory/presentation/screens/product_detail_screen.dart
// =========================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/storage/db_helper.dart';

import '../providers/inventory_providers.dart';
import 'stock_in_screen.dart';
import 'stock_out_screen.dart';

// ── One-off provider: movements for a given productId ──────────────────────
final _movementsProvider = FutureProvider.family
    .autoDispose<List<Map<String, dynamic>>, int>((ref, productId) async {
      return DBHelper.getProductMovements(productId);
    });

// ── One-off provider: fresh product data (after adjust/reorder actions) ────
final _productDetailProvider = FutureProvider.family
    .autoDispose<Map<String, dynamic>?, int>((ref, productId) async {
      ref.watch(productsRefreshProvider); // re-runs when inventory is refreshed
      return DBHelper.getProductById(productId);
    });

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get _productId => widget.product['id'] as int;

  @override
  Widget build(BuildContext context) {
    // Use fresh product data if available, else fall back to what was passed in
    final freshAsync = ref.watch(_productDetailProvider(_productId));
    final product = freshAsync.asData?.value ?? widget.product;

    final qty = (product['quantity'] as num?)?.toInt() ?? 0;
    final price = (product['selling_price'] as num?)?.toDouble() ?? 0.0;
    final purchasePrice =
        (product['purchase_price'] as num?)?.toDouble() ?? 0.0;
    final lsl = (product['lsl'] as num?)?.toInt() ?? 0;

    // "Committed" = qty reserved for open orders — we use lsl as a proxy
    // since there is no open-orders table yet; replace with real data when ready
    final committed = 0;
    final available = qty - committed;
    final value = qty * purchasePrice;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimaryDark,
            size: R.icon(context, AppSizes.iconLg),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          product['name']?.toString() ?? '',
          style: AppTextStyles.heading.copyWith(fontSize: R.fs(context, 18)),
        ),
        actions: [
          // Edit pencil icon (hook up to your edit product screen)
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: AppColors.textSecondary,
              size: R.icon(context, AppSizes.iconMd),
            ),
            onPressed: () {
              // TODO: navigate to AddProductScreen(product: product)
            },
          ),
          SizedBox(width: R.sp(context, AppSpacing.xs)),
        ],
      ),
      body: Column(
        children: [
          // ── Stats card (On-hand / Committed / Available / Value) ──────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              R.sp(context, AppSpacing.screenPadding),
              R.sp(context, AppSpacing.sm),
              R.sp(context, AppSpacing.screenPadding),
              0,
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: R.sp(context, AppSpacing.lg),
                vertical: R.sp(context, AppSpacing.md),
              ),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(
                  R.radius(context, AppSizes.cardRadius),
                ),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _StatCell(
                    label: 'On-hand',
                    value: '$qty',
                    valueColor: AppColors.primary,
                  ),
                  _vDivider(),
                  _StatCell(
                    label: 'Committed',
                    value: '$committed',
                    valueColor: AppColors.textPrimaryDark,
                  ),
                  _vDivider(),
                  _StatCell(
                    label: 'Available',
                    value: '$available',
                    valueColor: AppColors.green,
                  ),
                  _vDivider(),
                  _StatCell(
                    label: 'Value',
                    value: _formatCompact(value),
                    valueColor: AppColors.textPrimaryDark,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: R.sp(context, AppSpacing.md)),

          // ── Tab bar ───────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: R.sp(context, AppSpacing.screenPadding),
            ),
            child: Container(
              padding: EdgeInsets.all(R.sp(context, 4)),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(
                  R.radius(context, AppSizes.radiusMd),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(
                    R.radius(context, AppSizes.radiusSm),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppColors.textPrimaryDark,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTextStyles.small.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: R.fs(context, 13),
                ),
                unselectedLabelStyle: AppTextStyles.small.copyWith(
                  fontSize: R.fs(context, 13),
                ),
                tabs: const [
                  Tab(text: 'Details'),
                  Tab(text: 'Movements'),
                  Tab(text: 'Stats'),
                ],
              ),
            ),
          ),

          SizedBox(height: R.sp(context, AppSpacing.sm)),

          // ── Tab views ────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _DetailsTab(product: product),
                _MovementsTab(productId: _productId),
                _StatsTab(product: product),
              ],
            ),
          ),
        ],
      ),

      // ── Bottom buttons ────────────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: R.sp(context, AppSpacing.screenPadding),
            vertical: R.sp(context, AppSpacing.sm),
          ),
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              // Adjust stock — outlined plain button
              Expanded(
                child: SizedBox(
                  height: R.sp(context, AppSizes.buttonHeight),
                  child: OutlinedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StockOutScreen(),
                        ),
                      );
                      refreshInventory(ref);
                      ref.invalidate(_productDetailProvider(_productId));
                      ref.invalidate(_movementsProvider(_productId));
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          R.radius(context, AppSizes.radiusMd),
                        ),
                      ),
                    ),
                    child: Text(
                      'Adjust stock',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: R.sp(context, AppSpacing.sm)),
              // Reorder — gradient button
              Expanded(
                flex: 2,
                child: Container(
                  height: R.sp(context, AppSizes.buttonHeight),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(
                      R.radius(context, AppSizes.radiusMd),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                        R.radius(context, AppSizes.radiusMd),
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StockInScreen(),
                          ),
                        );
                        refreshInventory(ref);
                        ref.invalidate(_productDetailProvider(_productId));
                        ref.invalidate(_movementsProvider(_productId));
                      },
                      child: Center(
                        child: Text(
                          'Reorder',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.textWhite,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vDivider() {
    return Container(
      height: R.sp(context, 32),
      width: 1,
      color: AppColors.border,
      margin: EdgeInsets.symmetric(horizontal: R.sp(context, AppSpacing.sm)),
    );
  }

  String _formatCompact(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat cell inside the top card
// ─────────────────────────────────────────────────────────────────────────────
class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatCell({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: R.fs(context, 11),
            ),
          ),
          SizedBox(height: R.sp(context, AppSpacing.xs)),
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppTextStyles.cardValue.copyWith(
              fontSize: R.fs(context, 18),
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1: Details
// ─────────────────────────────────────────────────────────────────────────────
class _DetailsTab extends StatelessWidget {
  final Map<String, dynamic> product;
  const _DetailsTab({required this.product});

  @override
  Widget build(BuildContext context) {
    final rows = <_DetailRow>[
      _DetailRow('SKU', 'SKU-${product['id']}'),
      _DetailRow('Category', product['category']?.toString() ?? '—'),
      _DetailRow('Unit', product['unit']?.toString() ?? '—'),
      _DetailRow('Barcode', product['barcode']?.toString() ?? '—'),
      _DetailRow('Supplier', product['supplier']?.toString() ?? '—'),
      _DetailRow(
        'Expiry date',
        product['expiry_date']?.toString().isNotEmpty == true
            ? product['expiry_date'].toString()
            : '—',
      ),
      _DetailRow(
        'Purchase price',
        '₹${(product['purchase_price'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}',
      ),
      _DetailRow(
        'Selling price',
        '₹${(product['selling_price'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}',
      ),
      _DetailRow(
        'Discount',
        product['discount'] != null && product['discount'] != 0
            ? '${product['discount']}%'
            : '—',
      ),
      _DetailRow(
        'SGST',
        product['sgst'] != null && product['sgst'] != 0
            ? '${product['sgst']}%'
            : '—',
      ),
      _DetailRow(
        'CGST',
        product['cgst'] != null && product['cgst'] != 0
            ? '${product['cgst']}%'
            : '—',
      ),
      _DetailRow('HSN Code', product['hsn_code']?.toString() ?? '—'),
      _DetailRow('Reorder level', '${product['lsl'] ?? '—'}'),
      _DetailRow(
        'Description',
        product['description']?.toString().isNotEmpty == true
            ? product['description'].toString()
            : '—',
      ),
    ];

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: R.sp(context, AppSpacing.screenPadding),
        vertical: R.sp(context, AppSpacing.sm),
      ),
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(
              R.radius(context, AppSizes.cardRadius),
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: List.generate(rows.length, (i) {
              final row = rows[i];
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: R.sp(context, AppSpacing.lg),
                      vertical: R.sp(context, AppSpacing.md),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: R.sp(context, 110),
                          child: Text(
                            row.label,
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: R.fs(context, 12),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            row.value,
                            style: AppTextStyles.cardValue.copyWith(
                              fontSize: R.fs(context, 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < rows.length - 1)
                    Divider(height: 1, thickness: 1, color: AppColors.border),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _DetailRow {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2: Movements  (reads stock_transactions via _movementsProvider)
// ─────────────────────────────────────────────────────────────────────────────
class _MovementsTab extends ConsumerWidget {
  final int productId;
  const _MovementsTab({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movementsAsync = ref.watch(_movementsProvider(productId));

    return movementsAsync.when(
      data: (movements) {
        if (movements.isEmpty) {
          return Center(
            child: Text('No movements yet', style: AppTextStyles.subHeading),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.symmetric(
            horizontal: R.sp(context, AppSpacing.screenPadding),
            vertical: R.sp(context, AppSpacing.sm),
          ),
          itemCount: movements.length,
          separatorBuilder: (_, __) =>
              SizedBox(height: R.sp(context, AppSpacing.sm)),
          itemBuilder: (context, i) => _MovementTile(movement: movements[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text('Error: $e', style: AppTextStyles.small)),
    );
  }
}

class _MovementTile extends StatelessWidget {
  final Map<String, dynamic> movement;
  const _MovementTile({required this.movement});

  @override
  Widget build(BuildContext context) {
    final type = movement['type']?.toString() ?? '';
    final reason = movement['reason']?.toString() ?? '';
    final qty = (movement['quantity'] as num?)?.toInt() ?? 0;
    final reference = movement['reference']?.toString() ?? '';
    final note = movement['note']?.toString() ?? '';
    final dateRaw = movement['date']?.toString() ?? '';

    // Parse "running balance" stored in the movement row (if present)
    final balance = movement['running_balance'];

    // Determine icon colour and label from type
    Color dot;
    String typeLabel;
    String qtyDisplay;

    if (type == 'in') {
      dot = AppColors.green;
      typeLabel = reason.isEmpty ? 'Stock In' : reason;
      qtyDisplay = '+$qty';
    } else if (type == 'sale') {
      dot = AppColors.primary;
      typeLabel = 'Sale';
      qtyDisplay = '−$qty';
    } else {
      // out / adjust / damage etc.
      dot = AppColors.orange;
      typeLabel = reason.isEmpty ? 'Adjustment' : reason;
      qtyDisplay = '−$qty';
    }

    final subParts = <String>[];
    if (reference.isNotEmpty) subParts.add(reference);
    if (note.isNotEmpty) subParts.add(note);
    subParts.add(_friendlyDate(dateRaw));

    return Container(
      padding: EdgeInsets.all(R.sp(context, AppSpacing.cardPadding)),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(
          R.radius(context, AppSizes.cardRadius),
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coloured dot
          Padding(
            padding: EdgeInsets.only(top: R.sp(context, 4)),
            child: Container(
              width: R.sp(context, 8),
              height: R.sp(context, 8),
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
          ),
          SizedBox(width: R.sp(context, AppSpacing.md)),

          // Type + sub-line
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text: typeLabel,
                    style: AppTextStyles.cardValue.copyWith(
                      fontSize: R.fs(context, 13),
                    ),
                    children: [
                      TextSpan(
                        text: '  $qtyDisplay',
                        style: AppTextStyles.cardValue.copyWith(
                          fontSize: R.fs(context, 13),
                          color: type == 'in' ? AppColors.green : AppColors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: R.sp(context, 2)),
                Text(subParts.join(' · '), style: AppTextStyles.small),
              ],
            ),
          ),

          // Running balance
          if (balance != null)
            Text(
              '→ $balance',
              style: AppTextStyles.small.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  String _friendlyDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return raw;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3: Stats
// ─────────────────────────────────────────────────────────────────────────────
class _StatsTab extends ConsumerWidget {
  final Map<String, dynamic> product;
  const _StatsTab({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productId = product['id'] as int;
    final movementsAsync = ref.watch(_movementsProvider(productId));

    return movementsAsync.when(
      data: (movements) {
        // Compute aggregates from transaction history
        int totalIn = 0;
        int totalOut = 0;
        double totalCostIn = 0;

        for (final m in movements) {
          final qty = (m['quantity'] as num?)?.toInt() ?? 0;
          if (m['type'] == 'in') {
            totalIn += qty;
            totalCostIn += qty * ((m['unitCost'] as num?)?.toDouble() ?? 0.0);
          } else {
            totalOut += qty;
          }
        }

        final qty = (product['quantity'] as num?)?.toInt() ?? 0;
        final purchasePrice =
            (product['purchase_price'] as num?)?.toDouble() ?? 0.0;
        final sellingPrice =
            (product['selling_price'] as num?)?.toDouble() ?? 0.0;
        final lsl = (product['lsl'] as num?)?.toInt() ?? 0;
        final inventoryValue = qty * purchasePrice;
        final potentialRevenue = qty * sellingPrice;
        final profit = sellingPrice > 0 && purchasePrice > 0
            ? ((sellingPrice - purchasePrice) / purchasePrice) * 100
            : 0.0;

        final stats = <_StatCardData>[
          _StatCardData(
            icon: Icons.arrow_downward_rounded,
            iconColor: AppColors.green,
            label: 'Total received',
            value: '$totalIn units',
          ),
          _StatCardData(
            icon: Icons.arrow_upward_rounded,
            iconColor: AppColors.red,
            label: 'Total consumed / sold',
            value: '$totalOut units',
          ),
          _StatCardData(
            icon: Icons.inventory_2_outlined,
            iconColor: AppColors.primary,
            label: 'Current on-hand',
            value: '$qty units',
          ),
          _StatCardData(
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.orange,
            label: 'Reorder level (LSL)',
            value: '$lsl units',
          ),
          _StatCardData(
            icon: Icons.currency_rupee,
            iconColor: AppColors.primary,
            label: 'Inventory value (purchase)',
            value: _fc(inventoryValue),
          ),
          _StatCardData(
            icon: Icons.sell_outlined,
            iconColor: AppColors.cyan,
            label: 'Potential revenue',
            value: _fc(potentialRevenue),
          ),
          _StatCardData(
            icon: Icons.trending_up,
            iconColor: profit >= 0 ? AppColors.green : AppColors.red,
            label: 'Profit margin',
            value: '${profit.toStringAsFixed(1)}%',
          ),
          _StatCardData(
            icon: Icons.receipt_long_outlined,
            iconColor: AppColors.textSecondary,
            label: 'Total stock transactions',
            value: '${movements.length}',
          ),
        ];

        return ListView(
          padding: EdgeInsets.symmetric(
            horizontal: R.sp(context, AppSpacing.screenPadding),
            vertical: R.sp(context, AppSpacing.sm),
          ),
          children: stats.map((s) => _buildStatCard(context, s)).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text('Error: $e', style: AppTextStyles.small)),
    );
  }

  String _fc(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  Widget _buildStatCard(BuildContext context, _StatCardData s) {
    return Container(
      margin: EdgeInsets.only(bottom: R.sp(context, AppSpacing.sm)),
      padding: EdgeInsets.all(R.sp(context, AppSpacing.cardPadding)),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(
          R.radius(context, AppSizes.cardRadius),
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(R.sp(context, AppSpacing.sm)),
            decoration: BoxDecoration(
              color: s.iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                R.radius(context, AppSizes.radiusMd),
              ),
            ),
            child: Icon(
              s.icon,
              size: R.icon(context, AppSizes.iconMd),
              color: s.iconColor,
            ),
          ),
          SizedBox(width: R.sp(context, AppSpacing.md)),
          Expanded(
            child: Text(
              s.label,
              style: AppTextStyles.cardTitle.copyWith(
                fontSize: R.fs(context, 12),
              ),
            ),
          ),
          Text(
            s.value,
            style: AppTextStyles.cardValue.copyWith(
              fontSize: R.fs(context, 14),
              color: AppColors.textPrimaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardData {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _StatCardData({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });
}
