import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/storage/db_helper.dart';
import '../providers/billing_provider.dart';
import 'payment_screen.dart';
import 'add_product_bill_screen.dart';
import '../../../../core/utils/responsive_helper.dart';

class CurrentBillScreen extends ConsumerStatefulWidget {
  const CurrentBillScreen({super.key});

  @override
  ConsumerState<CurrentBillScreen> createState() => _CurrentBillScreenState();
}

class _CurrentBillScreenState extends ConsumerState<CurrentBillScreen> {
  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingProvider);
    final billingNotifier = ref.read(billingProvider.notifier);

    final originalSubtotal = billingState.cart.fold(
      0.0,
      (sum, item) => sum + item.subtotal,
    );
    final totalDiscount = billingState.cart.fold(
      0.0,
      (sum, item) => sum + item.discountAmount,
    );
    final subtotal = billingState.cart.fold(
      0.0,
      (sum, item) => sum + item.total,
    );
    final tax = billingState.tax;
    final total = subtotal + tax;

    // Responsive values
    final hPad = R.hPad(context, base: AppSpacing.screenPadding);
    final btnH = R.btnH(context);
    final headerFs = R.fs(context, 12);
    final itemNameFs = R.fs(context, 13);
    final totalFs = R.fs(context, 13);
    final imgSz = R.fluid(context, 40, 50);
    final iconSz = R.icon(context, 16);
    final summaryTitleFs = R.fs(context, 15);
    final summaryTotalFs = R.fs(context, 18);
    final summaryPad = R.sp(context, 6);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Clean Custom Header ──
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
                  Text("Billing", style: AppTextStyles.heading),
                ],
              ),
            ),

            // ── Add Products button (Compact) ──
            Container(
              margin: EdgeInsets.fromLTRB(
                R.sp(context, AppSpacing.screenPadding),
                R.sp(context, 10),
                R.sp(context, AppSpacing.screenPadding),
                R.sp(context, 6),
              ),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddProductBillScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  minimumSize: Size(
                    double.infinity,
                    R.sp(context, 48),
                  ), // ↓ Reduced
                  padding: EdgeInsets.symmetric(
                    vertical: R.sp(context, 4), // ↓ Reduced
                    horizontal: R.sp(context, 18),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Add Products",
                      style: AppTextStyles.button.copyWith(
                        color: Colors.white,
                        fontSize: R.fs(context, 16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: R.sp(context, 1)), // ↓ Reduced
                    Text(
                      "Scan or search to add items",
                      style: AppTextStyles.small.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: R.fs(context, 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Cart items ──
            Expanded(
              child: billingState.cart.isEmpty
                  ? Center(
                      child: Text(
                        "No Products Added",
                        style: AppTextStyles.sectionTitle.copyWith(
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                    )
                  : Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: hPad.left,
                        vertical: R.sp(context, AppSpacing.sm),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(
                          AppSizes.cardRadius,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // ── TABLE HEADER ──
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: R.sp(context, AppSpacing.sm),
                              vertical: R.sp(context, AppSpacing.md),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Text(
                                    "Item",
                                    style: AppTextStyles.small.copyWith(
                                      fontSize: headerFs,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimaryDark,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "Price",
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.small.copyWith(
                                      fontSize: headerFs,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimaryDark,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    "Qty",
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.small.copyWith(
                                      fontSize: headerFs,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimaryDark,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "Total",
                                    textAlign: TextAlign.right,
                                    style: AppTextStyles.small.copyWith(
                                      fontSize: headerFs,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimaryDark,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: R.fluid(context, 32, 40),
                                ), // Match delete button width
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: AppColors.surface2),
                          // ── TABLE ROWS ──
                          Expanded(
                            child: ListView.separated(
                              itemCount: billingState.cart.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: AppColors.surface2,
                              ),
                              itemBuilder: (context, index) {
                                final item = billingState.cart[index];
                                final deleteBtnW = R.fluid(context, 32, 40);

                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: R.sp(
                                      context,
                                      AppSpacing.sm,
                                    ), // Tighter horizontal padding to prevent overflow
                                    vertical: R.sp(context, AppSpacing.md),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // ITEM COLUMN
                                      Expanded(
                                        flex: 5,
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: imgSz,
                                              height: imgSz,
                                              child:
                                                  item.imagePath != null &&
                                                      item.imagePath!.isNotEmpty
                                                  ? ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            AppSizes.radiusSm,
                                                          ),
                                                      child: Image.file(
                                                        File(item.imagePath!),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    )
                                                  : Container(
                                                      decoration: BoxDecoration(
                                                        color:
                                                            AppColors.surface2,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              AppSizes.radiusSm,
                                                            ),
                                                      ),
                                                      child: Icon(
                                                        Icons.image_outlined,
                                                        color: AppColors
                                                            .textSecondary,
                                                        size: R.icon(
                                                          context,
                                                          20,
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                            SizedBox(
                                              width: R.sp(
                                                context,
                                                AppSpacing.sm,
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.name,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: AppTextStyles
                                                        .cardValue
                                                        .copyWith(
                                                          fontSize: itemNameFs,
                                                        ),
                                                  ),
                                                  SizedBox(
                                                    height: R.sp(
                                                      context,
                                                      AppSpacing.xs,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      "General",
                                                      style: AppTextStyles.small
                                                          .copyWith(
                                                            color: AppColors
                                                                .primary,
                                                            fontSize: 9,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // PRICE COLUMN
                                      Expanded(
                                        flex: 2,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.center,
                                          child: Text(
                                            "₹${item.price.toStringAsFixed(0)}",
                                            style: AppTextStyles.cardValue
                                                .copyWith(fontSize: itemNameFs),
                                          ),
                                        ),
                                      ),

                                      // QTY COLUMN
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            InkWell(
                                              onTap: () => billingNotifier
                                                  .decreaseQty(index),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: Container(
                                                padding: EdgeInsets.all(
                                                  R.sp(context, 2),
                                                ), // Reduced internal padding
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Icon(
                                                  Icons.remove,
                                                  size: iconSz,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: R.sp(
                                                  context,
                                                  AppSpacing.xs,
                                                ),
                                              ), // Tighter text spacing
                                              child: Text(
                                                item.qty.toString(),
                                                style: AppTextStyles.cardValue
                                                    .copyWith(
                                                      fontSize: itemNameFs,
                                                    ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () => billingNotifier
                                                  .increaseQty(index),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: Container(
                                                padding: EdgeInsets.all(
                                                  R.sp(context, 2),
                                                ), // Reduced internal padding
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Icon(
                                                  Icons.add,
                                                  size: iconSz,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // TOTAL COLUMN
                                      Expanded(
                                        flex: 2,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            "₹${item.total.toStringAsFixed(0)}",
                                            style: AppTextStyles.cardValue
                                                .copyWith(fontSize: totalFs),
                                          ),
                                        ),
                                      ),

                                      // DELETE ICON (Constraints Removed to prevent overflow)
                                      SizedBox(
                                        width: deleteBtnW,
                                        child: IconButton(
                                          padding: EdgeInsets
                                              .zero, // Stripped default padding causing overflow
                                          constraints:
                                              const BoxConstraints(), // Overrides the 48x48 default minimum
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: AppColors.red,
                                            size: R.icon(context, 20),
                                          ),
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (_) => AlertDialog(
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
                                                  "Delete ${item.name} ?",
                                                  style: AppTextStyles.small,
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          context,
                                                          false,
                                                        ),
                                                    child: const Text("Cancel"),
                                                  ),
                                                  ElevatedButton(
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              AppColors.red,
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
                                                            color: Colors.white,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              billingNotifier.removeItem(index);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // ── Summary panel ──
            Container(
              padding: EdgeInsets.all(R.sp(context, AppSpacing.screenPadding)),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(R.sp(context, AppSpacing.sm)),
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                        ),
                        child: Icon(
                          Icons.receipt_long,
                          color: AppColors.cyanDim,
                          size: R.icon(context, 18),
                        ),
                      ),
                      SizedBox(width: R.sp(context, AppSpacing.sm)),
                      Text(
                        "Bill Summary",
                        style: AppTextStyles.sectionTitle.copyWith(
                          color: AppColors.textPrimaryDark,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: R.sp(context, AppSpacing.lg)),
                  _amountRow(
                    context,
                    "Subtotal",
                    originalSubtotal,
                    titleFs: summaryTitleFs,
                    padding: summaryPad,
                  ),
                  _amountRow(
                    context,
                    "Discount",
                    totalDiscount,
                    titleFs: summaryTitleFs,
                    padding: summaryPad,
                  ),
                  _amountRow(
                    context,
                    "Tax",
                    tax,
                    titleFs: summaryTitleFs,
                    padding: summaryPad,
                  ),
                  const Divider(color: AppColors.surface2),
                  _amountRow(
                    context,
                    "Total",
                    total,
                    isBold: true,
                    titleFs: summaryTotalFs,
                    padding: summaryPad,
                  ),

                  SizedBox(height: R.sp(context, AppSpacing.xl)),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusLg,
                                    ),
                                  ),
                                  title: Text(
                                    "Clear Bill",
                                    style: AppTextStyles.sectionTitle.copyWith(
                                      color: AppColors.textPrimaryDark,
                                    ),
                                  ),
                                  content: Text(
                                    "Are you sure you want to clear all items from this bill?",
                                    style: AppTextStyles.small,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.red,
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text(
                                        "Clear",
                                        style: AppTextStyles.button.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (confirm == true) {
                              billingNotifier.clearCart();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Bill cleared successfully"),
                                ),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.red),
                            minimumSize: Size(double.infinity, btnH),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMd,
                              ),
                            ),
                          ),
                          child: Text(
                            "Clear Bill",
                            style: AppTextStyles.button.copyWith(
                              color: AppColors.red,
                              fontSize: R.fs(context, 15),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: R.sp(context, AppSpacing.md)),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMd,
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              if (billingState.cart.isEmpty) return;

                              final invoiceId = await DBHelper.createInvoice(
                                items: billingState.cart.map((item) {
                                  return {
                                    "id": item.productId,
                                    "name": item.name,
                                    "price": item.price,
                                    "qty": item.qty,
                                  };
                                }).toList(),
                                subtotal: subtotal,
                                discount: billingState.discount,
                                tax: tax,
                                total: total,
                              );
                              final invoiceNumber =
                                  "INV-${DateTime.now().millisecondsSinceEpoch}";

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PaymentScreen(
                                    totalAmount: total,
                                    invoiceId: invoiceId,
                                    invoiceNumber: invoiceNumber,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              minimumSize: Size(double.infinity, btnH),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMd,
                                ),
                              ),
                            ),
                            child: Text(
                              "Pay",
                              style: AppTextStyles.button.copyWith(
                                color: Colors.white,
                                fontSize: R.fs(context, 15),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountRow(
    BuildContext context,
    String title,
    double amount, {
    bool isBold = false,
    double? titleFs,
    double padding = 6,
  }) {
    final fs = titleFs ?? R.fs(context, isBold ? 18 : 15);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding),
      child: Row(
        children: [
          Text(
            title,
            style: isBold
                ? AppTextStyles.cardValue.copyWith(fontSize: fs * 1.1)
                : AppTextStyles.small.copyWith(
                    fontSize: fs,
                    color: AppColors.textPrimaryDark,
                  ),
          ),
          const Spacer(),
          Text(
            "₹${amount.toStringAsFixed(2)}",
            style: isBold
                ? AppTextStyles.cardValue.copyWith(fontSize: fs * 1.1)
                : AppTextStyles.cardValue.copyWith(fontSize: fs),
          ),
        ],
      ),
    );
  }
}
