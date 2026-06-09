import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_curve.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/storage/db_helper.dart';
import '../providers/billing_provider.dart';
import 'payment_screen.dart';

class NewBillScreen extends ConsumerStatefulWidget {
  const NewBillScreen({super.key});

  @override
  ConsumerState<NewBillScreen> createState() => _NewBillScreenState();
}

class _NewBillScreenState extends ConsumerState<NewBillScreen> {
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
          "New Bill",
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
                              margin: const EdgeInsets.only(bottom: 12),

                              padding: const EdgeInsets.all(14),

                              decoration: BoxDecoration(
                                color: Colors.white,

                                borderRadius: BorderRadius.circular(
                                  AppSizes.cardRadius,
                                ),
                              ),

                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          color: Colors.grey.shade100,
                                        ),
                                        child:
                                            item.imagePath != null &&
                                                item.imagePath!.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Image.file(
                                                  File(item.imagePath!),
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : const Icon(Icons.inventory),
                                      ),

                                      const SizedBox(width: 12),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,

                                          children: [
                                            Text(
                                              item.name,

                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),

                                            const SizedBox(height: 5),

                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "₹${item.price.toStringAsFixed(2)}",
                                                ),

                                                Text(
                                                  "Discount: ${item.discount.toStringAsFixed(0)}%",
                                                  style: const TextStyle(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      IconButton(
                                        onPressed: () async {
                                          final result = await showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: const Text(
                                                  "Remove Product",
                                                ),
                                                content: Text(
                                                  "Are you sure you want to remove ${item.name} from bill?",
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      );
                                                    },
                                                    child: const Text("Cancel"),
                                                  ),

                                                  ElevatedButton(
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                    onPressed: () {
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "Delete",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );

                                          if (result == true) {
                                            billingNotifier.removeItem(index);
                                          }
                                        },

                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),

                                          color: Colors.grey.shade200,
                                        ),

                                        child: Row(
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                billingNotifier.decreaseQty(
                                                  index,
                                                );
                                              },

                                              icon: const Icon(Icons.remove),
                                            ),

                                            Text(item.qty.toString()),

                                            IconButton(
                                              onPressed: () {
                                                billingNotifier.increaseQty(
                                                  index,
                                                );
                                              },

                                              icon: const Icon(Icons.add),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const Spacer(),

                                      Text(
                                        "₹${item.total.toStringAsFixed(2)}",

                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                Container(
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
                                        borderRadius: BorderRadius.circular(16),
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
                                backgroundColor: AppColors.primary.withOpacity(
                                  0.1,
                                ),
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
                                backgroundColor: Colors.green.withOpacity(0.1),
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
