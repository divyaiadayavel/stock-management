import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'scanner_bill_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/billing_provider.dart';
import 'current_bill_screen.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../products/presentation/providers/product_provider.dart';

final searchProductProvider = StateProvider<String>((ref) => "");

class AddProductBillScreen extends ConsumerStatefulWidget {
  const AddProductBillScreen({super.key});

  @override
  ConsumerState<AddProductBillScreen> createState() =>
      _AddProductBillScreenState();
}

class _AddProductBillScreenState extends ConsumerState<AddProductBillScreen> {
  bool isAscending = true;
  String selectedCategory = "All";

  final List<String> categories = [
    "Electronics",
    "Mobile",
    "Accessories",
    "Fashion",
    "Grocery",
    "Stationery",
    "Food",
    "Beauty",
    "Furniture",
    "Medical",
    "Sports",
    "Hardware",
    "Home Appliances",
    "Books",
    "Toys",
    "Footwear",
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(productListProvider.notifier).loadProducts();
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.red : AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingProvider);
    final search = ref.watch(searchProductProvider);

    final productState = ref.watch(productListProvider);
    final products = productState.items;
    final isLoading = productState.isInitialLoading;

    final filteredProducts = products.where((product) {
      final searchLower = search.toLowerCase();
      final searchMatch =
          product.name.toLowerCase().contains(searchLower) ||
          (product.barcode?.toLowerCase().contains(searchLower) ?? false);
      final categoryMatch =
          selectedCategory == "All" || product.category == selectedCategory;
      return searchMatch && categoryMatch;
    }).toList();

    filteredProducts.sort((a, b) {
      final nameA = a.name;
      final nameB = b.name;
      return isAscending ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
    });

    final showLoading = isLoading && products.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: R.sp(context, AppSpacing.screenPadding / 2),
                vertical: R.sp(context, AppSpacing.sm),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimaryDark,
                      size: R.icon(context, AppSizes.iconLg),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: R.sp(context, AppSpacing.xs)),
                  Text("Add Product Bill", style: AppTextStyles.heading),
                ],
              ),
            ),

            Expanded(
              child: showLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(
                        R.sp(context, AppSpacing.screenPadding),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Search & Scanner ──
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: AppSizes.inputHeight + 8,
                                  child: TextField(
                                    onChanged: (value) {
                                      ref
                                              .read(
                                                searchProductProvider.notifier,
                                              )
                                              .state =
                                          value;
                                    },
                                    decoration: InputDecoration(
                                      hintText: "Search product / barcode",
                                      hintStyle: AppTextStyles.small,
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        color: AppColors.textSecondary,
                                      ),
                                      filled: true,
                                      fillColor: AppColors.card,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 0,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppSizes.radiusLg,
                                        ),
                                        borderSide: const BorderSide(
                                          color: AppColors.border,
                                          width: 1,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppSizes.radiusLg,
                                        ),
                                        borderSide: const BorderSide(
                                          color: AppColors.border,
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppSizes.radiusLg,
                                        ),
                                        borderSide: const BorderSide(
                                          color: AppColors.cyan,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: R.sp(context, AppSpacing.md)),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ScannerBillScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  height: AppSizes.inputHeight + 8,
                                  width: AppSizes.inputHeight + 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusLg,
                                    ),
                                    border: Border.all(
                                      color: AppColors.border,
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.qr_code_scanner,
                                    color: AppColors.cyanDim,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(
                            height: R.sp(context, AppSpacing.sectionGap),
                          ),

                          // ── Category Chips ──
                          SizedBox(
                            height: R.searchH(context) - 8,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: categories.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) return _categoryChip("All");
                                return _categoryChip(categories[index - 1]);
                              },
                            ),
                          ),

                          SizedBox(
                            height: R.sp(context, AppSpacing.sectionGap),
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "All Products",
                                style: AppTextStyles.sectionTitle.copyWith(
                                  color: AppColors.textPrimaryDark,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    isAscending = !isAscending;
                                  });
                                },
                                child: Text(
                                  isAscending ? "A-Z" : "Z-A",
                                  style: AppTextStyles.button.copyWith(
                                    color: AppColors.cyanDim,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: R.sp(context, AppSpacing.md)),

                          // ── Product List ──
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              if (product.id == null)
                                return const SizedBox.shrink();

                              final isOutOfStock = product.quantity <= 0;

                              return Container(
                                margin: EdgeInsets.only(
                                  bottom: R.sp(context, AppSpacing.sm),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: R.sp(context, AppSpacing.md),
                                  vertical: R.sp(context, AppSpacing.md),
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusLg,
                                  ),
                                  border: Border.all(
                                    color: isOutOfStock
                                        ? AppColors.red.withOpacity(0.3)
                                        : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // ── Left: Product Info ──
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            product.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.cardValue
                                                .copyWith(
                                                  fontSize: R.fs(context, 13.5),
                                                  color: isOutOfStock
                                                      ? AppColors.textSecondary
                                                      : AppColors
                                                            .textPrimaryDark,
                                                ),
                                          ),
                                          SizedBox(
                                            height: R.sp(
                                              context,
                                              AppSpacing.xs,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              _metaChip(
                                                context: context,
                                                label: "Price",
                                                value:
                                                    "₹${product.sellingPrice}",
                                                valueColor:
                                                    AppColors.textPrimaryDark,
                                              ),
                                              SizedBox(
                                                width: R.sp(
                                                  context,
                                                  AppSpacing.md,
                                                ),
                                              ),
                                              _metaChip(
                                                context: context,
                                                label: "Disc",
                                                value: "${product.discount}%",
                                                valueColor: AppColors.green,
                                              ),
                                              SizedBox(
                                                width: R.sp(
                                                  context,
                                                  AppSpacing.md,
                                                ),
                                              ),
                                              _metaChip(
                                                context: context,
                                                label: "Stock",
                                                value: "${product.quantity}",
                                                valueColor: isOutOfStock
                                                    ? AppColors.red
                                                    : AppColors.cyanDim,
                                              ),
                                            ],
                                          ),
                                          if (isOutOfStock) ...[
                                            SizedBox(
                                              height: R.sp(
                                                context,
                                                AppSpacing.xs,
                                              ),
                                            ),
                                            Text(
                                              "⚠️ Out of Stock",
                                              style: AppTextStyles.small
                                                  .copyWith(
                                                    color: AppColors.red,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    // ── Right: Add / Qty Controls ──
                                    SizedBox(
                                      width: R.isDesktop(context)
                                          ? 180
                                          : R.isTablet(context)
                                          ? 160
                                          : 130,
                                      child: Consumer(
                                        builder: (context, ref, child) {
                                          final billingState = ref.watch(
                                            billingProvider,
                                          );
                                          final existingIndex = billingState
                                              .cart
                                              .indexWhere(
                                                (e) =>
                                                    e.productId == product.id,
                                              );

                                          // ── Not in cart ──
                                          if (existingIndex == -1) {
                                            return Align(
                                              alignment: Alignment.centerRight,
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppSizes.radiusMd,
                                                    ),
                                                onTap: isOutOfStock
                                                    ? null
                                                    : () {
                                                        ref
                                                            .read(
                                                              billingProvider
                                                                  .notifier,
                                                            )
                                                            .addProduct(
                                                              product,
                                                            );
                                                      },
                                                child: Container(
                                                  height: 34,
                                                  width: 34,
                                                  decoration: BoxDecoration(
                                                    gradient: isOutOfStock
                                                        ? null
                                                        : AppColors
                                                              .brandGradient,
                                                    color: isOutOfStock
                                                        ? AppColors.surface2
                                                        : null,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          AppSizes.radiusMd,
                                                        ),
                                                    border: isOutOfStock
                                                        ? Border.all(
                                                            color: AppColors
                                                                .border,
                                                          )
                                                        : null,
                                                  ),
                                                  child: Icon(
                                                    Icons.add,
                                                    color: isOutOfStock
                                                        ? AppColors
                                                              .textSecondary
                                                        : Colors.white,
                                                    size: 19,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }

                                          // ── Already in cart ──
                                          final item =
                                              billingState.cart[existingIndex];
                                          final availableStock =
                                              product.quantity;

                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  height: R.btnH(context) - 16,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: AppColors.cyanDim
                                                          .withOpacity(0.4),
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          AppSizes.radiusMd,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      // MINUS
                                                      Expanded(
                                                        child: InkWell(
                                                          borderRadius: const BorderRadius.only(
                                                            topLeft:
                                                                Radius.circular(
                                                                  AppSizes
                                                                      .radiusMd,
                                                                ),
                                                            bottomLeft:
                                                                Radius.circular(
                                                                  AppSizes
                                                                      .radiusMd,
                                                                ),
                                                          ),
                                                          onTap: () {
                                                            ref
                                                                .read(
                                                                  billingProvider
                                                                      .notifier,
                                                                )
                                                                .decreaseQty(
                                                                  product.id!,
                                                                );
                                                          },
                                                          child: Container(
                                                            height: 34,
                                                            decoration: const BoxDecoration(
                                                              color: AppColors
                                                                  .surface2,
                                                              borderRadius: BorderRadius.only(
                                                                topLeft:
                                                                    Radius.circular(
                                                                      AppSizes
                                                                          .radiusMd,
                                                                    ),
                                                                bottomLeft:
                                                                    Radius.circular(
                                                                      AppSizes
                                                                          .radiusMd,
                                                                    ),
                                                              ),
                                                            ),
                                                            child: const Icon(
                                                              Icons.remove,
                                                              color: AppColors
                                                                  .cyanDim,
                                                              size: 15,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      // Divider
                                                      Container(
                                                        width: 1,
                                                        height: 34,
                                                        color: AppColors.cyanDim
                                                            .withOpacity(0.25),
                                                      ),
                                                      // QTY INPUT
                                                      Expanded(
                                                        child: SizedBox(
                                                          height: 34,
                                                          child: TextFormField(
                                                            key: ValueKey(
                                                              item.qty,
                                                            ),
                                                            initialValue: item
                                                                .qty
                                                                .toString(),
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: AppTextStyles
                                                                .cardValue
                                                                .copyWith(
                                                                  fontSize: 13,
                                                                  height: 1.2,
                                                                ),
                                                            decoration: const InputDecoration(
                                                              filled: true,
                                                              fillColor:
                                                                  Colors.white,
                                                              border:
                                                                  InputBorder
                                                                      .none,
                                                              isDense: true,
                                                              contentPadding:
                                                                  EdgeInsets.symmetric(
                                                                    vertical: 8,
                                                                  ),
                                                            ),
                                                            onFieldSubmitted: (value) {
                                                              int? newQty =
                                                                  int.tryParse(
                                                                    value,
                                                                  );
                                                              if (newQty ==
                                                                      null ||
                                                                  newQty <= 0) {
                                                                return;
                                                              }
                                                              if (newQty >
                                                                  availableStock) {
                                                                newQty =
                                                                    availableStock;
                                                                _showSnackBar(
                                                                  'Only $availableStock items available',
                                                                  isError: true,
                                                                );
                                                              }
                                                              ref
                                                                  .read(
                                                                    billingProvider
                                                                        .notifier,
                                                                  )
                                                                  .updateQty(
                                                                    product.id!,
                                                                    newQty,
                                                                  );
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                      // Divider
                                                      Container(
                                                        width: 1,
                                                        height: 34,
                                                        color: AppColors.cyanDim
                                                            .withOpacity(0.25),
                                                      ),
                                                      // PLUS
                                                      Expanded(
                                                        child: InkWell(
                                                          borderRadius: const BorderRadius.only(
                                                            topRight:
                                                                Radius.circular(
                                                                  AppSizes
                                                                      .radiusMd,
                                                                ),
                                                            bottomRight:
                                                                Radius.circular(
                                                                  AppSizes
                                                                      .radiusMd,
                                                                ),
                                                          ),
                                                          onTap: () {
                                                            if (item.qty >=
                                                                availableStock) {
                                                              _showSnackBar(
                                                                'Only $availableStock items available',
                                                                isError: true,
                                                              );
                                                              return;
                                                            }
                                                            ref
                                                                .read(
                                                                  billingProvider
                                                                      .notifier,
                                                                )
                                                                .increaseQty(
                                                                  product.id!,
                                                                );
                                                          },
                                                          child: Container(
                                                            height: 34,
                                                            decoration: const BoxDecoration(
                                                              color: AppColors
                                                                  .surface2,
                                                              borderRadius: BorderRadius.only(
                                                                topRight:
                                                                    Radius.circular(
                                                                      AppSizes
                                                                          .radiusMd,
                                                                    ),
                                                                bottomRight:
                                                                    Radius.circular(
                                                                      AppSizes
                                                                          .radiusMd,
                                                                    ),
                                                              ),
                                                            ),
                                                            child: const Icon(
                                                              Icons.add,
                                                              color: AppColors
                                                                  .cyanDim,
                                                              size: 15,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: R.sp(
                                                  context,
                                                  AppSpacing.sm,
                                                ),
                                              ),
                                              // DELETE
                                              InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppSizes.radiusSm,
                                                    ),
                                                onTap: () async {
                                                  final confirm = await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              AppSizes.radiusLg,
                                                            ),
                                                      ),
                                                      title: Text(
                                                        "Delete Product",
                                                        style: AppTextStyles
                                                            .sectionTitle
                                                            .copyWith(
                                                              color: AppColors
                                                                  .textPrimaryDark,
                                                            ),
                                                      ),
                                                      content: Text(
                                                        "Are you sure you want to delete this product?",
                                                        style:
                                                            AppTextStyles.small,
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                context,
                                                                false,
                                                              ),
                                                          child: const Text(
                                                            "Cancel",
                                                          ),
                                                        ),
                                                        ElevatedButton(
                                                          style:
                                                              ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    AppColors
                                                                        .red,
                                                              ),
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                context,
                                                                true,
                                                              ),
                                                          child: Text(
                                                            "Delete",
                                                            style: AppTextStyles
                                                                .button
                                                                .copyWith(
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  if (confirm == true) {
                                                    ref
                                                        .read(
                                                          billingProvider
                                                              .notifier,
                                                        )
                                                        .removeProduct(
                                                          product.id!,
                                                        );
                                                  }
                                                },
                                                child: const Icon(
                                                  Icons.delete_outline,
                                                  color: AppColors.red,
                                                  size: 20,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: EdgeInsets.all(R.sp(context, AppSpacing.md)),
          height: R.btnH(context) + 10,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(width: R.sp(context, AppSpacing.lg)),
              Stack(
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        billingState.cart.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: R.sp(context, AppSpacing.md)),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${billingState.cart.length} Items",
                      style: AppTextStyles.small.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      "₹ ${billingState.grandTotal.toStringAsFixed(2)}",
                      style: AppTextStyles.cardValue.copyWith(
                        color: Colors.white,
                        fontSize: R.fs(context, 20),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: R.sp(context, AppSpacing.md)),
                child: SizedBox(
                  height: R.btnH(context) - 12,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.cyanDim,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                    ),
                    onPressed: () {
                      if (billingState.cart.isEmpty) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CurrentBillScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "View Bill",
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.cyanDim,
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

  Widget _categoryChip(String title) {
    final isSelected = selectedCategory == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = title;
        });
      },
      child: Container(
        margin: EdgeInsets.only(right: R.sp(context, AppSpacing.sm)),
        padding: EdgeInsets.symmetric(
          horizontal: R.sp(context, 14),
          vertical: R.sp(context, 10),
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.brandGradient : null,
          color: isSelected ? null : AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.border,
          ),
        ),
        child: Text(
          title,
          style: AppTextStyles.button.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimaryDark,
            fontSize: R.fs(context, 12),
          ),
        ),
      ),
    );
  }

  Widget _metaChip({
    required BuildContext context,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.small.copyWith(fontSize: R.fs(context, 10)),
        ),
        Text(
          value,
          style: AppTextStyles.cardValue.copyWith(
            color: valueColor,
            fontSize: R.fs(context, 12),
          ),
        ),
      ],
    );
  }
}
