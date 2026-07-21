import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stock_management/core/constants/app_colors.dart';
import 'package:stock_management/core/network/api_config.dart';
import 'package:stock_management/core/utils/responsive_helper.dart';
import 'package:stock_management/core/utils/notification_utils.dart';
import '../../domain/entities/supplier.dart';
import '../providers/supplier_provider.dart';
import '../providers/add_supplier_provider.dart';
import 'add_supplier_screen.dart';
import 'supplier_details_screen.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  String selectedCategoryFilter = "All";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(suppliersNotifierProvider.notifier).fetchAllSuppliers(refresh: true);
    });
  }

  Future<void> _makeCall(String contactNumber) async {
    final cleaned = contactNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        showCustomNotification(
          context,
          "Could not launch dialer for $contactNumber",
          isError: true,
        );
      }
    }
  }

  Widget _statCard(String label, String value, IconData icon, {Color? valueColor}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: R.sp(context, 16),
          vertical: R.sp(context, 14),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(R.radius(context, 16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: R.fs(context, 11),
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: R.sp(context, 6)),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: R.fs(context, 22),
                      fontWeight: FontWeight.bold,
                      color: valueColor ?? AppColors.textPrimaryDark,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(R.sp(context, 8)),
              decoration: BoxDecoration(
                color: (valueColor ?? AppColors.primary).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: R.icon(context, 20),
                color: valueColor ?? AppColors.primary,
              ),
            )
          ],
        ),
      ),
    );
  }

  bool _hasValidImage(String? image) {
    return image != null && image.isNotEmpty && (image.contains('/') || image.contains('.'));
  }

Widget _supplierCard(Supplier supplier) {
    final name = supplier.supplierName;
    final contact = supplier.phone ?? "";
    final category = (supplier.country != null && supplier.country!.isNotEmpty)
        ? supplier.country!
        : "General";
    final double dueAmount = supplier.currentBalance;

    final parts = name.trim().split(" ");
    final initials = parts.length >= 2
        ? "${parts[0][0]}${parts[1][0]}".toUpperCase()
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : "?";

    final bool hasValidImage = _hasValidImage(supplier.image);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SupplierDetailsScreen(supplier: supplier),
          ),
        );
        if (result == true && mounted) {
          ref.read(suppliersNotifierProvider.notifier).fetchAllSuppliers(refresh: true);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: R.sp(context, 8)), // Reduced from 12 to 8
        padding: EdgeInsets.symmetric(
          horizontal: R.sp(context, 12), // Reduced from 16 to 12
          vertical: R.sp(context, 10),   // Reduced from 14 to 10 for smaller card height
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(R.radius(context, 12)), // Reduced from 16 to 12
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015), // Softened shadow
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: R.fluid(context, 38, 44),  // Reduced size from (48, 56) to (38, 44)
              height: R.fluid(context, 38, 44), // Reduced size from (48, 56) to (38, 44)
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: !hasValidImage ? AppColors.brandGradient : null,
                image: hasValidImage
                    ? DecorationImage(
                        image: NetworkImage('${ApiConfig.baseUrl}/${supplier.image}'),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: !hasValidImage
                  ? Text(
                      initials,
                      style: TextStyle(
                        fontSize: R.fs(context, 12), // Reduced from 14 to 12
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: R.sp(context, 12)), // Compressed spacing
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Forces column down to absolute content height
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: R.fs(context, 14), // Balanced down from 15 to 14
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  SizedBox(height: R.sp(context, 2)),
                  Row(
                    children: [
                      Icon(Icons.layers_outlined, size: 12, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                      SizedBox(width: R.sp(context, 4)),
                      Expanded(
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: R.fs(context, 11), // Clean micro-typography
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: R.sp(context, 8)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: R.sp(context, 8), vertical: R.sp(context, 3)), // Slim padding bounds
                  decoration: BoxDecoration(
                    color: dueAmount > 0 ? AppColors.orange.withValues(alpha: 0.08) : AppColors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    dueAmount > 0 ? "Due ₹${_formatAmount(dueAmount)}" : "Settled",
                    style: TextStyle(
                      fontSize: R.fs(context, 11), // Compact micro alignment
                      fontWeight: FontWeight.bold,
                      color: dueAmount > 0 ? AppColors.orange : AppColors.green,
                    ),
                  ),
                ),
                SizedBox(height: R.sp(context, 4)), // Reduced vertical column gap
                GestureDetector(
                  onTap: () => _makeCall(contact),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: R.sp(context, 10),
                      vertical: R.sp(context, 4), // Slimmer action button padding
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.phone,
                          size: R.icon(context, 10), // Scaled down phone icon metric
                          color: AppColors.primary,
                        ),
                        SizedBox(width: R.sp(context, 4)),
                        Text(
                          "Call",
                          style: TextStyle(
                            fontSize: R.fs(context, 11),
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
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
    final hPad = R.hPad(context, base: 16);
    final providerState = ref.watch(suppliersNotifierProvider);
    final asyncCategories = ref.watch(dbCategoriesProvider);

    final List<String> categoryFilters = ["All", ...(asyncCategories.value ?? [])];

    final displayList = selectedCategoryFilter == "All"
        ? providerState.suppliers
        : providerState.suppliers
            .where((s) => (s.country ?? "").contains(selectedCategoryFilter))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: hPad.copyWith(
          top: R.sp(context, 40),
          bottom: R.sp(context, 24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // ✅ UI/UX Optimization: Added absolute back button icon matching navigation contracts
IconButton(
  onPressed: () => Navigator.pop(context),
  icon: Icon(
    Icons.arrow_back,
    color: AppColors.textPrimaryDark,
    size: R.icon(context, 22),
  ),
),
                SizedBox(width: R.sp(context, 12)),
                Expanded(
                  child: Text(
                    "Suppliers",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryDark,
                      fontSize: R.fs(context, 22),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: _SupplierSearchDelegate(providerState.suppliers, ref),
                    );
                  },
                  style: IconButton.styleFrom(backgroundColor: Colors.white, elevation: 1),
                  icon: Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: R.icon(context, 20),
                  ),
                ),
                SizedBox(width: R.sp(context, 4)),
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddSupplierScreen()),
                    );
                    if (result == true && mounted) {
                      ref.read(suppliersNotifierProvider.notifier).fetchAllSuppliers(refresh: true);
                    }
                  },
                  child: Container(
                    width: R.fluid(context, 36, 40),
                    height: R.fluid(context, 36, 40),
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
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
            SizedBox(height: R.sp(context, 24)),
            Row(
              children: [
                _statCard("Active suppliers", "${providerState.suppliers.length}", Icons.people_outline),
                SizedBox(width: R.sp(context, 12)),
                _statCard(
                  "Total Payable",
                  "₹${_formatAmount(providerState.suppliers.fold(0.0, (sum, s) => sum + s.currentBalance))}",
                  Icons.account_balance_wallet_outlined,
                  valueColor: AppColors.primary,
                ),
              ],
            ),
            SizedBox(height: R.sp(context, 24)),
            SizedBox(
              height: R.fluid(context, 36, 42),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categoryFilters.length,
                separatorBuilder: (context, _) => SizedBox(width: R.sp(context, 8)),
                itemBuilder: (context, index) {
                  final cat = categoryFilters[index];
                  final selected = cat == selectedCategoryFilter;
                  return GestureDetector(
                    onTap: () => setState(() => selectedCategoryFilter = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: EdgeInsets.symmetric(
                        horizontal: R.sp(context, 16),
                        vertical: R.sp(context, 8),
                      ),
                      decoration: BoxDecoration(
                        gradient: selected ? AppColors.brandGradient : null,
                        color: selected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: selected ? Colors.transparent : AppColors.border.withValues(alpha: 0.6),
                        ),
                        boxShadow: selected ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ] : null,
                      ),
                      child: Center(
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: R.fs(context, 13),
                            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                            color: selected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: R.sp(context, 16)),
            if (providerState.isLoading && displayList.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (displayList.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.supervised_user_circle_outlined,
                          size: R.icon(context, 64),
                          color: AppColors.textSecondary.withValues(alpha: 0.3),
                        ),
                      ),
                      SizedBox(height: R.sp(context, 16)),
                      Text(
                        "No suppliers in this category",
                        style: TextStyle(
                          fontSize: R.fs(context, 15),
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayList.length,
                itemBuilder: (context, index) => _supplierCard(displayList[index]),
              ),
          ],
        ),
      ),
    );
  }
}

class _SupplierSearchDelegate extends SearchDelegate<Supplier?> {
  final List<Supplier> suppliers;
  final WidgetRef ref;
  _SupplierSearchDelegate(this.suppliers, this.ref);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(backgroundColor: AppColors.background, elevation: 0),
      dividerColor: AppColors.border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = "",
        ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back_ios_new),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  bool _hasValidImage(String? image) {
    return image != null && image.isNotEmpty && (image.contains('/') || image.contains('.'));
  }

  Widget _buildList(BuildContext context) {
    final results = suppliers.where((s) =>
        s.supplierName.toLowerCase().contains(query.toLowerCase()) ||
        (s.country ?? "").toLowerCase().contains(query.toLowerCase())).toList();

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
          final bool hasValidImage = _hasValidImage(s.image);
          final name = s.supplierName;
          final initials = name.isNotEmpty ? name[0].toUpperCase() : "?";
          return Card(
            color: Colors.white,
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: !hasValidImage ? AppColors.brandGradient : null,
                  image: hasValidImage
                      ? DecorationImage(
                          image: NetworkImage('${ApiConfig.baseUrl}/${s.image}'),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: !hasValidImage
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              title: Text(
                s.supplierName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              subtitle: Text(
                s.country ?? "General",
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.textSecondary,
              ),
              onTap: () async {
                close(context, null);
                await Future.delayed(const Duration(milliseconds: 150));
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SupplierDetailsScreen(supplier: s)),
                  ).then((_) {
                    ref.read(suppliersNotifierProvider.notifier).fetchAllSuppliers(refresh: true);
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }
}