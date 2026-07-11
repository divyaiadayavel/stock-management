// =========================================================
// lib/features/inventory/presentation/screens/stock_screen.dart
// =========================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../providers/inventory_providers.dart';
import 'product_detail_screen.dart';

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _searchOpen = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(inventorySummaryProvider);
    final productsAsync = ref.watch(productsListProvider);
    final activeFilter = ref.watch(inventoryFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(R.sp(context, 56)),
        child: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          automaticallyImplyLeading: true,
          titleSpacing: R.sp(context, AppSpacing.screenPadding),
          title: _searchOpen
              ? TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  style: AppTextStyles.cardValue,
                  decoration: const InputDecoration(
                    hintText: 'Search product, SKU, barcode…',
                    border: InputBorder.none,
                  ),
                  onChanged: (v) =>
                      ref.read(inventorySearchProvider.notifier).state = v,
                )
              : Text('Stock', style: AppTextStyles.heading),
          actions: [
            IconButton(
              icon: Icon(
                _searchOpen ? Icons.close : Icons.search,
                color: AppColors.textSecondary,
                size: R.icon(context, AppSizes.iconLg),
              ),
              onPressed: () {
                setState(() {
                  _searchOpen = !_searchOpen;
                  if (!_searchOpen) {
                    _searchCtrl.clear();
                    ref.read(inventorySearchProvider.notifier).state = '';
                  }
                });
              },
            ),
            IconButton(
              icon: Icon(
                Icons.swap_vert,
                color: AppColors.textPrimaryDark,
                size: R.icon(context, AppSizes.iconLg),
              ),
              onPressed: () => _showSortSheet(context),
            ),
            SizedBox(width: R.sp(context, AppSpacing.sm)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: R.sp(context, AppSpacing.screenPadding),
              vertical: R.sp(context, AppSpacing.sm),
            ),
            child: summaryAsync.when(
              data: (summary) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _FilterChip(
                    label: 'All ${summary['all']}',
                    value: 'all',
                    selected: activeFilter == 'all',
                  ),
                  _FilterChip(
                    label: 'Low ${summary['low']}',
                    value: 'low',
                    selected: activeFilter == 'low',
                  ),
                  _FilterChip(
                    label: 'Out ${summary['out']}',
                    value: 'out',
                    selected: activeFilter == 'out',
                  ),
                  _FilterChip(
                    label: 'Expiring ${summary['expiring']}',
                    value: 'expiring',
                    selected: activeFilter == 'expiring',
                  ),
                ],
              ),
              loading: () => SizedBox(
                height: R.sp(context, AppSpacing.xxl),
                child: Center(
                  child: SizedBox(
                    width: R.sp(context, AppSizes.iconMd),
                    height: R.sp(context, AppSizes.iconMd),
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (e, st) => Text('Error: $e', style: AppTextStyles.small),
            ),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Text(
                      'No products found',
                      style: AppTextStyles.subHeading,
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => refreshInventory(ref),
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      R.sp(context, AppSpacing.screenPadding),
                      0,
                      R.sp(context, AppSpacing.screenPadding),
                      R.sp(context, 90),
                    ),
                    itemCount: products.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: R.sp(context, AppSpacing.sm)),
                    itemBuilder: (context, i) =>
                        _ProductTile(product: products[i]),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) =>
                  Center(child: Text('Error: $e', style: AppTextStyles.small)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    final currentSort = this.ref.read(inventorySortProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(R.radius(context, AppSizes.radiusLg)),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: R.sp(sheetContext, AppSpacing.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sort by', style: AppTextStyles.sectionTitle),
              SizedBox(height: R.sp(sheetContext, AppSpacing.sm)),
              ListTile(
                title: Text('Name (A–Z)', style: AppTextStyles.cardValue),
                trailing: currentSort == 'name_asc'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  this.ref.read(inventorySortProvider.notifier).state =
                      'name_asc';
                  this.ref.invalidate(productsListProvider);
                  Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                title: Text(
                  'Stock (Low → High)',
                  style: AppTextStyles.cardValue,
                ),
                trailing: currentSort == 'stock_asc'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  this.ref.read(inventorySortProvider.notifier).state =
                      'stock_asc';
                  this.ref.invalidate(productsListProvider);
                  Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                title: Text(
                  'Value (High → Low)',
                  style: AppTextStyles.cardValue,
                ),
                trailing: currentSort == 'value_desc'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  this.ref.read(inventorySortProvider.notifier).state =
                      'value_desc';
                  this.ref.invalidate(productsListProvider);
                  Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends ConsumerWidget {
  final String label;
  final String value;
  final bool selected;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(inventoryFilterProvider.notifier).state = value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: R.sp(context, AppSpacing.md + 2),
          vertical: R.sp(context, 6),
        ),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.brandGradient : null,
          color: selected ? null : AppColors.card,
          borderRadius: BorderRadius.circular(R.radius(context, 50)),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.small.copyWith(
            color: selected ? AppColors.textWhite : Colors.black,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: R.fs(context, 12),
          ),
        ),
      ),
    );
  }
}

class _ProductTile extends ConsumerWidget {
  final Map<String, dynamic> product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = (product['quantity'] as num?)?.toInt() ?? 0;
    final lsl = (product['lsl'] as num?)?.toInt() ?? 0;
    final unit = product['unit']?.toString() ?? '';
    final price = (product['selling_price'] as num?)?.toDouble() ?? 0.0;

    Color stockColor = AppColors.green;
    if (qty <= 0) {
      stockColor = AppColors.red;
    } else if (qty <= lsl) {
      stockColor = AppColors.orange;
    }

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
        refreshInventory(ref);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: R.sp(context, AppSpacing.cardPadding),
          vertical: R.sp(context, AppSpacing.cardPadding),
        ),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(
            R.radius(context, AppSizes.cardRadius),
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name']?.toString() ?? '',
                    style: AppTextStyles.cardValue.copyWith(
                      fontSize: R.fs(context, AppSizes.iconSm),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: R.sp(context, AppSpacing.xs)),
                  Text(
                    'SKU-${product['id']} · $unit',
                    style: AppTextStyles.small,
                  ),
                ],
              ),
            ),
            SizedBox(width: R.sp(context, AppSpacing.sm)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${price.toStringAsFixed(price >= 1000 ? 0 : 2)}',
                  style: AppTextStyles.cardValue,
                ),
                SizedBox(height: R.sp(context, AppSpacing.xs)),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.small,
                    children: [
                      const TextSpan(text: 'on-hand '),
                      TextSpan(
                        text: '$qty',
                        style: TextStyle(
                          color: stockColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(text: ' · reorder $lsl'),
                    ],
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
