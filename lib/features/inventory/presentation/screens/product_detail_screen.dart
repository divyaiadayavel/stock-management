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

// ✅ Correct providers
import '../providers/inventory_provider.dart'; // contains repository provider, summary, refresh, etc.
import '../../../products/data/models/product_model.dart';
import '../../domain/entities/stock_movement.dart'; // ✅ StockMovement entity
import 'stock_in_screen.dart';
import 'stock_out_screen.dart';
import '../providers/inventory_filter_provider.dart';
// ── Providers (can be moved to inventory_provider.dart later) ──

/// Fetches a product by ID using the repository.
final productDetailProvider = FutureProvider.family.autoDispose<Product?, int>(
  (ref, productId) async {
    final repo = ref.watch(inventoryRepositoryProvider);
    return repo.getProductById(productId);
  },
);

/// Fetches stock movements for a given product.
final movementsProvider = FutureProvider.family.autoDispose<
    List<StockMovement>, int>(
  (ref, productId) async {
    final repo = ref.watch(inventoryRepositoryProvider);
    return repo.getStockMovements(productId: productId);
  },
);

// ─── Screen ─────────────────────────────────────────────────

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product; // ✅ Uses existing Product model

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

  // ✅ Handle nullable id
  int get _productId => widget.product.id ?? 0;

  @override
  Widget build(BuildContext context) {
    // Use fresh product data if available, else fall back to what was passed in
    final freshAsync = ref.watch(productDetailProvider(_productId));
    final product = freshAsync.asData?.value ?? widget.product;

    final qty = product.quantity;
    final purchasePrice = product.purchasePrice; // non‑nullable


    // "Committed" = qty reserved for open orders — we use lsl as a proxy
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
          product.name,
          style: AppTextStyles.heading.copyWith(fontSize: R.fs(context, 18)),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: AppColors.textSecondary,
              size: R.icon(context, AppSizes.iconMd),
            ),
            onPressed: () {
              // TODO: navigate to EditProductScreen(product: product)
            },
          ),
          SizedBox(width: R.sp(context, AppSpacing.xs)),
        ],
      ),
      body: Column(
        children: [
          // ── Stats card ──────────────────────────────────────────
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

          // ── Tab bar ─────────────────────────────────────────────
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

          // ── Tab views ──────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _DetailsTab(product: product),
                _MovementsTab(productId: _productId),
                _StatsTab(product: product, productId: _productId),
              ],
            ),
          ),
        ],
      ),

      // ── Bottom buttons ──────────────────────────────────────
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
              // Adjust stock
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
                      _refreshAfterAction();
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
              // Reorder
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
                        _refreshAfterAction();
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

void _refreshAfterAction() {
  ref.read(inventoryRefreshProvider.notifier).state++;

  ref.invalidate(productDetailProvider(_productId));
  ref.invalidate(movementsProvider(_productId));
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

// ────────────────────────────────────────────────────────────

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

// ────────────────────────────────────────────────────────────
// TAB 1: Details
// ────────────────────────────────────────────────────────────

class _DetailsTab extends StatelessWidget {
  final Product product;
  const _DetailsTab({required this.product});

  @override
  Widget build(BuildContext context) {
    final rows = <_DetailRow>[
      _DetailRow('SKU', 'SKU-${product.id}'),
      _DetailRow('Category', product.category),
      _DetailRow('Unit', product.unit),
      _DetailRow('Barcode', product.barcode.isEmpty ? '—' : product.barcode),
      _DetailRow('Supplier', product.supplier.isEmpty ? '—' : product.supplier),
      _DetailRow(
        'Expiry date',
        product.expiryDate.isEmpty ? '—' : product.expiryDate,
      ),
      _DetailRow(
        'Purchase price',
        '₹${product.purchasePrice.toStringAsFixed(2)}',
      ),
      _DetailRow(
        'Selling price',
        '₹${product.sellingPrice.toStringAsFixed(2)}',
      ),
      _DetailRow(
        'Discount',
        product.discount != 0 ? '${product.discount}%' : '—',
      ),
      _DetailRow(
        'SGST',
        product.sgst != 0 ? '${product.sgst}%' : '—',
      ),
      _DetailRow(
        'CGST',
        product.cgst != 0 ? '${product.cgst}%' : '—',
      ),
      _DetailRow('HSN Code', product.hsnCode.isEmpty ? '—' : product.hsnCode),
      _DetailRow('Reorder level', '${product.lsl}'),
      _DetailRow(
        'Description',
        product.description.isNotEmpty ? product.description : '—',
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

// ────────────────────────────────────────────────────────────
// TAB 2: Movements
// ────────────────────────────────────────────────────────────

class _MovementsTab extends ConsumerWidget {
  final int productId;
  const _MovementsTab({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movementsAsync = ref.watch(movementsProvider(productId));

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
  final StockMovement movement;
  const _MovementTile({required this.movement});

  @override
  Widget build(BuildContext context) {
    final type = movement.movementType; // 'IN' or 'OUT'
    final reason = movement.referenceType;
    final qty = movement.quantity;
    final reference = movement.referenceNumber;
    final note = movement.remarks;
    final date = movement.createdAt;

    Color dot;
    String typeLabel;
    String qtyDisplay;

if (type == 'STOCK_IN' || type == 'PURCHASE') {
  dot = AppColors.green;
  typeLabel = reason.isEmpty ? 'Stock In' : reason;
  qtyDisplay = '+$qty';
} else if (type == 'STOCK_OUT' ||
    type == 'SALE' ||
    type == 'DAMAGE') {
  dot = AppColors.red;
  typeLabel = reason.isEmpty ? 'Stock Out' : reason;
  qtyDisplay = '-$qty';
} else {
  dot = AppColors.orange;
  typeLabel = reason.isEmpty ? 'Adjustment' : reason;
  qtyDisplay = '$qty';
}

    final subParts = <String>[];
    if (reference.isNotEmpty) subParts.add(reference);
    if (note.isNotEmpty) subParts.add(note);
    subParts.add(_friendlyDate(date));

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
          Padding(
            padding: EdgeInsets.only(top: R.sp(context, 4)),
            child: Container(
              width: R.sp(context, 8),
              height: R.sp(context, 8),
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
          ),
          SizedBox(width: R.sp(context, AppSpacing.md)),
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
                          color: (type == 'STOCK_IN' || type == 'PURCHASE')
    ? AppColors.green
    : (type == 'STOCK_OUT' ||
            type == 'SALE' ||
            type == 'DAMAGE')
        ? AppColors.red
        : AppColors.orange,
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
        ],
      ),
    );
  }

  String _friendlyDate(DateTime date) {
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
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

// ────────────────────────────────────────────────────────────
// TAB 3: Stats
// ────────────────────────────────────────────────────────────

class _StatsTab extends ConsumerWidget {
  final Product product;
  final int productId;
  const _StatsTab({required this.product, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movementsAsync = ref.watch(movementsProvider(productId));

    return movementsAsync.when(
      data: (movements) {
        int totalIn = 0;
        int totalOut = 0;

        for (final m in movements) {
          final qty = m.quantity;
          if (m.movementType == 'STOCK_IN' ||
    m.movementType == 'PURCHASE') {
            totalIn += qty;
          } else if (m.movementType == 'STOCK_OUT' ||
         m.movementType == 'SALE' ||
         m.movementType == 'DAMAGE') {
            totalOut += qty;
          }
        }

        final qty = product.quantity;
        final purchasePrice = product.purchasePrice;
        final sellingPrice = product.sellingPrice;
        final lsl = product.lsl;
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