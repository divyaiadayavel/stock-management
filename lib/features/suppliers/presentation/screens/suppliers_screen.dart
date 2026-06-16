import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/db_helper.dart';
import 'add_supplier_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/supplier_provider.dart';
import '../../../../core/constants/app_curve.dart';
import 'supplier_details_screen.dart';
import '../../../../core/utils/responsive_helper.dart'; // ← add this import

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  List<Map<String, dynamic>> filteredSuppliers = [];
  String searchText = '';

  @override
  void initState() {
    super.initState();
    loadSuppliers();
  }

  // =========================
  // 🔹 LOAD SUPPLIERS
  // =========================
  Future<void> loadSuppliers() async {
    final data = await DBHelper.getSuppliers();
    final supplierCount = await DBHelper.getSupplierCount();
    final productCount = await DBHelper.getProductCount();
    final categories = data.map((e) => e["category"]).toSet().length;
    final purchaseAmount = await DBHelper.getTotalPurchaseAmount();

    ref.read(suppliersProvider.notifier).state = data;
    ref.read(totalSuppliersProvider.notifier).state = supplierCount;
    ref.read(totalCategoriesProvider.notifier).state = categories;
    ref.read(totalProductsProvider.notifier).state = productCount;
    ref.read(totalPurchasesProvider.notifier).state = purchaseAmount;
  }

  // =========================
  // 🔹 TOP CARD (FIXED HORIZONTAL LAYOUT)
  // =========================
  Widget _topCard(String title, String value, IconData icon, Color color) {
    return Container(
      // Fluid padding shrinks gracefully on smaller devices to prevent squeezing layout elements
      padding: EdgeInsets.all(R.fluid(context, 10, 16)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(
          R.radius(context, AppSizes.cardRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: R.fluid(
              context,
              18,
              26,
            ), // Scaled down slightly to guarantee room for text
            backgroundColor: color.withOpacity(0.20),
            child: Icon(
              icon,
              color: color,
              size: R.icon(context, AppSizes.iconMd),
            ),
          ),

          SizedBox(width: R.fluid(context, 6, 12)), // Scaled down gap

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: R.fs(
                        context,
                        16,
                      ), // Sized down base from 18 to 16 for better data fitment
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),

                SizedBox(height: R.sp(context, 2)),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines:
                        1, // Set to 1 line inside a scale-down box to absolutely prevent text spill
                    style: TextStyle(
                      fontSize: R.fs(
                        context,
                        11,
                      ), // Baseline at 11 fits beautifully
                      color: Colors.black.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // 🔹 SUPPLIER CARD
  // =========================
  Widget supplierCard(Map<String, dynamic> supplier) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SupplierDetailsScreen(supplier: supplier),
          ),
        );
        if (result == true) {
          loadSuppliers();
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: R.sp(context, 14)),
        padding: EdgeInsets.all(R.sp(context, 14)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            R.radius(context, AppSizes.cardRadius),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: R.fluid(context, 28, 38),
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                supplier["supplierName"][0].toUpperCase(),
                style: TextStyle(
                  fontSize: R.fs(context, 22),
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),

            SizedBox(width: R.sp(context, 14)),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplier["supplierName"],
                    style: TextStyle(
                      fontSize: R.fs(context, 17),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: R.sp(context, 4)),
                  Text(
                    supplier["category"],
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: R.fs(context, 13),
                    ),
                  ),
                  SizedBox(height: R.sp(context, 8)),
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: R.icon(context, AppSizes.iconSm),
                        color: AppColors.primary,
                      ),
                      SizedBox(width: R.sp(context, 5)),
                      Text(
                        supplier["contactNumber"],
                        style: TextStyle(fontSize: R.fs(context, 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              size: R.icon(context, AppSizes.iconSm),
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // 🔹 BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(filteredSuppliersProvider);
    final totalSuppliers = ref.watch(totalSuppliersProvider);
    final totalCategories = ref.watch(totalCategoriesProvider);
    final totalProducts = ref.watch(totalProductsProvider);
    final totalPurchases = ref.watch(totalPurchasesProvider);

    // ── responsive values ──────────────────────────────────────
    final hPad = R.hPad(context, base: 16);
    final gridCols = R.gridCols(context, phone: 2, tablet: 4, desktop: 4);
    final gridRatio = R.gridRatio(
      context,
      phone: 1.8,
      tablet: 2.0,
      desktop: 2.2,
    );

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          "Suppliers",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: R.fs(context, 18),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddSupplierScreen()),
              );
              if (result == true) {
                loadSuppliers();
              }
            },
            icon: Icon(
              Icons.add,
              color: Colors.white,
              size: R.icon(context, 24),
            ),
          ),
        ],
      ),

      body: Container(
        color: AppColors.primary,
        child: ClipRRect(
          borderRadius: AppCurve.top(context),
          child: Container(
            color: Colors.grey.shade100,
            child: SingleChildScrollView(
              padding: hPad.copyWith(
                top: R.sp(context, 16),
                bottom: R.sp(context, 16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================== SEARCH BAR ====================
                  Container(
                    height: R.searchH(context),
                    margin: EdgeInsets.only(bottom: R.sp(context, 16)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        R.radius(context, 14),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) {
                        ref.read(searchSupplierProvider.notifier).state = value;
                      },
                      style: TextStyle(fontSize: R.fs(context, 14)),
                      decoration: InputDecoration(
                        hintText: "Search suppliers...",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: R.fs(context, 14),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey,
                          size: R.icon(context, 22),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: R.sp(context, 14),
                        ),
                      ),
                    ),
                  ),

                  // =========================
                  // 🔹 TOP CARDS (OVERFLOW-PROOF)
                  // =========================
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: R.gridCols(
                      context,
                      phone: 2,
                      tablet: 2,
                      desktop: 4,
                    ),
                    crossAxisSpacing: R.sp(context, 12),
                    mainAxisSpacing: R.sp(context, 12),
                    // Updated aspect ratio properties: a slightly larger phone ratio gives cards more horizontal room to breathe
                    childAspectRatio: R.gridRatio(
                      context,
                      phone: 1.5,
                      tablet: 1.6,
                      desktop: 1.8,
                    ),
                    children: [
                      _topCard(
                        "Total Suppliers",
                        "$totalSuppliers",
                        Icons.people,
                        Colors.blue,
                      ),
                      _topCard(
                        "Categories",
                        "$totalCategories",
                        Icons.category,
                        Colors.orange,
                      ),
                      _topCard(
                        "Total Products",
                        "$totalProducts",
                        Icons.inventory,
                        Colors.green,
                      ),
                      _topCard(
                        "Purchases",
                        "₹${totalPurchases.toStringAsFixed(0)}",
                        Icons.shopping_cart,
                        Colors.purple,
                      ),
                    ],
                  ),

                  SizedBox(height: R.sp(context, 24)),

                  // =========================
                  // 🔹 HEADER
                  // =========================
                  Row(
                    children: [
                      Text(
                        "Supplier List",
                        style: TextStyle(
                          fontSize: R.fs(context, 20),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          "View All",
                          style: TextStyle(fontSize: R.fs(context, 14)),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: R.sp(context, 12)),

                  // =========================
                  // 🔹 SUPPLIER LIST
                  // =========================
                  suppliers.isEmpty
                      ? Container(
                          height: R.fluid(context, 200, 300),
                          alignment: Alignment.center,
                          child: Text(
                            "No Suppliers Added",
                            style: TextStyle(fontSize: R.fs(context, 14)),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: suppliers.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SupplierDetailsScreen(
                                      supplier: suppliers[index],
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  loadSuppliers();
                                }
                              },
                              child: supplierCard(suppliers[index]),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
