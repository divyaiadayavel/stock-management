import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/db_helper.dart';
import 'add_product_screen.dart';
import 'product_details_screen.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_provider.dart';
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

  int totalUnits = 0;
  double totalValue = 0;

  String currentSort = 'name_asc';

  final TextEditingController _searchCtrl = TextEditingController();
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> loadProducts() async {
    final data = await DBHelper.getAllProducts();

    products = data.map((item) {
      final mutableItem = Map<String, dynamic>.from(item);
      final rawQty = mutableItem["quantity"] ?? 0;
      if (rawQty < 0) {
        mutableItem["quantity"] = 0;
      }
      return mutableItem;
    }).toList();

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

    int calculatedUnits = 0;
    double calculatedValue = 0;
    for (final p in products) {
      final qty = (p["quantity"] ?? 0) as int;
      final price = (p["selling_price"] as num?)?.toDouble() ?? 0.0;
      calculatedUnits += qty;
      calculatedValue += qty * price;
    }

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

    // ========================================================
    // 🔄 APPLY SORT ROUTINES
    // ========================================================
    if (currentSort == 'name_asc') {
      temp.sort(
        (a, b) => (a["name"] ?? "").toString().toLowerCase().compareTo(
          (b["name"] ?? "").toString().toLowerCase(),
        ),
      );
    } else if (currentSort == 'stock_asc') {
      temp.sort(
        (a, b) => ((a["quantity"] ?? 0) as int).compareTo(
          (b["quantity"] ?? 0) as int,
        ),
      );
    } else if (currentSort == 'value_desc') {
      temp.sort((a, b) {
        final valA =
            ((a["quantity"] ?? 0) as int) *
            ((a["selling_price"] as num?)?.toDouble() ?? 0.0);
        final valB =
            ((b["quantity"] ?? 0) as int) *
            ((b["selling_price"] as num?)?.toDouble() ?? 0.0);
        return valB.compareTo(valA);
      });
    }

    setState(() {
      filteredProducts = temp;
      totalCount = calculatedTotal;
      inStockCount = calculatedInStock;
      lowStockCount = calculatedLowStock;
      outOfStockCount = calculatedOutOfStock;
      totalUnits = calculatedUnits;
      totalValue = calculatedValue;
    });
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(R.radius(context, 14)),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: R.sp(sheetContext, 16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sort by',
                style: TextStyle(
                  fontSize: R.fs(context, 16),
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: R.sp(sheetContext, 8)),
              ListTile(
                title: Text(
                  'Name (A–Z)',
                  style: TextStyle(fontSize: R.fs(context, 14)),
                ),
                trailing: currentSort == 'name_asc'
                    ? const Icon(Icons.check, color: Colors.cyan)
                    : null,
                onTap: () {
                  setState(() {
                    currentSort = 'name_asc';
                  });
                  applyFilters();
                  Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                title: Text(
                  'Stock (Low → High)',
                  style: TextStyle(fontSize: R.fs(context, 14)),
                ),
                trailing: currentSort == 'stock_asc'
                    ? const Icon(Icons.check, color: Colors.cyan)
                    : null,
                onTap: () {
                  setState(() {
                    currentSort = 'stock_asc';
                  });
                  applyFilters();
                  Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                title: Text(
                  'Value (High → Low)',
                  style: TextStyle(fontSize: R.fs(context, 14)),
                ),
                trailing: currentSort == 'value_desc'
                    ? const Icon(Icons.check, color: Colors.cyan)
                    : null,
                onTap: () {
                  setState(() {
                    currentSort = 'value_desc';
                  });
                  applyFilters();
                  Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatValue(double value) {
    if (value >= 100000) return "₹${(value / 100000).toStringAsFixed(1)}L";
    if (value >= 1000) return "₹${(value / 1000).toStringAsFixed(1)}K";
    return "₹${value.toStringAsFixed(0)}";
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

    final hPad = R.hPad(context, base: 16);
    final imgSz = R.imgSize(context, 0.16);
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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: hPad,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _searchOpen
                        ? TextField(
                            controller: _searchCtrl,
                            autofocus: true,
                            style: TextStyle(
                              fontSize: R.fs(context, 16),
                              color: Colors.black87,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Search product name...',
                              border: InputBorder.none,
                            ),
                            onChanged: (v) {
                              ref.read(searchQueryProvider.notifier).state = v;
                              applyFilters();
                            },
                          )
                        : Text(
                            "Products",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                              fontSize: R.fs(context, 22),
                            ),
                          ),
                  ),
                  Row(
                    children: [
                      _circleIconButton(
                        icon: _searchOpen ? Icons.close : Icons.search,
                        onTap: () {
                          setState(() {
                            _searchOpen = !_searchOpen;
                            if (!_searchOpen) {
                              _searchCtrl.clear();
                              ref.read(searchQueryProvider.notifier).state = '';
                              applyFilters();
                            }
                          });
                        },
                      ),
                      SizedBox(width: R.sp(context, 8)),
                      _circleIconButton(
                        icon: Icons.swap_vert,
                        label: "Sort",
                        onTap: () => _showSortSheet(context),
                      ),
                      SizedBox(width: R.sp(context, 8)),
                      GestureDetector(
                        onTap: openAddScreen,
                        child: Container(
                          padding: EdgeInsets.all(R.sp(context, 8)),
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: R.icon(context, 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: R.sp(context, 12)),

            Padding(
              padding: hPad,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: R.sp(context, 16),
                  vertical: R.sp(context, 14),
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(R.radius(context, 14)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _statItem(title: "${totalCount} items", value: ""),
                    ),
                    _statDivider(),
                    Expanded(
                      child: _statItem(title: "$totalUnits units", value: ""),
                    ),
                    _statDivider(),
                    Expanded(
                      child: _statItem(
                        title: "value ${_formatValue(totalValue)}",
                        value: "",
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: R.sp(context, 14)),

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
                  Expanded(child: _filterTab("Out Of Stock", outOfStockCount)),
                ],
              ),
            ),

            SizedBox(height: R.sp(context, 12)),

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
                          // ── FIXED: Await the response and trigger real-time list refreshing ──
                          onTap: () async {
                            final needRefresh = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailsScreen(product: p),
                              ),
                            );
                            if (needRefresh == true) {
                              loadProducts();
                            }
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: hPad.left,
                              vertical: R.sp(context, 8),
                            ),
                            padding: EdgeInsets.all(cardPad),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(cardRadius),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              p["name"] ?? "",
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
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

                                      Text(
                                        p["category"] ?? "",
                                        style: TextStyle(
                                          fontSize: catFs,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),

                                      SizedBox(height: R.sp(context, 10)),

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

                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: R.sp(context, 5),
                                              vertical: R.sp(context, 2),
                                            ),
                                            decoration: BoxDecoration(
                                              color: isOutStock
                                                  ? Colors.red.withOpacity(0.12)
                                                  : isLowStock
                                                  ? Colors.orange.withOpacity(
                                                      0.12,
                                                    )
                                                  : Colors.green.withOpacity(
                                                      0.12,
                                                    ),
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
                                                fontWeight: FontWeight.normal,
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
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    String? label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: R.sp(context, 10),
          vertical: R.sp(context, 8),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(R.radius(context, 30)),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: R.icon(context, 16), color: Colors.black87),
            if (label != null) ...[
              SizedBox(width: R.sp(context, 4)),
              Text(
                label,
                style: TextStyle(
                  fontSize: R.fs(context, 12),
                  color: Colors.black87,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statItem({required String title, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: R.fs(context, 13),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _statDivider() {
    return Container(
      height: R.sp(context, 24),
      width: 1,
      color: Colors.grey.shade300,
      margin: EdgeInsets.symmetric(horizontal: R.sp(context, 8)),
    );
  }

  Widget _filterTab(String title, int count) {
    final isSelected = ref.watch(selectedFilterProvider) == title;

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
          gradient: isSelected ? AppColors.brandGradient : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(R.radius(context, 25)),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
        child: Text(
          displayTitle == "In Stock" ? "In stock" : displayTitle,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: R.fs(context, 11),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
