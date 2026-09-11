// =========================================================
// lib/features/inventory/presentation/screens/stock_screen.dart
// =========================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/no_internet_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';

import '../providers/inventory_provider.dart';
import '../providers/inventory_filter_provider.dart';

import '../../../products/data/models/product_model.dart';

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
    final productsAsync = ref.watch(inventoryProductsProvider);

    final activeFilter = ref.watch(inventoryFilterProvider);
    final searchQuery = ref.watch(inventorySearchProvider);
    final currentSort = ref.watch(inventorySortProvider);

    if (productsAsync.hasError) {
      return Scaffold(
        body: NoInternetScreen(
          onRetry: () {
            ref.invalidate(inventoryProductsProvider);
            ref.invalidate(inventorySummaryProvider);
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          R.sp(context, 56),
        ),
        child: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: true,
          titleSpacing: R.sp(
            context,
            AppSpacing.screenPadding,
          ),

          title: _searchOpen
              ? TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  style: AppTextStyles.cardValue,
                  decoration: const InputDecoration(
                    hintText: 'Search products...',
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    ref
                        .read(
                          inventorySearchProvider.notifier,
                        )
                        .state = value;
                  },
                )
              : Text(
                  'Stock',
                  style: AppTextStyles.heading,
                ),

          actions: [
            IconButton(
              icon: Icon(
                _searchOpen
                    ? Icons.close
                    : Icons.search,
                color: AppColors.textSecondary,
                size: R.icon(
                  context,
                  AppSizes.iconLg,
                ),
              ),
              onPressed: () {
                setState(() {
                  _searchOpen = !_searchOpen;

                  if (!_searchOpen) {
                    _searchCtrl.clear();

                    ref
                        .read(
                          inventorySearchProvider.notifier,
                        )
                        .state = '';
                  }
                });
              },
            ),

            IconButton(
              icon: Icon(
                Icons.swap_vert,
                color: AppColors.textPrimaryDark,
                size: R.icon(
                  context,
                  AppSizes.iconLg,
                ),
              ),
              onPressed: () {
                _showSortSheet(context);
              },
            ),

            SizedBox(
              width: R.sp(
                context,
                AppSpacing.sm,
              ),
            ),
          ],
        ),
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: Column(
        children: [

          // =================================================
          // FILTER CHIPS + COUNTS
          // =================================================

          Padding(
            padding: EdgeInsets.symmetric(
              vertical: R.sp(
                context,
                AppSpacing.sm,
              ),
            ),

            child: summaryAsync.when(
              data: (summary) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,

                  padding: EdgeInsets.symmetric(
                    horizontal: R.sp(
                      context,
                      AppSpacing.screenPadding,
                    ),
                  ),

                  child: Row(
                    children: [

                      // -------------------------------------
                      // ALL
                      // -------------------------------------

                      _FilterChip(
                        label:
                            'All (${summary.totalProducts})',
                        value: 'all',
                        selected:
                            activeFilter == 'all',
                      ),

                      SizedBox(
                        width: R.sp(
                          context,
                          AppSpacing.xs,
                        ),
                      ),

                      // -------------------------------------
                      // LOW
                      // -------------------------------------

                      _FilterChip(
                        label:
                            'Low (${summary.lowStockProducts})',
                        value: 'low',
                        selected:
                            activeFilter == 'low',
                      ),

                      SizedBox(
                        width: R.sp(
                          context,
                          AppSpacing.xs,
                        ),
                      ),

                      // -------------------------------------
                      // OUT
                      // -------------------------------------

                      _FilterChip(
                        label:
                            'Out (${summary.outOfStockProducts})',
                        value: 'out',
                        selected:
                            activeFilter == 'out',
                      ),

                      SizedBox(
                        width: R.sp(
                          context,
                          AppSpacing.xs,
                        ),
                      ),

                      // -------------------------------------
                      // EXPIRING
                      // -------------------------------------

                      _FilterChip(
                        label:
                            'Expiring (${summary.expiringProducts})',
                        value: 'expiring',
                        selected:
                            activeFilter == 'expiring',
                      ),

                      SizedBox(
                        width: R.sp(
                          context,
                          AppSpacing.xs,
                        ),
                      ),

                      // -------------------------------------
                      // EXPIRED
                      // -------------------------------------

                      _FilterChip(
                        label:
                            'Expired (${summary.expiredProducts})',
                        value: 'expired',
                        selected:
                            activeFilter == 'expired',
                      ),
                    ],
                  ),
                );
              },

              loading: () {
                return SizedBox(
                  height: R.sp(
                    context,
                    AppSpacing.xxl,
                  ),

                  child: Center(
                    child: SizedBox(
                      width: R.sp(
                        context,
                        AppSizes.iconMd,
                      ),
                      height: R.sp(
                        context,
                        AppSizes.iconMd,
                      ),
                      child:
                          const CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                );
              },

              error: (error, stack) {
                return SizedBox(
                  height: 70,

                  child: NoInternetScreen(
                    onRetry: () {
                      ref.invalidate(
                        inventorySummaryProvider,
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // =================================================
          // PRODUCT LIST
          // =================================================

          Expanded(
            child: productsAsync.when(

              // =============================================
              // DATA
              // =============================================

              data: (products) {

                /*
                 * IMPORTANT:
                 *
                 * Filtering is handled by the backend.
                 *
                 * The selected filter is sent through:
                 *
                 * inventoryFilterProvider
                 *        ↓
                 * inventoryProductsProvider
                 *        ↓
                 * GetInventoryStock
                 *        ↓
                 * Repository
                 *        ↓
                 * RemoteDataSource
                 *        ↓
                 * inventory.php
                 *
                 * Therefore DO NOT filter low/out/expiring/
                 * expired products again here.
                 */

                final filteredList =
                    List<Product>.from(products);

                // =========================================
                // SORTING
                // =========================================

                switch (currentSort) {

                  case 'Name (A–Z)':
                  case 'name_asc':

                    filteredList.sort(
                      (a, b) => a.name
                          .toLowerCase()
                          .compareTo(
                            b.name.toLowerCase(),
                          ),
                    );

                    break;

                  case 'Stock (Low → High)':
                  case 'stock_asc':

                    filteredList.sort(
                      (a, b) => a.quantity.compareTo(
                        b.quantity,
                      ),
                    );

                    break;

                  case 'Price (High → Low)':
                  case 'Value (High → Low)':
                  case 'value_desc':
                  case 'price_high_low':

                    filteredList.sort(
                      (a, b) {

                        final priceA =
                            a.sellingPrice;

                        final priceB =
                            b.sellingPrice;

                        if (priceB > priceA) {
                          return 1;
                        }

                        if (priceB < priceA) {
                          return -1;
                        }

                        return a.name
                            .toLowerCase()
                            .compareTo(
                              b.name.toLowerCase(),
                            );
                      },
                    );

                    break;

                  default:

                    filteredList.sort(
                      (a, b) => a.name
                          .toLowerCase()
                          .compareTo(
                            b.name.toLowerCase(),
                          ),
                    );
                }

                // =========================================
                // EMPTY
                // =========================================

                if (filteredList.isEmpty) {
                  return Center(
                    child: Text(
                      _emptyMessage(activeFilter),
                      style: AppTextStyles.subHeading,
                    ),
                  );
                }

                // =========================================
                // LIST
                // =========================================

                return RefreshIndicator(
                  onRefresh: () async {

                    ref.invalidate(
                      inventorySummaryProvider,
                    );

                    ref.invalidate(
                      inventoryProductsProvider,
                    );

                    /*
                     * Wait for the inventory list provider
                     * so RefreshIndicator doesn't complete
                     * before the request finishes.
                     */

                    await ref.read(
                      inventoryProductsProvider.future,
                    );
                  },

                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      R.sp(
                        context,
                        AppSpacing.screenPadding,
                      ),
                      0,
                      R.sp(
                        context,
                        AppSpacing.screenPadding,
                      ),
                      R.sp(
                        context,
                        90,
                      ),
                    ),

                    itemCount:
                        filteredList.length,

                    separatorBuilder: (_, __) =>
                        SizedBox(
                      height: R.sp(
                        context,
                        AppSpacing.sm,
                      ),
                    ),

                    itemBuilder: (context, index) {

                      final product =
                          filteredList[index];

                      return _ProductTile(
                        product: product,
                        searchQuery: searchQuery,
                      );
                    },
                  ),
                );
              },

              // =============================================
              // LOADING
              // =============================================

              loading: () {
                return const Center(
                  child:
                      CircularProgressIndicator(),
                );
              },

              // =============================================
              // ERROR
              // =============================================

              error: (error, stack) {
                return NoInternetScreen(
                  onRetry: () {
                    ref.invalidate(
                      inventoryProductsProvider,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // EMPTY MESSAGE
  // =========================================================

  String _emptyMessage(
    String filter,
  ) {
    switch (filter) {

      case 'low':
        return 'No low stock products';

      case 'out':
        return 'No out-of-stock products';

      case 'expiring':
        return 'No products expiring within 30 days';

      case 'expired':
        return 'No expired products';

      default:
        return 'No products found';
    }
  }

  // =========================================================
  // SORT SHEET
  // =========================================================

  void _showSortSheet(
    BuildContext context,
  ) {
    final currentSort =
        ref.read(inventorySortProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(
            R.radius(
              context,
              AppSizes.radiusLg,
            ),
          ),
        ),
      ),

      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: R.sp(
                sheetContext,
                AppSpacing.lg,
              ),
            ),

            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              children: [

                Text(
                  'Sort by',
                  style:
                      AppTextStyles.sectionTitle,
                ),

                SizedBox(
                  height: R.sp(
                    sheetContext,
                    AppSpacing.sm,
                  ),
                ),

                // -----------------------------------------
                // NAME
                // -----------------------------------------

                ListTile(
                  title: Text(
                    'Name (A–Z)',
                    style:
                        AppTextStyles.cardValue,
                  ),

                  trailing:
                      (
                        currentSort ==
                            'name_asc' ||
                        currentSort ==
                            'Name (A–Z)'
                      )
                          ? const Icon(
                              Icons.check,
                              color:
                                  AppColors.primary,
                            )
                          : null,

                  onTap: () {

                    ref
                        .read(
                          inventorySortProvider
                              .notifier,
                        )
                        .state = 'name_asc';

                    ref.invalidate(
                      inventoryProductsProvider,
                    );

                    Navigator.pop(
                      sheetContext,
                    );
                  },
                ),

                // -----------------------------------------
                // STOCK
                // -----------------------------------------

                ListTile(
                  title: Text(
                    'Stock (Low → High)',
                    style:
                        AppTextStyles.cardValue,
                  ),

                  trailing:
                      (
                        currentSort ==
                            'stock_asc' ||
                        currentSort ==
                            'Stock (Low → High)'
                      )
                          ? const Icon(
                              Icons.check,
                              color:
                                  AppColors.primary,
                            )
                          : null,

                  onTap: () {

                    ref
                        .read(
                          inventorySortProvider
                              .notifier,
                        )
                        .state = 'stock_asc';

                    ref.invalidate(
                      inventoryProductsProvider,
                    );

                    Navigator.pop(
                      sheetContext,
                    );
                  },
                ),

                // -----------------------------------------
                // PRICE
                // -----------------------------------------

                ListTile(
                  title: Text(
                    'Price (High → Low)',
                    style:
                        AppTextStyles.cardValue,
                  ),

                  trailing:
                      (
                        currentSort ==
                            'value_desc' ||
                        currentSort ==
                            'Price (High → Low)'
                      )
                          ? const Icon(
                              Icons.check,
                              color:
                                  AppColors.primary,
                            )
                          : null,

                  onTap: () {

                    ref
                        .read(
                          inventorySortProvider
                              .notifier,
                        )
                        .state = 'value_desc';

                    ref.invalidate(
                      inventoryProductsProvider,
                    );

                    Navigator.pop(
                      sheetContext,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


// ============================================================
// FILTER CHIP
// ============================================================

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
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {

    return GestureDetector(
      behavior:
          HitTestBehavior.opaque,

      onTap: () {

        ref
            .read(
              inventoryFilterProvider
                  .notifier,
            )
            .state = value;
      },

      child: Container(

        padding:
            EdgeInsets.symmetric(
          horizontal: R.sp(
            context,
            AppSpacing.md + 2,
          ),
          vertical: R.sp(
            context,
            6,
          ),
        ),

        decoration:
            BoxDecoration(
          gradient: selected
              ? AppColors.brandGradient
              : null,

          color: selected
              ? null
              : AppColors.card,

          borderRadius:
              BorderRadius.circular(
            R.radius(
              context,
              50,
            ),
          ),

          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppColors.border,
          ),
        ),

        child: Text(
          label,

          style:
              AppTextStyles.small.copyWith(
            color: selected
                ? AppColors.textWhite
                : Colors.black,

            fontWeight: selected
                ? FontWeight.w600
                : FontWeight.normal,

            fontSize: R.fs(
              context,
              12,
            ),
          ),
        ),
      ),
    );
  }
}


// ============================================================
// PRODUCT TILE
// ============================================================

class _ProductTile
    extends ConsumerWidget {

  final Product product;
  final String searchQuery;

  const _ProductTile({
    required this.product,
    required this.searchQuery,
  });

  String _capitalize(
    String text,
  ) {
    if (text.isEmpty) {
      return text;
    }

    return text
        .split(' ')
        .map((word) {

          if (word.isEmpty) {
            return word;
          }

          return word[0].toUpperCase() +
              word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {

    final qty =
        product.quantity;

    final lsl =
        product.lsl;

    final unit =
        product.unit;

    final price =
        product.sellingPrice;


    Color stockColor =
        AppColors.green;

    if (qty <= 0) {

      stockColor =
          AppColors.red;

    } else if (
        lsl > 0 &&
        qty <= lsl
    ) {

      stockColor =
          AppColors.orange;
    }


    return GestureDetector(

      onTap: () async {

        await Navigator.push(
          context,

          MaterialPageRoute(
            builder: (_) =>
                ProductDetailScreen(
              product: product,
            ),
          ),
        );

        ref.invalidate(
          inventoryProductsProvider,
        );

        ref.invalidate(
          inventorySummaryProvider,
        );
      },

      child: Container(

        padding:
            EdgeInsets.symmetric(
          horizontal: R.sp(
            context,
            AppSpacing.cardPadding,
          ),

          vertical: R.sp(
            context,
            AppSpacing.cardPadding,
          ),
        ),

        decoration:
            BoxDecoration(
          color:
              AppColors.card,

          borderRadius:
              BorderRadius.circular(
            R.radius(
              context,
              AppSizes.cardRadius,
            ),
          ),

          border: Border.all(
            color:
                AppColors.border,
          ),
        ),

        child: Row(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,

          children: [

            // =============================================
            // PRODUCT NAME
            // =============================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  _buildHighlightedName(
                    context,
                    _capitalize(
                      product.name,
                    ),
                    searchQuery,
                  ),

                  SizedBox(
                    height: R.sp(
                      context,
                      AppSpacing.xs,
                    ),
                  ),

                  Text(
                    'SKU-${product.id} · $unit',
                    style:
                        AppTextStyles.small,
                  ),
                ],
              ),
            ),

            SizedBox(
              width: R.sp(
                context,
                AppSpacing.sm,
              ),
            ),

            // =============================================
            // PRICE / STOCK
            // =============================================

            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,

              children: [

                Text(
                  '₹${price.toStringAsFixed(
                    price >= 1000 ? 0 : 2,
                  )}',

                  style:
                      AppTextStyles.cardValue,
                ),

                SizedBox(
                  height: R.sp(
                    context,
                    AppSpacing.xs,
                  ),
                ),

                RichText(
                  text: TextSpan(
                    style:
                        AppTextStyles.small,

                    children: [

                      const TextSpan(
                        text: 'on-hand ',
                      ),

                      TextSpan(
                        text: '$qty',

                        style: TextStyle(
                          color:
                              stockColor,

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      TextSpan(
                        text:
                            ' · reorder $lsl',
                      ),
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


  // =========================================================
  // SEARCH HIGHLIGHT
  // =========================================================

  Widget _buildHighlightedName(
    BuildContext context,
    String text,
    String query,
  ) {

    final baseStyle =
        AppTextStyles.cardValue.copyWith(
      fontSize: R.fs(
        context,
        AppSizes.iconSm,
      ),
    );


    if (query.isEmpty) {

      return Text(
        text,
        style: baseStyle,
        overflow:
            TextOverflow.ellipsis,
      );
    }


    final nameSpans =
        <TextSpan>[];

    final lowerName =
        text.toLowerCase();

    final lowerQuery =
        query.toLowerCase();


    int start = 0;


    while (true) {

      final found =
          lowerName.indexOf(
        lowerQuery,
        start,
      );

      if (found == -1) {
        break;
      }


      if (found > start) {

        nameSpans.add(
          TextSpan(
            text: text.substring(
              start,
              found,
            ),
            style: baseStyle,
          ),
        );
      }


      nameSpans.add(
        TextSpan(
          text: text.substring(
            found,
            found + query.length,
          ),

          style:
              baseStyle.copyWith(
            fontWeight:
                FontWeight.bold,

            color:
                AppColors.primary,
          ),
        ),
      );


      start =
          found + query.length;
    }


    if (start < text.length) {

      nameSpans.add(
        TextSpan(
          text:
              text.substring(start),
          style: baseStyle,
        ),
      );
    }


    return Text.rich(
      TextSpan(
        children: nameSpans,
      ),

      maxLines: 1,

      overflow:
          TextOverflow.ellipsis,
    );
  }
}