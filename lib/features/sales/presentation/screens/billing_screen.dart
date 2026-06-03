import 'package:flutter/material.dart';
import '../../../../core/storage/db_helper.dart';
import '../../data/models/cart_item_model.dart';
import '../widgets/product_search_sheet.dart';
import 'payment_screen.dart'; // ✅ Updated Import
import '../../../../core/constants/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/billing_provider.dart';

class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingState = ref.watch(billingProvider);

    final billingNotifier = ref.read(billingProvider.notifier);

    final cart = billingState.cart;

    final subtotal = billingState.subtotal;

    final tax = billingState.tax;

    final total = billingState.total;

    final discount = billingState.discount;

    final taxPercent = billingState.taxPercent;

    // ================= PAYMENT (UPDATED NAVIGATION) =================
    Future<void> processPayment() async {
      if (cart.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please add items to cart first")),
        );
        return;
      }

      try {
        final items = cart
            .map(
              (e) => {
                "id": e.productId,
                "name": e.name,
                "price": e.price,
                "qty": e.qty,
              },
            )
            .toList();
        print("===== BILL ITEMS =====");

        for (var item in items) {
          print("Product: ${item['name']} | Qty: ${item['qty']}");
        }

        // Create the invoice in DB first to get the ID
        int invoiceId = await DBHelper.createInvoice(
          items: items,
          subtotal: subtotal,
          discount: discount,
          tax: tax,
          total: total,
        );

        // ✅ Navigate to Payment Screen instead of directly to Invoice
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentScreen(
              totalAmount: total,
              invoiceNumber: "INV-$invoiceId",
              invoiceId: invoiceId,
            ),
          ),
        );

        // Note: We don't clear the cart here anymore because
        // the transaction isn't "Complete" until the Payment Screen says so.
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }

    // ================= UI =================
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // 🔷 APP BAR
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          "New Bill",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Column(
        children: [
          // 🔵 HEADER SEARCH
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => ProductSearchSheet(
                          // Pass the function like this to ensure context is maintained
                          onSelect: (selectedProduct, selectedQty) {
                            billingNotifier.addToCart(
                              selectedProduct,
                              selectedQty,
                            );
                          },
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Search product / barcode",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.qr_code, color: Colors.blue),
                ),
              ],
            ),
          ),

          // 🧾 HEADER ROW
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Colors.white,
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text("Product")),
                Expanded(child: Text("Qty")),
                Expanded(child: Text("Price")),
                Expanded(child: Text("Amount")),
              ],
            ),
          ),

          // 🧾 CART LIST
          Flexible(
            child: cart.isEmpty
                ? const Center(child: Text("No items added"))
                : ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (_, i) {
                      final item = cart[i];

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                item.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        billingNotifier.decreaseQty(i);
                                      },
                                      child: const Icon(Icons.remove, size: 18),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      child: Text("${item.qty}"),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        billingNotifier.increaseQty(i);
                                      },
                                      child: const Icon(Icons.add, size: 18),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: FittedBox(
                                alignment: Alignment.centerLeft,
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "₹ ${item.price.toStringAsFixed(0)}",
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  children: [
                                    Text(
                                      "₹ ${item.total.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () {
                                        billingNotifier.removeItem(i);
                                      },
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // 💰 TOTAL SECTION
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: Colors.white,
            child: Column(
              children: [
                _row("Subtotal", subtotal),
                _row("Discount", discount),
                _row("Tax (${taxPercent.toInt()}%)", tax),
                const Divider(),
                _row("Total", total, bold: true),
              ],
            ),
          ),

          // 🔘 BUTTONS
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        billingNotifier.clearCart();
                      },
                      child: const Text("Clear"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ✅ Removed Hold Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white, // Text color
                      ),
                      child: const Text("Pay"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String title, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            "₹ ${value.toStringAsFixed(0)}",
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
