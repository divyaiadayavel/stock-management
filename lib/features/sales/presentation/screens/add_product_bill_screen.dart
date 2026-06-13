import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../products/presentation/screens/barcode_scanner_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_curve.dart';
import '../../../../core/storage/db_helper.dart';
import '../providers/billing_provider.dart';
import 'current_bill_screen.dart';

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
      final searchMatch = product["name"].toString().toLowerCase().contains(
        search.toLowerCase(),
      );

      final categoryMatch =
          selectedCategory == "All" ||
          (product["category"] ?? "").toString() == selectedCategory;

      return searchMatch && categoryMatch;
    }).toList();

    filteredProducts.sort(
      (a, b) => (a["name"] ?? "").toString().toLowerCase().compareTo(
        (b["name"] ?? "").toString().toLowerCase(),
      ),
    );
    filteredProducts.sort((a, b) {
      final nameA = a["name"].toString();
      final nameB = b["name"].toString();

      return isAscending ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
    });
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
                                height: 50,
                                width: 50,
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

                        SizedBox(
                          height: 42,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return _categoryChip("All");
                              }

                              return _categoryChip(categories[index - 1]);
                            },
                          ),
                        ),

                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "All Products",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            TextButton(
                              onPressed: () {
                                setState(() {
                                  isAscending = !isAscending;
                                });
                              },
                              child: Text(isAscending ? "A-Z" : "Z-A"),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // ── LEFT: product info — always same width ──────────────
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Product name
                                        Text(
                                          product["name"] ?? "",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                          ),
                                        ),

                                        const SizedBox(height: 5),

                                        // Price / Disc / Stock
                                        Row(
                                          children: [
                                            _metaChip(
                                              label: "Price",
                                              value:
                                                  "₹${product["selling_price"]}",
                                              valueColor: Colors.black87,
                                            ),
                                            const SizedBox(width: 12),
                                            _metaChip(
                                              label: "Disc",
                                              value:
                                                  "${product["discount"] ?? 0}%",
                                              valueColor: Colors.green,
                                            ),
                                            const SizedBox(width: 12),
                                            _metaChip(
                                              label: "Stock",
                                              value: "${product["quantity"]}u",
                                              valueColor: Colors.blue,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // ── RIGHT: fixed 130px wide — never shifts left text ────
                                  SizedBox(
                                    width: 130,
                                    child: Consumer(
                                      builder: (context, ref, child) {
                                        final billingState = ref.watch(
                                          billingProvider,
                                        );
                                        final existingIndex = billingState.cart
                                            .indexWhere(
                                              (e) =>
                                                  e.productId == product["id"],
                                            );

                                        // ── NOT IN CART: + button aligned far right ────────
                                        if (existingIndex == -1) {
                                          return Align(
                                            alignment: Alignment.centerRight,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(9),
                                              onTap: () => ref
                                                  .read(
                                                    billingProvider.notifier,
                                                  )
                                                  .addToCart(product, 1),
                                              child: Container(
                                                height: 34,
                                                width: 34,
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(9),
                                                ),
                                                child: const Icon(
                                                  Icons.add,
                                                  color: Colors.white,
                                                  size: 19,
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        // ── IN CART: [ − qty + ]  🗑 fills the 130px ──────
                                        final item =
                                            billingState.cart[existingIndex];

                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            // [ − | qty | + ]
                                            Expanded(
                                              child: Container(
                                                height: 34,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: AppColors.primary
                                                        .withOpacity(0.4),
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(9),
                                                ),
                                                child: Row(
                                                  children: [
                                                    // MINUS
                                                    Expanded(
                                                      child: InkWell(
                                                        borderRadius:
                                                            const BorderRadius.only(
                                                              topLeft:
                                                                  Radius.circular(
                                                                    8,
                                                                  ),
                                                              bottomLeft:
                                                                  Radius.circular(
                                                                    8,
                                                                  ),
                                                            ),
                                                        onTap: () {
                                                          if (item.qty > 1) {
                                                            ref
                                                                .read(
                                                                  billingProvider
                                                                      .notifier,
                                                                )
                                                                .decreaseQty(
                                                                  existingIndex,
                                                                );
                                                          }
                                                        },
                                                        child: Container(
                                                          height: 34,
                                                          decoration: const BoxDecoration(
                                                            color: Color(
                                                              0x121A56E8,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.only(
                                                                  topLeft:
                                                                      Radius.circular(
                                                                        8,
                                                                      ),
                                                                  bottomLeft:
                                                                      Radius.circular(
                                                                        8,
                                                                      ),
                                                                ),
                                                          ),
                                                          child: Icon(
                                                            Icons.remove,
                                                            color: AppColors
                                                                .primary,
                                                            size: 15,
                                                          ),
                                                        ),
                                                      ),
                                                    ),

                                                    // Divider
                                                    Container(
                                                      width: 1,
                                                      height: 34,
                                                      color: AppColors.primary
                                                          .withOpacity(0.25),
                                                    ),

                                                    // QTY INPUT — white bg, black text
                                                    Expanded(
                                                      child: SizedBox(
                                                        height: 34,
                                                        child: TextFormField(
                                                          key: ValueKey(
                                                            item.qty,
                                                          ),
                                                          initialValue: item.qty
                                                              .toString(),
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          textAlign:
                                                              TextAlign.center,

                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 13,
                                                                height: 1.2,
                                                              ),
                                                          decoration:
                                                              const InputDecoration(
                                                                filled: true,
                                                                fillColor:
                                                                    Colors
                                                                        .white,
                                                                border:
                                                                    InputBorder
                                                                        .none,
                                                                isDense: true,
                                                                contentPadding:
                                                                    EdgeInsets.symmetric(
                                                                      vertical:
                                                                          8,
                                                                    ),
                                                              ),
                                                          onFieldSubmitted: (value) {
                                                            final newQty =
                                                                int.tryParse(
                                                                  value,
                                                                );
                                                            if (newQty !=
                                                                    null &&
                                                                newQty > 0) {
                                                              while (item.qty <
                                                                  newQty) {
                                                                ref
                                                                    .read(
                                                                      billingProvider
                                                                          .notifier,
                                                                    )
                                                                    .increaseQty(
                                                                      existingIndex,
                                                                    );
                                                              }
                                                              while (item.qty >
                                                                  newQty) {
                                                                ref
                                                                    .read(
                                                                      billingProvider
                                                                          .notifier,
                                                                    )
                                                                    .decreaseQty(
                                                                      existingIndex,
                                                                    );
                                                              }
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                    ),

                                                    // Divider
                                                    Container(
                                                      width: 1,
                                                      height: 34,
                                                      color: AppColors.primary
                                                          .withOpacity(0.25),
                                                    ),

                                                    // PLUS
                                                    Expanded(
                                                      child: InkWell(
                                                        borderRadius:
                                                            const BorderRadius.only(
                                                              topRight:
                                                                  Radius.circular(
                                                                    8,
                                                                  ),
                                                              bottomRight:
                                                                  Radius.circular(
                                                                    8,
                                                                  ),
                                                            ),
                                                        onTap: () => ref
                                                            .read(
                                                              billingProvider
                                                                  .notifier,
                                                            )
                                                            .increaseQty(
                                                              existingIndex,
                                                            ),
                                                        child: Container(
                                                          height: 34,
                                                          decoration: const BoxDecoration(
                                                            color: Color(
                                                              0x121A56E8,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.only(
                                                                  topRight:
                                                                      Radius.circular(
                                                                        8,
                                                                      ),
                                                                  bottomRight:
                                                                      Radius.circular(
                                                                        8,
                                                                      ),
                                                                ),
                                                          ),
                                                          child: Icon(
                                                            Icons.add,
                                                            color: AppColors
                                                                .primary,
                                                            size: 15,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            const SizedBox(width: 6),

                                            // DELETE icon
                                            InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              onTap: () async {
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                    ),
                                                    title: const Text(
                                                      "Delete Product",
                                                    ),
                                                    content: const Text(
                                                      "Are you sure you want to delete this product?",
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
                                                                  Colors.red,
                                                            ),
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              context,
                                                              true,
                                                            ),
                                                        child: const Text(
                                                          "Delete",
                                                          style: TextStyle(
                                                            color: Colors.white,
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
                                                      .removeItem(
                                                        existingIndex,
                                                      );
                                                }
                                              },
                                              child: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
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
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          height: 70,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
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
              const SizedBox(width: 14),

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
                        color: Colors.red,
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

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${billingState.cart.length} Items",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),

                    Text(
                      "₹ ${billingState.total.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CurrentBillScreen()),
                      );
                    },
                    child: const Text(
                      "View Bill",
                      style: TextStyle(fontWeight: FontWeight.bold),
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
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── _metaChip helper (inside State class, outside build) ───────
  Widget _metaChip({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
