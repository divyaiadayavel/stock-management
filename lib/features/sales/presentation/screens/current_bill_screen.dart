import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_config.dart';
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
  // ─── Dynamic Product Image Loader for Cart ────────────────
  Widget _buildCartItemImage(String? rawImagePath, double size) {
    if (rawImagePath == null || rawImagePath.trim().isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: Icon(
          Icons.image_outlined,
          color: AppColors.textSecondary,
          size: R.icon(context, 20),
        ),
      );
    }

    String imagePath = rawImagePath.trim();

    // 1. Local Device File Path (e.g., newly selected image)
    final localFile = File(imagePath);
    if (!imagePath.startsWith('http') && localFile.existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        child: Image.file(
          localFile,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.surface2,
            child: Icon(
              Icons.image_outlined,
              color: AppColors.textSecondary,
              size: R.icon(context, 20),
            ),
          ),
        ),
      );
    }

    // 2. Sanitize legacy ngrok / localhost URLs stored in DB
    if (imagePath.contains('ngrok') ||
        imagePath.contains('localhost') ||
        imagePath.contains('127.0.0.1')) {
      if (imagePath.contains('uploads/')) {
        imagePath = 'uploads/' + imagePath.split('uploads/').last;
      }
    }

    // 3. Convert Relative Path to Full Live URL
    String fullImageUrl = imagePath;
    if (!fullImageUrl.startsWith('http://') &&
        !fullImageUrl.startsWith('https://')) {
      if (fullImageUrl.startsWith('/')) {
        fullImageUrl = fullImageUrl.substring(1);
      }
      fullImageUrl = '${ApiConfig.baseUrl}/$fullImageUrl';
    }

    // Decoding at roughly the on-screen pixel size (rather than full
    // resolution) means each cached decode is tiny, so a whole bill's worth
    // of thumbnails comfortably fits in Flutter's image cache at once instead
    // of pushing each other out and forcing a re-decode on scroll.
    final targetPx = (size * MediaQuery.of(context).devicePixelRatio).round();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      child: CachedNetworkImage(
        imageUrl: fullImageUrl,
        cacheKey: fullImageUrl,
        memCacheWidth: targetPx,
        memCacheHeight: targetPx,
        useOldImageOnUrlChange: true,
        fit: BoxFit.cover,
        placeholder: (_, __) => Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          color: AppColors.surface2,
          child: Icon(
            Icons.image_outlined,
            color: AppColors.textSecondary,
            size: R.icon(context, 20),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingProvider);
    final billingNotifier = ref.read(billingProvider.notifier);

    // All totals come directly from BillingProvider
    final subtotal = billingState.subtotal;
    final tax = billingState.tax;
    final totalDiscount = billingState.itemDiscount;
    final grandTotal = billingState.grandTotal;
    final totalItems = billingState.totalItems;

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
                  minimumSize: Size(double.infinity, R.sp(context, 48)),
                  padding: EdgeInsets.symmetric(
                    vertical: R.sp(context, 4),
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
                    SizedBox(height: R.sp(context, 1)),
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: R.icon(context, 60),
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: R.sp(context, AppSpacing.md)),
                          Text(
                            "No items in this bill",
                            style: AppTextStyles.sectionTitle.copyWith(
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                          SizedBox(height: R.sp(context, AppSpacing.sm)),
                          Text(
                            "Tap \"Add Products\" to start billing",
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox.shrink(),
                        ],
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
                                SizedBox(width: R.fluid(context, 32, 40)),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: AppColors.surface2),
                          // ── TABLE ROWS ──
                          Expanded(
                            child: ListView.separated(
                              // ✅ FIX: A bill's cart is a bounded, modest-sized
                              // list (a handful to a few dozen line items), not
                              // an endless feed. The default cacheExtent (250px)
                              // was disposing rows once they scrolled far enough
                              // off-screen, so scrolling back down past them
                              // remounted a brand-new CachedNetworkImage widget
                              // and briefly flashed the placeholder again —
                              // looking like the image was "reloading". Keeping
                              // a generous cacheExtent means every row (and its
                              // decoded image) stays alive for the life of the
                              // billing session, so it never has to re-resolve.
                              cacheExtent: 3000,
                              itemCount: billingState.cart.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: AppColors.surface2,
                              ),
                              itemBuilder: (context, index) {
                                final item = billingState.cart[index];
                                final deleteBtnW = R.fluid(context, 32, 40);

                                return Padding(
                                  // Stable identity per product so Flutter never
                                  // confuses one row's element/image state for
                                  // another's when qty changes or an item is
                                  // removed from the middle of the cart.
                                  key: ValueKey(item.productId),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: R.sp(context, AppSpacing.sm),
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
                                              child: _buildCartItemImage(
                                                item.imagePath,
                                                imgSz,
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
                                                      item.category ??
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
                                            "₹${item.price.toStringAsFixed(2)}",
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
                                                  .decreaseQty(item.productId),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: Container(
                                                padding: EdgeInsets.all(
                                                  R.sp(context, 2),
                                                ),
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
                                              ),
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
                                                  .increaseQty(item.productId),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: Container(
                                                padding: EdgeInsets.all(
                                                  R.sp(context, 2),
                                                ),
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
                                            "₹${item.total.toStringAsFixed(2)}",
                                            style: AppTextStyles.cardValue
                                                .copyWith(fontSize: totalFs),
                                          ),
                                        ),
                                      ),

                                      // DELETE ICON
                                      SizedBox(
                                        width: deleteBtnW,
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
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
                                              billingNotifier.removeProduct(
                                                item.productId,
                                              );
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
                      const Spacer(),
                      Text(
                        "$totalItems items",
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: R.sp(context, AppSpacing.lg)),
                  _amountRow(
                    context,
                    "Subtotal",
                    subtotal,
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
                    "Grand Total",
                    grandTotal,
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

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Bill cleared successfully"),
      ),
    );
  }
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
                            onPressed: billingState.cart.isEmpty
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PaymentScreen(
                                          totalAmount: grandTotal,
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
