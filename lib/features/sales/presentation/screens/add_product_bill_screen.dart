import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../products/presentation/screens/barcode_scanner_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_curve.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/storage/db_helper.dart';
import 'dart:io';
import '../providers/billing_provider.dart';
import 'new_bill_screen.dart';

final searchProductProvider = StateProvider<String>((ref) => "");

class AddProductBillScreen extends ConsumerStatefulWidget {
  const AddProductBillScreen({super.key});

  @override
  ConsumerState<AddProductBillScreen> createState() =>
      _AddProductBillScreenState();
}

class _AddProductBillScreenState extends ConsumerState<AddProductBillScreen> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    final data = await DBHelper.getAllProducts();

    setState(() {
      products = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingProvider);

    final search = ref.watch(searchProductProvider);
    final filteredProducts = products.where((product) {
      return product["name"].toString().toLowerCase().contains(
        search.toLowerCase(),
      );
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Add Product Bill",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: Container(
        color: AppColors.primary,
        child: ClipRRect(
          borderRadius: AppCurve.top(context),
          child: Container(
            color: AppColors.background,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SEARCH + FILTER
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: (value) {
                                  ref
                                          .read(searchProductProvider.notifier)
                                          .state =
                                      value;
                                },
                                decoration: InputDecoration(
                                  hintText: "Search product / barcode",
                                  prefixIcon: const Icon(Icons.search),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () async {
                                final barcode = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const BarcodeScannerScreen(),
                                  ),
                                );

                                if (barcode == null ||
                                    barcode.toString().isEmpty)
                                  return;

                                final product =
                                    await DBHelper.getProductByBarcode(
                                      barcode.toString(),
                                    );

                                if (product != null) {
                                  ref
                                      .read(billingProvider.notifier)
                                      .addToCart(product, 1);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "${product['name']} added to bill",
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Product not found"),
                                    ),
                                  );
                                }
                              },

                              child: Container(
                                height: 55,
                                width: 55,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.qr_code_scanner,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        // ALL PRODUCTS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              "All Products",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "A to Z",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child:
                                        product["image_path"] != null &&
                                            product["image_path"]
                                                .toString()
                                                .isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Image.file(
                                              File(product["image_path"]),
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
                                          product["name"],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),

                                        const SizedBox(height: 4),

                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            product["category"],
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Text(
                                    "₹${product["selling_price"]}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),

                                  IconButton(
                                    onPressed: () {
                                      ref
                                          .read(billingProvider.notifier)
                                          .addToCart(product, 1);
                                    },
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: AppColors.primary,
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
        ),
      ),

      floatingActionButton: billingState.cart.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.primary,

              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewBillScreen()),
                );
              },

              label: Text(
                "View Bill (${billingState.cart.length})",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),

              icon: const Icon(Icons.receipt_long, color: Colors.white),
            ),
    );
  }
}
