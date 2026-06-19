import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/db_helper.dart';
import 'add_product_screen.dart';
import 'product_details_screen.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_provider.dart';
import '../../../../core/constants/app_curve.dart';
import '../../../../core/utils/responsive_helper.dart';

class ProductScreen extends ConsumerStatefulWidget {
  const ProductScreen({super.key});

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  int currentIndex = 1;
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];

  int totalCount = 0;
  int inStockCount = 0;
  int lowStockCount = 0;
  int outOfStockCount = 0;

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

    // ========================================================
    // 📊 CALCULATE MASTER COUNTS FROM INITIAL PRODUCTS
    // ========================================================
    final calculatedTotal = products.length;

    final calculatedInStock = products.where((p) {
      int qty = p["quantity"] ?? 0;
      int lsl = p["lsl"] ?? 10;
      return qty > lsl;
    }).length;

    final calculatedLowStock = products.where((p) {
      int qty = p["quantity"] ?? 0;
      int lsl = p["lsl"] ?? 10;
      return qty > 0 && qty <= lsl;
    }).length;

    final calculatedOutOfStock = products.where((p) {
      int qty = p["quantity"] ?? 0;
      return qty <= 0;
    }).length;

    // ========================================================
    // ⚙️ APPLY SELECTED STATUS FILTER TO RENDER LIST
    // ========================================================
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

    // ========================================================
    // 🔄 UPDATE UI STATE AT THE SAME TIME
    // ========================================================
    setState(() {
      filteredProducts = temp;
      totalCount = calculatedTotal;
      inStockCount = calculatedInStock;
      lowStockCount = calculatedLowStock;
      outOfStockCount = calculatedOutOfStock;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final selectedFilter = ref.watch(selectedFilterProvider);
    // ignore: unused_local_variable
    final searchQuery = ref.watch(searchQueryProvider);
    // ignore: unused_local_variable
    final filterNotifier = ref.read(selectedFilterProvider.notifier);
    // ignore: unused_local_variable
    final searchNotifier = ref.read(searchQueryProvider.notifier);

    // ── responsive values ──────────────────────────────────────
    final hPad = R.hPad(context, base: 16);
    final imgSz = R.imgSize(context, 0.16);
    final searchHeight = R.searchH(context);
    final nameFs = R.fs(context, 14);
    final priceFs = R.fs(context, 14);
    final catFs = R.fs(context, 10);
    final stockFs = R.fs(context, 11);
    final badgeFs = R.fs(context, 10);
    final cardRadius = R.radius(context, 10);
    final cardPad = R.sp(context, 10);
    final vGap = R.sp(context, 6);

    return Scaffold(
      backgroundColor: Colors.white,

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Products",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white,
            fontSize: R.fs(context, 18),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: Colors.white,
              size: R.icon(context, 24),
            ),
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
            color: Colors.white,
            child: Column(
              children: [
                SizedBox(height: R.sp(context, 14)),

                // ── Search bar ──────────────────────────────────
                Padding(
                  padding: hPad,
                  child: Container(
                    height: searchHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        R.radius(context, 12),
                      ),
                      border: Border.all(color: Colors.grey.shade300, width: 1),

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
                      style: TextStyle(fontSize: R.fs(context, 14)),
                      decoration: InputDecoration(
                        hintText: "Search products...",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: R.fs(context, 14),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: R.icon(context, 22),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: R.sp(context, 14),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: R.sp(context, 14)),

                // =========================
                // 🔹 EQUAL-WIDTH FILTER ROW (NO SCROLL)
                // =========================
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: R.fluid(context, 14, 18),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _filterTab("All", totalCount)),
                      SizedBox(width: R.sp(context, 4)),
                      Expanded(child: _filterTab("In Stock", inStockCount)),
                      SizedBox(width: R.sp(context, 4)),
                      Expanded(child: _filterTab("Low Stock", lowStockCount)),
                      SizedBox(width: R.sp(context, 4)),
                      Expanded(
                        child: _filterTab("Out Of Stock", outOfStockCount),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: R.sp(context, 12)),

                // ================= PRODUCT LIST =================
                Expanded(
                  child: filteredProducts.isEmpty
                      ? Center(
                          child: Text(
                            "No Products Found",
                            style: TextStyle(
                              fontSize: R.fs(context, 16),
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.only(bottom: R.sp(context, 16)),
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
                                margin: EdgeInsets.symmetric(
                                  horizontal: hPad.left,
                                  vertical: R.sp(context, 8),
                                ),
                                padding: EdgeInsets.all(cardPad),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    cardRadius,
                                  ),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ================= IMAGE =================
                                    Container(
                                      width: imgSz,
                                      height: imgSz,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          R.radius(context, 8),
                                        ),
                                        color: Colors.grey.shade100,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          R.radius(context, 14),
                                        ),
                                        child:
                                            p["image_path"] != null &&
                                                p["image_path"] != ""
                                            ? Image.file(
                                                File(p["image_path"]),
                                                fit: BoxFit.cover,
                                              )
                                            : Icon(
                                                Icons.inventory_2,
                                                size: R.icon(context, 40),
                                                color: Colors.grey,
                                              ),
                                      ),
                                    ),

                                    SizedBox(width: R.sp(context, 14)),

                                    // ================= DETAILS =================
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // NAME + PRICE
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
                                                  style: TextStyle(
                                                    fontSize: nameFs,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: R.sp(context, 8)),
                                              Text(
                                                "₹ ${(p["selling_price"] as num?)?.toDouble().toStringAsFixed(0) ?? "0"}",
                                                style: TextStyle(
                                                  fontSize: priceFs,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),

                                          SizedBox(height: vGap),

                                          // CATEGORY
                                          Text(
                                            p["category"] ?? "",
                                            style: TextStyle(
                                              fontSize: catFs,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),

                                          SizedBox(height: R.sp(context, 10)),

                                          // STOCK ROW
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Stock: $qty pcs",
                                                style: TextStyle(
                                                  fontSize: stockFs,
                                                  fontWeight: FontWeight.w500,
                                                  color: isOutStock
                                                      ? Colors.red
                                                      : isLowStock
                                                      ? Colors.orange
                                                      : Colors.green,
                                                ),
                                              ),

                                              // BADGE
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: R.sp(context, 5),
                                                  vertical: R.sp(context, 2),
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
                                                    fontSize: badgeFs,
                                                    fontWeight:
                                                        FontWeight.normal,
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
    final isSelected = ref.watch(selectedFilterProvider) == title;

    // Shorten the string structure to guarantee space for the count bracket
    String displayTitle = title;
    if (title == "Low Stock") displayTitle = "Low";
    if (title == "Out Of Stock") displayTitle = "Out";

    return GestureDetector(
      onTap: () {
        ref.read(selectedFilterProvider.notifier).state = title;
        applyFilters();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: R.sp(context, 2),
          vertical: R.sp(context, 8),
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(R.radius(context, 25)),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          "$displayTitle ($count)",
          maxLines: 1,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: R.fs(context, 11),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primary : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
