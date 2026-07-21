import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'add_product_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../data/models/product_model.dart';
import '../providers/product_provider.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  late Product currentProduct;

  @override
  void initState() {
    super.initState();
    currentProduct = widget.product;
  }

  Future<void> refreshProduct() async {
    final notifier = ref.read(productListProvider.notifier);
    await notifier.refresh();
    final state = ref.read(productListProvider);
    final freshMatch = state.items.firstWhere(
      (element) => element.id == currentProduct.id,
      orElse: () => currentProduct,
    );
    if (mounted) {
      setState(() {
        currentProduct = freshMatch;
      });
    }
  }

  void _showUpdateStockDialog() {
    final TextEditingController stockController = TextEditingController(text: "1");
    bool isAdding = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              title: Text(
                "Update Stock",
                style: AppTextStyles.sectionTitle.copyWith(color: AppColors.textPrimaryDark),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Current Stock: ${currentProduct.quantity}",
                    style: AppTextStyles.cardValue,
                  ),
                  SizedBox(height: R.sp(context, AppSpacing.lg)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => setDialogState(() => isAdding = false),
                        icon: Icon(
                          Icons.remove_circle,
                          color: !isAdding ? AppColors.red : Colors.grey,
                          size: R.icon(context, 40),
                        ),
                      ),
                      SizedBox(width: R.sp(context, AppSpacing.sm)),
                      SizedBox(
                        width: 80,
                        height: AppSizes.inputHeight,
                        child: TextField(
                          controller: stockController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.cardValue,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      SizedBox(width: R.sp(context, AppSpacing.sm)),
                      IconButton(
                        onPressed: () => setDialogState(() => isAdding = true),
                        icon: Icon(
                          Icons.add_circle,
                          color: isAdding ? AppColors.green : Colors.grey,
                          size: R.icon(context, 40),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: R.sp(context, AppSpacing.md)),
                  Text(
                    isAdding ? "Action: Add to Stock" : "Action: Remove from Stock",
                    style: AppTextStyles.small.copyWith(
                      color: isAdding ? AppColors.green : AppColors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: AppTextStyles.button.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    int amount = int.tryParse(stockController.text) ?? 0;
                    if (amount > 0 && currentProduct.id != null) {
                      int finalChange = isAdding ? amount : -amount;

                      final mutatedStockProduct = Product(
                        id: currentProduct.id,
                        name: currentProduct.name,
                        category: currentProduct.category,
                        hsnCode: currentProduct.hsnCode,
                        purchasePrice: currentProduct.purchasePrice,
                        sellingPrice: currentProduct.sellingPrice,
                        quantity: currentProduct.quantity + finalChange,
                        unit: currentProduct.unit,
                        description: currentProduct.description,
                        imagePath: currentProduct.imagePath,
                        barcode: currentProduct.barcode,
                        sgst: currentProduct.sgst,
                        cgst: currentProduct.cgst,
                        discount: currentProduct.discount,
                        expiryDate: currentProduct.expiryDate,
                        supplier: currentProduct.supplier,
                        lsl: currentProduct.lsl,
                      );

                      final success = await ref.read(productOperationsProvider.notifier).modifyProduct(mutatedStockProduct);
                      if (success) {
                        await refreshProduct();
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Stock Updated Successfully")),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                  ),
                  child: Text("Update", style: AppTextStyles.button),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
          title: Text("Delete Product", style: AppTextStyles.sectionTitle.copyWith(color: AppColors.textPrimaryDark)),
          content: Text(
            "Are you sure you want to delete ${currentProduct.name}? This action cannot be undone.",
            style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel", style: AppTextStyles.button.copyWith(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text("Delete", style: AppTextStyles.button.copyWith(color: AppColors.textWhite)),
            ),
          ],
        );
      },
    );

    if (confirm == true && currentProduct.id != null) {
      final softDone = await ref.read(productOperationsProvider.notifier).deleteProduct(currentProduct.id!);
      if (softDone && mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final qty = currentProduct.quantity;
    final bool isOut = qty == 0;
    final bool isLow = !isOut && qty <= currentProduct.lsl;
    final String status = isOut ? "Out of Stock" : isLow ? "Low Stock" : "In Stock";
    final Color statusColor = isOut ? AppColors.red : isLow ? AppColors.orange : AppColors.green;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimaryDark),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          "Product Details",
          style: AppTextStyles.sectionTitle.copyWith(color: AppColors.textPrimaryDark),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.red),
            onPressed: _confirmDelete,
          ),
          SizedBox(width: R.sp(context, AppSpacing.xs)),
        ],
      ),
      body: SafeArea(
        child: R.maxW(
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              R.sp(context, AppSpacing.screenPadding),
              R.sp(context, AppSpacing.lg),
              R.sp(context, AppSpacing.screenPadding),
              R.sp(context, AppSpacing.sectionGap),
            ),
            child: Column(
              children: [
                // Photo
Hero(
  tag: 'product_${currentProduct.id}',
  child: ClipRRect(
    borderRadius: BorderRadius.circular(
      R.radius(context, AppSizes.radiusLg),
    ),
    child: Container(
      width: double.infinity,
      height: R.fluid(context, 220, 280),
      color: AppColors.surface2,
      child: currentProduct.imagePath.isNotEmpty
          ? (currentProduct.imagePath.startsWith('http')
              ? CachedNetworkImage(
                  imageUrl: currentProduct.imagePath,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (_, __, ___) => Icon(
                    Icons.broken_image,
                    size: R.icon(context, 60),
                    color: Colors.grey,
                  ),
                )
              : Image.file(
                  File(currentProduct.imagePath),
                  fit: BoxFit.cover,
                ))
          : Icon(
              Icons.image_outlined,
              size: R.icon(context, 90),
              color: AppColors.textSecondary,
            ),
    ),
  ),
),
                SizedBox(height: R.sp(context, AppSpacing.md)),

                // Name + category
                Text(
                  currentProduct.name,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: R.sp(context, 4)),
                Text(
                  currentProduct.category,
                  style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
                ),
                SizedBox(height: R.sp(context, AppSpacing.lg)),

                // Price / Stock / Status summary strip
                Container(
                  padding: EdgeInsets.symmetric(vertical: R.sp(context, AppSpacing.md)),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(R.radius(context, AppSizes.cardRadius)),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _summaryCell(
                          label: "Selling Price",
                          value: "₹${currentProduct.sellingPrice.toStringAsFixed(0)}",
                        ),
                      ),
                      _verticalDivider(),
                      Expanded(
                        child: _summaryCell(
                          label: "Stock",
                          value: "$qty ${currentProduct.unit}",
                        ),
                      ),
                      _verticalDivider(),
                      Expanded(
                        child: _summaryCell(
                          label: "Status",
                          value: status,
                          valueColor: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: R.sp(context, AppSpacing.md)),

                // Update stock + Edit, same row
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: R.sp(context, AppSizes.buttonHeight),
                        child: OutlinedButton.icon(
                          onPressed: _showUpdateStockDialog,
                          icon: Icon(Icons.inventory_2_outlined, size: R.icon(context, AppSizes.iconMd), color: AppColors.primary),
                          label: Text("Update Stock", style: AppTextStyles.button.copyWith(color: AppColors.primary)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusMd))),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: R.sp(context, AppSpacing.sm)),
                    SizedBox(
                      width: R.sp(context, AppSizes.buttonHeight),
                      height: R.sp(context, AppSizes.buttonHeight),
                      child: OutlinedButton(
                        onPressed: () async {
                          final checkDone = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AddProductScreen(product: currentProduct)),
                          );
                          if (checkDone == true) {
                            await refreshProduct();
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusMd))),
                        ),
                        child: Icon(Icons.edit_outlined, size: R.icon(context, AppSizes.iconMd), color: AppColors.textPrimaryDark),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: R.sp(context, AppSpacing.xl)),

                // Details card
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Product Information",
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: AppColors.textPrimaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: R.sp(context, AppSpacing.sm)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: R.sp(context, AppSpacing.cardPadding)),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(R.radius(context, AppSizes.cardRadius)),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Column(
                    children: [
_infoRow("Category", currentProduct.category),
_infoRow("HSN Code", currentProduct.hsnCode),
_infoRow("Product Code", currentProduct.barcode),
_infoRow("Purchase Price", "₹${currentProduct.purchasePrice.toStringAsFixed(0)}"),
_infoRow("Quantity", "$qty"),
_infoRow("Unit", currentProduct.unit),
_infoRow("Supplier", currentProduct.supplier),
_infoRow("Expiry Date", currentProduct.expiryDate),
_infoRow("Description", currentProduct.description, isLast: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCell({required String label, required String value, Color? valueColor}) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.small.copyWith(color: AppColors.textSecondary)),
        SizedBox(height: R.sp(context, 4)),
        Text(
          value,
          style: AppTextStyles.cardValue.copyWith(
            color: valueColor ?? AppColors.textPrimaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: R.sp(context, 32),
      color: AppColors.border,
    );
  }

  Widget _infoRow(String title, dynamic value, {bool isLast = false}) {
    final displayValue = (value == null || value.toString().trim().isEmpty) ? "-" : value.toString();
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: R.sp(context, AppSpacing.md)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Text(title, style: AppTextStyles.small.copyWith(color: AppColors.textSecondary)),
              ),
              Expanded(
                flex: 5,
                child: Text(
                  displayValue,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.cardValue.copyWith(color: AppColors.textPrimaryDark),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: AppColors.border.withValues(alpha: 0.6)),
      ],
    );
  }
}