import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/db_helper.dart';
import 'add_product_screen.dart';
import 'product_details_screen.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_provider.dart';
import '../../../../core/constants/app_curve.dart';

class ProductScreen extends ConsumerStatefulWidget {
  const ProductScreen({super.key});

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  int currentIndex = 1;
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];

  int total = 0;
  int inStock = 0;
  int lowStock = 0;
  int outStock = 0;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    final data = await DBHelper.getAllProducts();

    products = data;
    applyFilters();
  }

  void openAddScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );

    if (result == true) {
      loadProducts();
    }
  }

  void applyFilters() {
    List<Map<String, dynamic>> temp = List.from(products);

    // 🔍 SEARCH
    final currentSearch = ref.read(searchQueryProvider);

    if (currentSearch.isNotEmpty) {
      temp = temp.where((p) {
        return p["name"].toString().toLowerCase().contains(
          currentSearch.toLowerCase(),
        );
      }).toList();
    }

    // 📊 TOTAL
    total = products.length;

    // ✅ IN STOCK
    inStock = products.where((p) {
      int qty = p["quantity"] ?? 0;
      int lsl = p["lsl"] ?? 10;

      return qty > lsl;
    }).length;

    // ⚠️ LOW STOCK
    lowStock = products.where((p) {
      int qty = p["quantity"] ?? 0;
      int lsl = p["lsl"] ?? 10;

      return qty > 0 && qty <= lsl;
    }).length;

    // ❌ OUT OF STOCK
    outStock = products.where((p) {
      int qty = p["quantity"] ?? 0;
      return qty <= 0;
    }).length;

    // =========================
    // FILTERS
    // =========================
    final currentFilter = ref.read(selectedFilterProvider);

    if (currentFilter == "In Stock") {
      temp = temp.where((p) {
        int qty = p["quantity"] ?? 0;
        int lsl = p["lsl"] ?? 10;

        return qty > lsl;
      }).toList();
    } else if (currentFilter == "Low Stock") {
      temp = temp.where((p) {
        int qty = p["quantity"] ?? 0;
        int lsl = p["lsl"] ?? 10;

        return qty > 0 && qty <= lsl;
      }).toList();
    } else if (currentFilter == "Out Of Stock") {
      temp = temp.where((p) {
        int qty = p["quantity"] ?? 0;
        return qty <= 0;
      }).toList();
    }

    temp.sort(
      (a, b) => (a["name"] ?? "").toString().toLowerCase().compareTo(
        (b["name"] ?? "").toString().toLowerCase(),
      ),
    );

    filteredProducts = temp;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final selectedFilter = ref.watch(selectedFilterProvider);

    final searchQuery = ref.watch(searchQueryProvider);

    final filterNotifier = ref.read(selectedFilterProvider.notifier);

    final searchNotifier = ref.read(searchQueryProvider.notifier);
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Products",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: openAddScreen,
          ),
        ],
      ),

      // ================= BODY =================
      body: Container(
        color: AppColors.primary,
        child: ClipRRect(
          borderRadius: AppCurve.top(context),
          child: Container(
            color: const Color(0xffF5F6FA),
            child: Column(
              children: [
                const SizedBox(height: 14),

                // Fixed missing container wrapper for the Search field here
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (val) {
                        ref.read(searchQueryProvider.notifier).state = val;
                        applyFilters();
                      },
                      decoration: InputDecoration(
                        hintText: "Search products...",
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ================= FILTERS =================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.start,
                    children: [
                      _filterTab("All", total),
                      _filterTab("In Stock", inStock),
                      _filterTab("Low Stock", lowStock),
                      _filterTab("Out Of Stock", outStock),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ================= PRODUCT LIST =================
                Expanded(
                  child: filteredProducts.isEmpty
                      ? const Center(
                          child: Text(
                            "No Products Found",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: filteredProducts.length,
                          itemBuilder: (_, index) {
                            final p = filteredProducts[index];
                            final qty = p["quantity"] ?? 0;
                            final bool isLowStock = qty > 0 && qty <= 15;
                            final bool isOutStock = qty == 0;

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailsScreen(product: p),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ================= IMAGE =================
                                    Container(
                                      width: width * 0.20,
                                      height: width * 0.20,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        color: Colors.grey.shade100,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child:
                                            p["image_path"] != null &&
                                                p["image_path"] != ""
                                            ? Image.file(
                                                File(p["image_path"]),
                                                fit: BoxFit.cover,
                                              )
                                            : const Icon(
                                                Icons.inventory_2,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                      ),
                                    ),

                                    const SizedBox(width: 14),

                                    // ================= DETAILS =================
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // ================= NAME + PRICE =================
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  p["name"] ?? "",
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "₹ ${(p["selling_price"] as num?)?.toDouble().toStringAsFixed(0) ?? "0"}",
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 6),

                                          // ================= CATEGORY =================
                                          Text(
                                            p["category"] ?? "",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),

                                          const SizedBox(height: 10),

                                          // ================= STOCK ROW =================
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              // STOCK COUNT
                                              Text(
                                                "Stock: $qty pcs",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: isOutStock
                                                      ? Colors.red
                                                      : isLowStock
                                                      ? Colors.orange
                                                      : Colors.green,
                                                ),
                                              ),

                                              // ================= BADGE =================
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isOutStock
                                                      ? Colors.red.withOpacity(
                                                          0.12,
                                                        )
                                                      : isLowStock
                                                      ? Colors.orange
                                                            .withOpacity(0.12)
                                                      : Colors.green
                                                            .withOpacity(0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                  border: Border.all(
                                                    color: isOutStock
                                                        ? Colors.red
                                                        : isLowStock
                                                        ? Colors.orange
                                                        : Colors.green,
                                                  ),
                                                ),
                                                child: Text(
                                                  isOutStock
                                                      ? "Out of Stock"
                                                      : isLowStock
                                                      ? "Low Stock"
                                                      : "In Stock",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: isOutStock
                                                        ? Colors.red
                                                        : isLowStock
                                                        ? Colors.orange
                                                        : Colors.green,
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
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterTab(String title, int count) {
    final isSelected = ref.read(selectedFilterProvider) == title;

    return GestureDetector(
      onTap: () {
        ref.read(selectedFilterProvider.notifier).state = title;
        applyFilters();
      },

      child: Container(
        margin: const EdgeInsets.only(right: 4),

        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),

        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),

        child: Text(
          "$title ($count)",

          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,

            color: isSelected ? AppColors.primary : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
