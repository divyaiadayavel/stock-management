import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/db_helper.dart';
import 'add_supplier_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/supplier_provider.dart';
// import '../../../../core/constants/app_curve.dart';
import 'supplier_details_screen.dart';
import '../../../../core/utils/responsive_helper.dart';
import 'package:url_launcher/url_launcher.dart'; // ← add url_launcher to pubspec.yaml

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  String selectedCategoryFilter = "All";

  final List<String> categoryFilters = [
    "All",
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
    loadSuppliers();
  }

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

    applyCategoryFilter();
  }

  void applyCategoryFilter() async {
    final data = await DBHelper.getSuppliers();
    if (selectedCategoryFilter == "All") {
      ref.read(suppliersProvider.notifier).state = data;
    } else {
      ref.read(suppliersProvider.notifier).state = data.where((s) {
        final cats = (s["category"] as String?)?.split(",") ?? [];
        return cats.any((c) => c.trim() == selectedCategoryFilter);
      }).toList();
    }
  }

  // ── Launch phone dialer ──────────────────────────────────────
  Future<void> _makeCall(String contactNumber) async {
    final cleaned = contactNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not launch dialer for $contactNumber"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Stat card (top row) ──────────────────────────────────────
  Widget _statCard(String label, String value, {Color? valueColor}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: R.sp(context, 14),
          vertical: R.sp(context, 12),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(R.radius(context, 12)),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: R.fs(context, 11),
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: R.sp(context, 4)),
            Text(
              value,
              style: TextStyle(
                fontSize: R.fs(context, 20),
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppColors.textPrimaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Supplier row card ────────────────────────────────────────
  Widget _supplierCard(Map<String, dynamic> supplier) {
    final name = supplier["supplierName"] ?? "";
    final category = supplier["category"] ?? "";
    final contact = (supplier["contactNumber"] as String?) ?? "";
    final double dueAmount = (supplier["dueAmount"] as num?)?.toDouble() ?? 0.0;
    final int leadDays = (supplier["leadDays"] as num?)?.toInt() ?? 0;
    final bool hasDue = dueAmount > 0;

    final parts = name.trim().split(" ");
    final initials = parts.length >= 2
        ? "${parts[0][0]}${parts[1][0]}".toUpperCase()
        : name.isNotEmpty
        ? name[0].toUpperCase()
        : "?";

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SupplierDetailsScreen(supplier: supplier),
          ),
        );
        if (result == true) loadSuppliers();
      },
      child: Container(
        margin: EdgeInsets.only(bottom: R.sp(context, 10)),
        padding: EdgeInsets.symmetric(
          horizontal: R.sp(context, 14),
          vertical: R.sp(context, 12),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(R.radius(context, 12)),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: R.fluid(context, 44, 56),
              height: R.fluid(context, 44, 56),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.brandGradient,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: R.fs(context, 13),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            SizedBox(width: R.sp(context, 12)),

            // Name + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: R.fs(context, 14),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  SizedBox(height: R.sp(context, 2)),
                  Text(
                    leadDays > 0
                        ? "$category · lead $leadDays day${leadDays == 1 ? '' : 's'}"
                        : category,
                    style: TextStyle(
                      fontSize: R.fs(context, 11),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Right: due / settled + Call button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hasDue ? "due ₹${_formatAmount(dueAmount)}" : "settled",
                  style: TextStyle(
                    fontSize: R.fs(context, 12),
                    fontWeight: FontWeight.w600,
                    color: hasDue ? AppColors.orange : AppColors.green,
                  ),
                ),
                SizedBox(height: R.sp(context, 6)),

                // ── Call button with phone icon ──────────────
                GestureDetector(
                  onTap: () => _makeCall(contact),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: R.sp(context, 10),
                      vertical: R.sp(context, 5),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.phone,
                          size: R.icon(context, 12),
                          color: AppColors.textPrimaryDark,
                        ),
                        SizedBox(width: R.sp(context, 4)),
                        Text(
                          "Call",
                          style: TextStyle(
                            fontSize: R.fs(context, 11),
                            color: AppColors.textPrimaryDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) return "${(amount / 100000).toStringAsFixed(1)}L";
    if (amount >= 1000) return "${(amount / 1000).toStringAsFixed(0)}k";
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(filteredSuppliersProvider);
    final totalSuppliers = ref.watch(totalSuppliersProvider);
    final totalPurchases = ref.watch(totalPurchasesProvider);
    final hPad = R.hPad(context, base: 16);

    return Scaffold(
      backgroundColor: AppColors.background,

      body: SingleChildScrollView(
        padding: hPad.copyWith(
          top: R.sp(context, 30),
          bottom: R.sp(context, 24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Suppliers",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimaryDark,
                      fontSize: R.fs(context, 18),
                    ),
                  ),
                ),

                IconButton(
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: _SupplierSearchDelegate(suppliers),
                    );
                  },
                  icon: Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: R.icon(context, 22),
                  ),
                ),

                IconButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddSupplierScreen(),
                      ),
                    );
                    if (result == true) loadSuppliers();
                  },
                  icon: Container(
                    width: R.fluid(context, 28, 32),
                    height: R.fluid(context, 28, 32),
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: R.icon(context, 18),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: R.sp(context, 20)),

            // ── Stat cards ───────────────────────────────────
            Row(
              children: [
                _statCard("Suppliers", "$totalSuppliers"),
                SizedBox(width: R.sp(context, 12)),
                _statCard(
                  "Payable",
                  "₹${_formatAmount(totalPurchases)}",
                  valueColor: AppColors.primary,
                ),
              ],
            ),

            SizedBox(height: R.sp(context, 20)),

            // ── Category filter chips ─────────────────────────
            SizedBox(
              height: R.fluid(context, 34, 40),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categoryFilters.length,
                separatorBuilder: (_, __) => SizedBox(width: R.sp(context, 8)),
                itemBuilder: (context, index) {
                  final cat = categoryFilters[index];
                  final selected = cat == selectedCategoryFilter;
                  return GestureDetector(
                    onTap: () {
                      setState(() => selectedCategoryFilter = cat);
                      applyCategoryFilter();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: R.sp(context, 14),
                        vertical: R.sp(context, 6),
                      ),
                      decoration: BoxDecoration(
                        gradient: selected ? AppColors.brandGradient : null,
                        color: selected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? Colors.transparent
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: R.fs(context, 12),
                          fontWeight: FontWeight.normal,
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: R.sp(context, 10)),

            // ── Supplier list ─────────────────────────────────
            suppliers.isEmpty
                ? SizedBox(
                    height: R.fluid(context, 200, 300),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: R.icon(context, 48),
                            color: AppColors.textSecondary.withOpacity(0.4),
                          ),
                          SizedBox(height: R.sp(context, 12)),
                          Text(
                            "No suppliers added yet",
                            style: TextStyle(
                              fontSize: R.fs(context, 14),
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: suppliers.length,
                    itemBuilder: (context, index) =>
                        _supplierCard(suppliers[index]),
                  ),
          ],
        ),
      ),
    );
  }
}

// ── Simple search delegate ────────────────────────────────────────
class _SupplierSearchDelegate extends SearchDelegate<Map<String, dynamic>?> {
  final List<Map<String, dynamic>> suppliers;
  _SupplierSearchDelegate(this.suppliers);
  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      scaffoldBackgroundColor: AppColors.background,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),

      dividerColor: AppColors.border,

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey, width: 1.5),
        ),
      ),

      iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),

      textTheme: Theme.of(context).textTheme.copyWith(
        titleLarge: const TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ""),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    final results = suppliers
        .where(
          (s) =>
              (s["supplierName"] ?? "").toString().toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              (s["category"] ?? "").toString().toLowerCase().contains(
                query.toLowerCase(),
              ),
        )
        .toList();

    if (results.isEmpty) {
      return Container(
        color: AppColors.background,
        child: const Center(
          child: Text(
            "No suppliers found",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      color: AppColors.background,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final s = results[index];
          return Card(
            color: Colors.white,
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.brandGradient,
                ),
                alignment: Alignment.center,
                child: Text(
                  (s["supplierName"] ?? "?")[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              title: Text(
                s["supplierName"] ?? "",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              subtitle: Text(
                s["category"] ?? "",
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
              onTap: () async {
                close(context, null);

                await Future.delayed(const Duration(milliseconds: 150));

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SupplierDetailsScreen(supplier: s),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
