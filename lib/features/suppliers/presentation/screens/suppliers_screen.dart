import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/db_helper.dart';
import 'add_supplier_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/supplier_provider.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
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

    final count = await DBHelper.getSuppliersCount();

    final categories = data.map((e) => e["category"]).toSet().length;

    // 🔹 GET TOTAL PURCHASE AMOUNT
    final purchaseAmount = await DBHelper.getTotalPurchaseAmount();
    ref.read(suppliersProvider.notifier).state = data;

    ref.read(totalSuppliersProvider.notifier).state = count;

    ref.read(totalCategoriesProvider.notifier).state = categories;

    ref.read(totalProductsProvider.notifier).state = count;

    ref.read(totalPurchasesProvider.notifier).state = purchaseAmount;
  }
  // =========================
  // 🔹 TOP CARD
  // =========================

  Widget _topCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(AppSizes.cardRadius),

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
            radius: 22,

            backgroundColor: color.withOpacity(0.12),

            child: Icon(icon, color: color, size: AppSizes.iconMd),
          ),

          const SizedBox(width: 12),

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
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(AppSizes.cardRadius),

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
            radius: 28,

            backgroundColor: AppColors.primary.withOpacity(0.1),

            child: Text(
              supplier["supplierName"][0].toUpperCase(),

              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  supplier["supplierName"],

                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  supplier["category"],

                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(
                      Icons.phone,
                      size: AppSizes.iconSm,
                      color: AppColors.primary,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      supplier["contactNumber"],

                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Icon(
            Icons.arrow_forward_ios,
            size: AppSizes.iconSm,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  // =========================
  // 🔹 BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(suppliersProvider);

    final totalSuppliers = ref.watch(totalSuppliersProvider);

    final totalCategories = ref.watch(totalCategoriesProvider);

    final totalProducts = ref.watch(totalProductsProvider);

    final totalPurchases = ref.watch(totalPurchasesProvider);
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,

        title: const Text(
          "Suppliers",

          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),

        actions: [
          // IconButton(
          //   onPressed: () {},

          //   icon: const Icon(Icons.search, color: Colors.white),
          // ),
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

            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // =========================
            // 🔹 TOP CARDS
            // =========================
            GridView.count(
              shrinkWrap: true,

              physics: const NeverScrollableScrollPhysics(),

              crossAxisCount: 2,

              crossAxisSpacing: AppSizes.gridSpacing,

              mainAxisSpacing: AppSizes.gridSpacing,

              childAspectRatio: 1.8,

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

            const SizedBox(height: 24),

            // =========================
            // 🔹 HEADER
            // =========================
            Row(
              children: [
                const Text(
                  "Supplier List",

                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const Spacer(),

                TextButton(onPressed: () {}, child: const Text("View All")),
              ],
            ),

            const SizedBox(height: 12),

            // =========================
            // 🔹 SUPPLIER LIST
            // =========================
            suppliers.isEmpty
                ? Container(
                    height: 250,

                    alignment: Alignment.center,

                    child: const Text("No Suppliers Added"),
                  )
                : ListView.builder(
                    shrinkWrap: true,

                    physics: const NeverScrollableScrollPhysics(),

                    itemCount: suppliers.length,

                    itemBuilder: (context, index) {
                      return supplierCard(suppliers[index]);
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
