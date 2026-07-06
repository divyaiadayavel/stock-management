import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/storage/db_helper.dart'; // Ensure this path is correct
import 'add_product_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  // We use a local variable to hold the product data so we can update it
  late Map<String, dynamic> currentProduct;

  @override
  void initState() {
    super.initState();
    currentProduct = widget.product;
  }

  // 🔹 REFRESH LOGIC: Fetches the latest data from the DB
  Future<void> refreshProduct() async {
    final updatedData = await DBHelper.getProductById(currentProduct['id']);
    if (updatedData != null) {
      setState(() {
        currentProduct = updatedData;
      });
    }
  }

  // 🔹 UPDATE STOCK POPUP
  void _showUpdateStockDialog() {
    final TextEditingController stockController = TextEditingController(
      text: "1",
    );
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
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Current Stock: ${currentProduct['quantity']}",
                    style: AppTextStyles.cardValue,
                  ),
                  SizedBox(height: R.sp(context, AppSpacing.lg)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Minus Button
                      IconButton(
                        onPressed: () => setDialogState(() => isAdding = false),
                        icon: Icon(
                          Icons.remove_circle,
                          color: !isAdding ? AppColors.red : Colors.grey,
                          size: R.icon(context, 40),
                        ),
                      ),
                      SizedBox(width: R.sp(context, AppSpacing.sm)),
                      // Input Field
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
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMd,
                              ),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMd,
                              ),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      SizedBox(width: R.sp(context, AppSpacing.sm)),
                      // Plus Button
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
                    isAdding
                        ? "Action: Add to Stock"
                        : "Action: Remove from Stock",
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
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    int amount = int.tryParse(stockController.text) ?? 0;
                    if (amount > 0) {
                      int finalChange = isAdding ? amount : -amount;
                      await DBHelper.updateStockQuantity(
                        currentProduct['id'],
                        finalChange,
                      );
                      await refreshProduct(); // Refresh screen in real-time
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Stock Updated Successfully"),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
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

  @override
  Widget build(BuildContext context) {
    final qty = currentProduct["quantity"] ?? 0;

    String status = qty == 0
        ? "Out of Stock"
        : qty <= 15
        ? "Low Stock"
        : "In Stock";
    Color statusColor = qty == 0
        ? AppColors.red
        : qty <= 15
        ? AppColors.orange
        : AppColors.green;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: EdgeInsets.fromLTRB(
                R.sp(context, AppSpacing.screenPadding),
                R.sp(context, AppSpacing.lg),
                R.sp(context, AppSpacing.screenPadding),
                R.sp(context, AppSpacing.md),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimaryDark,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Product Details",
                        style: AppTextStyles.sectionTitle.copyWith(
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                    ),
                  ),
                  // Spacer to balance the center alignment with the back button
                  SizedBox(width: R.sp(context, 48)),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: R.maxW(
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    R.sp(context, AppSpacing.screenPadding),
                    R.sp(context, AppSpacing.sm),
                    R.sp(context, AppSpacing.screenPadding),
                    R.sp(context, AppSpacing.sectionGap),
                  ),
                  child: Column(
                    children: [
                      // ✅ Main Details Card
                      Container(
                        padding: EdgeInsets.all(
                          R.sp(context, AppSpacing.cardPadding),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(
                            R.radius(context, AppSizes.cardRadius),
                          ),
                          border: Border.all(color: AppColors.border, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.03),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusMd,
                                    ),
                                    child:
                                        currentProduct["image_path"] != null &&
                                            currentProduct["image_path"] != ""
                                        ? Image.file(
                                            File(currentProduct["image_path"]),
                                            height: R.fluid(context, 180, 320),
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            height: R.fluid(context, 180, 320),
                                            width: double.infinity,
                                            color: AppColors.surface2,
                                            child: Icon(
                                              Icons.image,
                                              size: R.icon(context, 50),
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                  ),
                                ),

                                SizedBox(height: R.sp(context, AppSpacing.xl)),

                                _rowItem(
                                  "Product Name",
                                  currentProduct["name"],
                                ),
                                _rowItem(
                                  "Category",
                                  currentProduct["category"],
                                ),
                                _rowItem(
                                  "Selling Price",
                                  "₹ ${currentProduct["selling_price"]}",
                                ),
                                _rowItem("Stock", "$qty Units"),
                                _rowItem(
                                  "Status",
                                  status,
                                  overrideColor: statusColor,
                                ),

                                SizedBox(height: R.sp(context, AppSpacing.xl)),

                                Row(
                                  children: [
                                    // EDIT
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AddProductScreen(
                                                    product: currentProduct,
                                                  ),
                                            ),
                                          );

                                          if (result == true) {
                                            refreshProduct();
                                          }
                                        },
                                        icon: Icon(
                                          Icons.edit,
                                          color: AppColors.primary,
                                          size: R.icon(
                                            context,
                                            AppSizes.iconMd,
                                          ),
                                        ),
                                        label: Text(
                                          "Edit",
                                          style: AppTextStyles.button.copyWith(
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary
                                              .withOpacity(0.1),
                                          foregroundColor: AppColors.primary,
                                          elevation: 0,
                                          minimumSize: Size.fromHeight(
                                            R.sp(
                                              context,
                                              AppSizes.buttonHeight,
                                            ),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              R.radius(
                                                context,
                                                AppSizes.radiusMd,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(
                                      width: R.sp(context, AppSpacing.sm),
                                    ),

                                    // UPDATE STOCK
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _showUpdateStockDialog,
                                        icon: Icon(
                                          Icons.inventory_2_outlined,
                                          color: AppColors.green,
                                          size: R.icon(
                                            context,
                                            AppSizes.iconMd,
                                          ),
                                        ),
                                        label: Text(
                                          "Update",
                                          style: AppTextStyles.button.copyWith(
                                            color: AppColors.green,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.green
                                              .withOpacity(0.1),
                                          foregroundColor: AppColors.green,
                                          elevation: 0,
                                          minimumSize: Size.fromHeight(
                                            R.sp(
                                              context,
                                              AppSizes.buttonHeight,
                                            ),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              R.radius(
                                                context,
                                                AppSizes.radiusMd,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(
                                      width: R.sp(context, AppSpacing.sm),
                                    ),

                                    // DELETE
                                    SizedBox(
                                      width: R.sp(
                                        context,
                                        AppSizes.buttonHeight,
                                      ),
                                      height: R.sp(
                                        context,
                                        AppSizes.buttonHeight,
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                backgroundColor: AppColors.card,
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
                                                  "Are you sure you want to delete ${currentProduct["name"]}?",
                                                  style: AppTextStyles.small
                                                      .copyWith(
                                                        color: AppColors
                                                            .textPrimaryDark,
                                                      ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      );
                                                    },
                                                    child: Text(
                                                      "Cancel",
                                                      style: AppTextStyles
                                                          .button
                                                          .copyWith(
                                                            color: AppColors
                                                                .textSecondary,
                                                          ),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          AppColors.red,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              AppSizes.radiusMd,
                                                            ),
                                                      ),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      );
                                                    },
                                                    child: Text(
                                                      "Delete",
                                                      style: AppTextStyles
                                                          .button
                                                          .copyWith(
                                                            color: AppColors
                                                                .textWhite,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );

                                          if (confirm == true) {
                                            await DBHelper.deleteProduct(
                                              currentProduct["id"],
                                            );
                                            Navigator.pop(context, true);
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.red
                                              .withOpacity(0.1),
                                          elevation: 0,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              R.radius(
                                                context,
                                                AppSizes.radiusMd,
                                              ),
                                            ),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.delete_outline,
                                          color: AppColors.red,
                                          size: R.icon(
                                            context,
                                            AppSizes.iconLg,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: R.sp(context, AppSpacing.lg)),

                      // ✅ INFO SECTION
                      Container(
                        padding: EdgeInsets.all(
                          R.sp(context, AppSpacing.cardPadding),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(
                            R.radius(context, AppSizes.cardRadius),
                          ),
                          border: Border.all(color: AppColors.border, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.03),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Product Information",
                              style: AppTextStyles.sectionTitle.copyWith(
                                color: AppColors.textPrimaryDark,
                              ),
                            ),

                            SizedBox(height: R.sp(context, AppSpacing.lg)),

                            _infoRow("Category", currentProduct["category"]),
                            _infoRow("HSN Code", currentProduct["hsn_code"]),
                            _infoRow("Product Code", currentProduct["barcode"]),
                            _infoRow(
                              "Purchase Price",
                              "₹ ${currentProduct["purchase_price"]}",
                            ),
                            _infoRow("Quantity", "$qty"),
                            _infoRow("Unit", currentProduct["unit"]),
                            _infoRow(
                              "Expiry Date",
                              currentProduct["expiry_date"],
                            ),
                            _infoRow(
                              "Description",
                              currentProduct["description"],
                            ),
                          ],
                        ),
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

  Widget _rowItem(String title, dynamic value, {Color? overrideColor}) {
    return Padding(
      padding: EdgeInsets.only(bottom: R.sp(context, AppSpacing.md)),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(title, style: AppTextStyles.small)),
          Expanded(
            flex: 5,
            child: Text(
              value?.toString() ?? "",
              style: AppTextStyles.cardValue.copyWith(
                color: overrideColor ?? AppColors.textPrimaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, dynamic value) {
    return Padding(
      padding: EdgeInsets.only(bottom: R.sp(context, AppSpacing.lg)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: Text(title, style: AppTextStyles.small)),
          Expanded(
            flex: 5,
            child: Text(
              value?.toString() ?? "-",
              style: AppTextStyles.cardValue,
            ),
          ),
        ],
      ),
    );
  }
}
