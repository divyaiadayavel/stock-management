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
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          ("Current Bill"),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                Container(
                  margin: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddProductBillScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      "Add Products",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: const [
                      Expanded(
                        flex: 4,
                        child: Text(
                          "Item",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      Expanded(
                        flex: 2,
                        child: Text(
                          "Price",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      Expanded(
                        flex: 3,
                        child: Text(
                          "Qty",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      Expanded(
                        flex: 2,
                        child: Text(
                          "Total",
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      SizedBox(
                        width: 32,
                        child: Icon(Icons.delete_outline, size: 18),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: billingState.cart.isEmpty
                      ? const Center(
                          child: Text(
                            "No Products Added",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),

                          itemCount: billingState.cart.length,

                          itemBuilder: (context, index) {
                            final item = billingState.cart[index];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  // IMAGE
                                  SizedBox(
                                    width: 45,
                                    height: 45,
                                    child:
                                        item.imagePath != null &&
                                            item.imagePath!.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: Image.file(
                                              File(item.imagePath!),
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Icon(Icons.inventory),
                                  ),

                                  const SizedBox(width: 8),

                                  // ITEM NAME
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      item.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),

                                  // PRICE
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "₹${item.price.toStringAsFixed(0)}",
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  // QTY
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            billingNotifier.decreaseQty(index);
                                          },
                                          child: const Icon(
                                            Icons.remove,
                                            size: 16,
                                          ),
                                        ),

                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: Text(
                                            item.qty.toString(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),

                                        InkWell(
                                          onTap: () {
                                            billingNotifier.increaseQty(index);
                                          },
                                          child: const Icon(
                                            Icons.add,
                                            size: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // TOTAL
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "₹${item.total.toStringAsFixed(0)}",
                                      textAlign: TextAlign.right,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  // DELETE
                                  SizedBox(
                                    width: 32,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text("Delete Product"),
                                            content: Text(
                                              "Delete ${item.name} ?",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text("Cancel"),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                child: const Text("Delete"),
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

                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.all(16),

                    decoration: const BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),

                    child: Column(
                      children: [
                        _amountRow("Subtotal", originalSubtotal),

                        _amountRow("Discount", totalDiscount),

                        _amountRow("Tax", tax),

                        const Divider(),

                        _amountRow("Total", total, isBold: true),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
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
                                  minimumSize: const Size(double.infinity, 55),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),

                                child: Text(
                                  "Clear Bill",
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

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
                                  minimumSize: const Size(double.infinity, 55),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),

                                child: const Text(
                                  "Pay",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
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

  Widget _amountRow(String title, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isBold ? 18 : 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),

          const Spacer(),

          Text(
            "₹${amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: isBold ? 18 : 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
