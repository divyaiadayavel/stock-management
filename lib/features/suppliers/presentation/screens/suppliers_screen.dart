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
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(dbCategoriesProvider);
      ref
          .read(suppliersNotifierProvider.notifier)
          .fetchAllSuppliers(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Capitalize first letter helper
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
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

  String _formatAmountExact(double amount) {
    if (amount == amount.truncateToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
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
            ),
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
                      fontSize: R.fs(context, 20),
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
                color: (valueColor ?? AppColors.primary).withValues(
                  alpha: 0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: R.icon(context, 20),
                color: valueColor ?? AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasValidImage(String? image) {
    return image != null &&
        image.isNotEmpty &&
        (image.contains('/') || image.contains('.'));
  }

  Widget _highlightedName(String name, String query, TextStyle baseStyle) {
    if (query.isEmpty) {
      return Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }

    final lowerName = name.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final List<TextSpan> spans = [];
    int start = 0;

    while (true) {
      final found = lowerName.indexOf(lowerQuery, start);
      if (found == -1) break;

      if (found > start) {
        spans.add(TextSpan(text: name.substring(start, found)));
      }

      spans.add(
        TextSpan(
          text: name.substring(found, found + query.length),
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      );

      start = found + query.length;
    }

    if (start < name.length) {
      spans.add(TextSpan(text: name.substring(start)));
    }

    return Text.rich(
      TextSpan(style: baseStyle, children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _supplierCard(
    Supplier supplier,
    List<Map<String, dynamic>> dbCategories,
  ) {
    final name = _capitalizeFirstLetter(supplier.supplierName);
    final contact = supplier.phone ?? "";
    final categoryNames = dbCategories
        .where((c) => supplier.categoryIds.contains(c['id'] as int))
        .map((c) => c['name'].toString())
        .toList();
    final category = categoryNames.isNotEmpty
        ? categoryNames.join(", ")
        : "General";
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
          ref
              .read(suppliersNotifierProvider.notifier)
              .fetchAllSuppliers(refresh: true);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: R.sp(context, 8)),
        padding: EdgeInsets.symmetric(
          horizontal: R.sp(context, 12),
          vertical: R.sp(context, 10),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(R.radius(context, 12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: R.fluid(context, 38, 44),
              height: R.fluid(context, 38, 44),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: !hasValidImage ? AppColors.brandGradient : null,
                image: hasValidImage
                    ? DecorationImage(
                        image: NetworkImage(
                          '${ApiConfig.baseUrl}/${supplier.image}',
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: !hasValidImage
                  ? Text(
                      initials,
                      style: TextStyle(
                        fontSize: R.fs(context, 12),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: R.sp(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _highlightedName(
                    name,
                    _searchQuery,
                    TextStyle(
                      fontSize: R.fs(context, 14),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  SizedBox(height: R.sp(context, 2)),
                  Row(
                    children: [
                      Icon(
                        Icons.layers_outlined,
                        size: 12,
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                      ),
                      SizedBox(width: R.sp(context, 4)),
                      Expanded(
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: R.fs(context, 11),
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
                GestureDetector(
                  onTap: () => _makeCall(contact),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: R.sp(context, 10),
                      vertical: R.sp(context, 4),
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
                          size: R.icon(context, 10),
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

  @override
  Widget build(BuildContext context) {
    final hPad = R.hPad(context, base: 16);
    final providerState = ref.watch(suppliersNotifierProvider);
    final asyncCategories = ref.watch(dbCategoriesProvider);

    final List<Map<String, dynamic>> dbCategories =
        asyncCategories.value ?? const <Map<String, dynamic>>[];

    final List<String> categoryFilters = [
      "All",
      ...dbCategories
          .map((c) => c['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty),
    ];

    final double totalPayable = providerState.suppliers.fold(
      0.0,
      (sum, s) => sum + s.currentBalance,
    );

    final displayList = providerState.suppliers.where((s) {
      final matchesCategory =
          selectedCategoryFilter == "All" ||
          dbCategories.any(
            (c) =>
                c['name']?.toString() == selectedCategoryFilter &&
                s.categoryIds.contains(c['id'] as int),
          );
      final matchesQuery =
          _searchQuery.isEmpty ||
          s.supplierName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (s.phone ?? "").replaceAll(RegExp(r'\s+'), '').contains(_searchQuery);
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Fixed Header ──────────────────────────────────────────
            Padding(
              padding: hPad.copyWith(
                top: R.sp(context, 12),
                bottom: R.sp(context, 12),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimaryDark,
                      size: R.icon(context, 22),
                    ),
                  ),
                  SizedBox(width: R.sp(context, 8)),
                  Expanded(
                    child: _isSearching
                        ? TextField(
                            controller: _searchController,
                            autofocus: true,
                            onChanged: (val) {
                              setState(() => _searchQuery = val.trim());
                            },
                            decoration: InputDecoration(
                              hintText: "Search suppliers...",
                              border: InputBorder.none,
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.textSecondary,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = "";
                                    _isSearching = false;
                                  });
                                },
                              ),
                            ),
                          )
                        : Text(
                            "Suppliers",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryDark,
                              fontSize: R.fs(context, 22),
                            ),
                          ),
                  ),
                  if (!_isSearching) ...[
                    IconButton(
                      onPressed: () => setState(() => _isSearching = true),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 1,
                      ),
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
                          MaterialPageRoute(
                            builder: (_) => const AddSupplierScreen(),
                          ),
                        );
                        if (result == true && mounted) {
                          ref
                              .read(suppliersNotifierProvider.notifier)
                              .fetchAllSuppliers(refresh: true);
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
                            ),
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
                ],
              ),
            ),

            // ─── Fixed Stats Cards ─────────────────────────────────────
            Padding(
              padding: hPad,
              child: Row(
                children: [
                  _statCard(
                    "Suppliers",
                    "${providerState.suppliers.length}",
                    Icons.people_outline,
                  ),
                  SizedBox(width: R.sp(context, 12)),
                  _statCard(
                    "Total Payable",
                    "₹${_formatAmountExact(totalPayable)}",
                    Icons.account_balance_wallet_outlined,
                    valueColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            SizedBox(height: R.sp(context, 16)),

            // ─── Fixed Category Filter Chips ───────────────────────────
            SizedBox(
              height: R.fluid(context, 36, 42),
              child: ListView.separated(
                padding: hPad,
                scrollDirection: Axis.horizontal,
                itemCount: categoryFilters.length,
                separatorBuilder: (context, _) =>
                    SizedBox(width: R.sp(context, 8)),
                itemBuilder: (context, index) {
                  final cat = categoryFilters[index];
                  final selected = cat == selectedCategoryFilter;
                  return GestureDetector(
                    onTap: () => setState(() => selectedCategoryFilter = cat),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: R.sp(context, 16),
                        vertical: R.sp(context, 8),
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: selected ? AppColors.brandGradient : null,
                        color: selected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: selected
                              ? Colors.transparent
                              : AppColors.border.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: R.fs(context, 13),
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.w500,
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
            SizedBox(height: R.sp(context, 12)),

            // ─── Scrollable Supplier List Only ────────────────────────
            Expanded(
              child: providerState.isLoading && displayList.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : displayList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.05,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.supervised_user_circle_outlined,
                              size: R.icon(context, 64),
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          SizedBox(height: R.sp(context, 16)),
                          Text(
                            "No suppliers found",
                            style: TextStyle(
                              fontSize: R.fs(context, 15),
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        await ref
                            .read(suppliersNotifierProvider.notifier)
                            .fetchAllSuppliers(refresh: true);
                      },
                      child: ListView.builder(
                        padding: hPad.copyWith(bottom: R.sp(context, 24)),
                        itemCount: displayList.length,
                        itemBuilder: (context, index) =>
                            _supplierCard(displayList[index], dbCategories),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
