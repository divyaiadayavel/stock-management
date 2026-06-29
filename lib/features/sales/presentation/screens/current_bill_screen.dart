import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_curve.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/storage/db_helper.dart';
import '../providers/billing_provider.dart';
import 'payment_screen.dart';
import 'add_product_bill_screen.dart';
import '../../../../core/utils/responsive_helper.dart'; // ← add this import

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

    // ── responsive values ──────────────────────────────────────
    final hPad = R.hPad(context, base: 16);
    final btnH = R.btnH(context);
    final headerFs = R.fs(context, 13);
    final itemNameFs = R.fs(context, 13);
    final priceFs = R.fs(context, 13);
    final totalFs = R.fs(context, 13);
    final imgSz = R.fluid(context, 45, 70);
    final iconSz = R.icon(context, 16);
    final cardRadius = R.radius(context, 8);
    final summaryTitleFs = R.fs(context, 15);
    final summaryTotalFs = R.fs(context, 18);
    final summaryPad = R.sp(context, 6);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Billing",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: R.fs(context, 18),
          ),
        ),
      ),

      body: Container(
        color: AppColors.primary,
        child: ClipRRect(
          borderRadius: AppCurve.top(context),
          child: Container(
            color: AppColors.background,
            child: Column(
              children: [
                // ── Add Products button ──────────────────────────
                Container(
                  margin: EdgeInsets.all(R.sp(context, 16)),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: Size(double.infinity, btnH),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          R.radius(context, 12),
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddProductBillScreen(),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          height: R.fluid(context, 32, 40),
                          width: R.fluid(context, 32, 40),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white54,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),

                        SizedBox(width: R.sp(context, 12)),

                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Add Products",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: R.fs(context, 16),
                                ),
                              ),

                              SizedBox(height: R.sp(context, 2)),

                              Text(
                                "Add more items to your bill",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: R.fs(context, 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Cart items ────────────────────────────────────
                Expanded(
                  child: billingState.cart.isEmpty
                      ? Center(
                          child: Text(
                            "No Products Added",
                            style: TextStyle(
                              fontSize: R.fs(context, 16),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: hPad.left,
                            vertical: R.sp(context, 8),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(cardRadius),
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
                              // HEADER
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: R.sp(context, 12),
                                  vertical: R.sp(context, 12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        "Item",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: headerFs,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "Price",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: headerFs,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        "Qty",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: headerFs,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "Total",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: headerFs,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: R.fluid(context, 32, 44)),
                                  ],
                                ),
                              ),

                              Divider(height: 1),

                              Expanded(
                                child: ListView.separated(
                                  itemCount: billingState.cart.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final item = billingState.cart[index];
                                    final deleteBtnW = R.fluid(context, 32, 44);

                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: R.sp(context, 10),
                                        vertical: R.sp(context, 10),
                                      ),
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
                                                          R.radius(context, 6),
                                                        ),
                                                    child: Image.file(
                                                      File(item.imagePath!),
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                : Icon(
                                                    Icons.inventory,
                                                    size: R.icon(context, 24),
                                                  ),
                                          ),

                                          SizedBox(width: R.sp(context, 8)),

                                          Expanded(
                                            flex: 4,
                                            child: Text(
                                              item.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: itemNameFs,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),

                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              "₹${item.price.toStringAsFixed(0)}",
                                              textAlign: TextAlign.center,
                                            ),
                                          ),

                                          Expanded(
                                            flex: 3,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    billingNotifier.decreaseQty(
                                                      index,
                                                    );
                                                  },
                                                  child: Icon(
                                                    Icons.remove,
                                                    size: iconSz,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: R.sp(
                                                      context,
                                                      4,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    item.qty.toString(),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    billingNotifier.increaseQty(
                                                      index,
                                                    );
                                                  },
                                                  child: Icon(
                                                    Icons.add,
                                                    size: iconSz,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              "₹${item.total.toStringAsFixed(0)}",
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: totalFs,
                                              ),
                                            ),
                                          ),

                                          SizedBox(
                                            width: deleteBtnW,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                                size: R.icon(context, 20),
                                              ),
                                              onPressed: () async {
                                                final confirm =
                                                    await showDialog<bool>(
                                                      context: context,
                                                      builder: (_) => AlertDialog(
                                                        title: const Text(
                                                          "Delete Product",
                                                        ),
                                                        content: Text(
                                                          "Delete ${item.name} ?",
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
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  context,
                                                                  true,
                                                                ),
                                                            child: const Text(
                                                              "Delete",
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );

                                                if (confirm == true) {
                                                  billingNotifier.removeItem(
                                                    index,
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
                // ── Summary panel ─────────────────────────────────
                SafeArea(
                  top: false,
                  child: Container(
                    padding: EdgeInsets.all(R.sp(context, 16)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        R.radius(context, 16),
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
                        // 🔹 BILL SUMMARY HEADER
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(R.sp(context, 8)),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                  R.radius(context, 8),
                                ),
                              ),
                              child: Icon(
                                Icons.receipt_long,
                                color: AppColors.primary,
                                size: R.icon(context, 18),
                              ),
                            ),

                            SizedBox(width: R.sp(context, 10)),

                            Text(
                              "Bill Summary",
                              style: TextStyle(
                                fontSize: R.fs(context, 16),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: R.sp(context, 16)),

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
                        const Divider(),
                        _amountRow(
                          context,
                          "Total",
                          total,
                          isBold: true,
                          titleFs: summaryTotalFs,
                          padding: summaryPad,
                        ),

                        SizedBox(height: R.sp(context, 20)),

                        Row(
                          children: [
                            // CLEAR BILL
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            R.radius(context, 16),
                                          ),
                                        ),
                                        title: const Text("Clear Bill"),
                                        content: const Text(
                                          "Are you sure you want to clear all items from this bill?",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context, false);
                                            },
                                            child: const Text("Cancel"),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            onPressed: () {
                                              Navigator.pop(context, true);
                                            },
                                            child: const Text(
                                              "Clear",
                                              style: TextStyle(
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
                                        content: Text(
                                          "Bill cleared successfully",
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary
                                      .withOpacity(0.1),
                                  foregroundColor: AppColors.primary,
                                  elevation: 0,
                                  minimumSize: Size(double.infinity, btnH),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      R.radius(context, 12),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  "Clear Bill",
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: R.fs(context, 15),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(width: R.sp(context, 12)),

                            // PAY
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (billingState.cart.isEmpty) return;

                                  final invoiceId =
                                      await DBHelper.createInvoice(
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
                                  backgroundColor: Colors.green.withOpacity(
                                    0.1,
                                  ),
                                  foregroundColor: Colors.green,
                                  elevation: 0,
                                  minimumSize: Size(double.infinity, btnH),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      R.radius(context, 12),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  "Pay",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                    fontSize: R.fs(context, 15),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
            style: TextStyle(
              fontSize: isBold ? fs * 1.1 : fs,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            "₹${amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: isBold ? fs * 1.1 : fs,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
