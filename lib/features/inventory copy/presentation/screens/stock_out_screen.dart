// =========================================================
// lib/features/inventory/presentation/screens/stock_out_screen.dart
// =========================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';

import '../../../products/data/models/product_model.dart';
import '../providers/inventory_filter_provider.dart';
import '../providers/inventory_provider.dart';
import 'product_detail_screen.dart';

/// Provider to fetch and filter out-of-stock products (quantity <= 0)
final outOfStockProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  ref.watch(inventoryRefreshProvider);
  final useCase = ref.watch(getInventoryStockProvider);
  final products = await useCase.call(
    filter: 'all',
    search: '',
    sortBy: 'name_asc',
  );
  return products.where((p) => p.quantity <= 0).toList();
});

class StockOutScreen extends ConsumerStatefulWidget {
  const StockOutScreen({super.key});

  @override
  ConsumerState<StockOutScreen> createState() => _StockOutScreenState();
}

class _StockOutScreenState extends ConsumerState<StockOutScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'name_asc';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(outOfStockProductsProvider);

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
          'Out of Stock',
          style: AppTextStyles.heading.copyWith(fontSize: R.fs(context, 18)),
        ),
      ),
      body: productsAsync.when(
        data: (products) {
          var filtered = products.where((p) {
            final query = _searchQuery.toLowerCase();
            return p.name.toLowerCase().contains(query) ||
                p.category.toLowerCase().contains(query) ||
                p.supplier.toLowerCase().contains(query);
          }).toList();

          if (_sortBy == 'name_asc') {
            filtered.sort((a, b) => a.name.compareTo(b.name));
          } else if (_sortBy == 'name_desc') {
            filtered.sort((a, b) => b.name.compareTo(a.name));
          } else if (_sortBy == 'reorder_desc') {
            filtered.sort((a, b) => b.lsl.compareTo(a.lsl));
          }

          return Column(
            children: [
              // ── Summary Card & Search Row ──
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: R.sp(context, AppSpacing.screenPadding),
                  vertical: R.sp(context, AppSpacing.xs),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(
                          R.sp(context, AppSpacing.cardPadding)),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                          R.radius(context, AppSizes.cardRadius),
                        ),
                        border: Border.all(
                          color: AppColors.red.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: R.sp(context, 36),
                            height: R.sp(context, 36),
                            decoration: BoxDecoration(
                              color: AppColors.red.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.red,
                              size: R.icon(context, 20),
                            ),
                          ),
                          SizedBox(width: R.sp(context, AppSpacing.sm)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${products.length} Products Out of Stock',
                                  style: AppTextStyles.cardValue.copyWith(
                                    fontSize: R.fs(context, 14),
                                    color: AppColors.red,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: R.sp(context, 2)),
                                Text(
                                  'These products require urgent restocking',
                                  style: AppTextStyles.small.copyWith(
                                    fontSize: R.fs(context, 11),
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: R.sp(context, AppSpacing.sm)),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (v) =>
                                setState(() => _searchQuery = v.trim()),
                            decoration: InputDecoration(
                              hintText: 'Search out-of-stock products...',
                              hintStyle: AppTextStyles.small.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                size: R.icon(context, 20),
                                color: AppColors.textSecondary,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              isDense: true,
                              filled: true,
                              fillColor: AppColors.card,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: R.sp(context, 10),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  R.radius(context, AppSizes.radiusMd),
                                ),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  R.radius(context, AppSizes.radiusMd),
                                ),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  R.radius(context, AppSizes.radiusMd),
                                ),
                                borderSide:
                                    const BorderSide(color: AppColors.primary),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: R.sp(context, AppSpacing.xs)),
                        PopupMenuButton<String>(
                          icon: Container(
                            padding: EdgeInsets.all(R.sp(context, 10)),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(
                                R.radius(context, AppSizes.radiusMd),
                              ),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Icon(
                              Icons.sort_rounded,
                              color: AppColors.textPrimaryDark,
                              size: R.icon(context, 20),
                            ),
                          ),
                          onSelected: (val) => setState(() => _sortBy = val),
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'name_asc',
                              child: Text('Name (A-Z)'),
                            ),
                            const PopupMenuItem(
                              value: 'name_desc',
                              child: Text('Name (Z-A)'),
                            ),
                            const PopupMenuItem(
                              value: 'reorder_desc',
                              child: Text('Highest Reorder Level'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: R.sp(context, AppSpacing.xs)),

              // ── Product List ──
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isNotEmpty
                              ? 'No matching products found'
                              : 'No products are out of stock 🎉',
                          style: AppTextStyles.subHeading,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.read(inventoryRefreshProvider.notifier).state++;
                        },
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            R.sp(context, AppSpacing.screenPadding),
                            R.sp(context, AppSpacing.xs),
                            R.sp(context, AppSpacing.screenPadding),
                            R.sp(context, AppSpacing.lg),
                          ),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              SizedBox(height: R.sp(context, AppSpacing.sm)),
                          itemBuilder: (context, i) {
                            final product = filtered[i];
                            return _OutOfStockCard(product: product);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Text('Error loading out-of-stock products: $e',
              style: AppTextStyles.small),
        ),
      ),
    );
  }
}

class _OutOfStockCard extends StatelessWidget {
  final Product product;
  const _OutOfStockCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          product.name,
                          style: AppTextStyles.cardValue.copyWith(
                            fontSize: R.fs(context, 14),
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: R.sp(context, AppSpacing.xs)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: R.sp(context, 6),
                          vertical: R.sp(context, 2),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            R.radius(context, AppSizes.radiusSm),
                          ),
                        ),
                        child: Text(
                          'Out of Stock',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.red,
                            fontSize: R.fs(context, 10),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: R.sp(context, 4)),
                  Text(
                    'Supplier: ${product.supplier.isNotEmpty ? product.supplier : 'Unassigned'}',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: R.sp(context, 4)),
                  Text(
                    'Reorder Threshold (LSL): ${product.lsl} ${product.unit}',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: R.fs(context, 11),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: R.sp(context, AppSpacing.sm)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '0 ${product.unit}',
                  style: AppTextStyles.cardValue.copyWith(
                    fontSize: R.fs(context, 15),
                    fontWeight: FontWeight.w700,
                    color: AppColors.red,
                  ),
                ),
                SizedBox(height: R.sp(context, 2)),
                Text(
                  'Price: ₹${product.sellingPrice.toStringAsFixed(0)}',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: R.fs(context, 10),
                  ),
                ),
              ],
            ),
            SizedBox(width: R.sp(context, 4)),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: R.icon(context, 18),
            ),
          ],
        ),
      ),
    );
  }
}