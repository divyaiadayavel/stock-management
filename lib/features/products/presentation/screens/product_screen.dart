import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import 'add_product_screen.dart';
import 'product_details_screen.dart';
import 'dart:io';
import '../providers/product_provider.dart';
import '../../data/models/product_model.dart';
import '../../../../core/utils/responsive_helper.dart';
import 'dart:async';
class ProductScreen extends ConsumerStatefulWidget {
  const ProductScreen({super.key});

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  bool _showTopButton = false;
  Timer? _searchDebounce;  

  // For shimmer animation
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productListProvider.notifier).loadProducts();
    });
    _scrollController.addListener(() {
      final show = _scrollController.offset > 200;
      if (show != _showTopButton) setState(() => _showTopButton = show);

      final notifier = ref.read(productListProvider.notifier);
      final state = ref.read(productListProvider);
      if (!state.isLoadingMore && state.hasMore &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.8) {
        notifier.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  String _formatValue(double value) {
    if (value >= 100000) return "₹${(value / 100000).toStringAsFixed(1)}L";
    if (value >= 1000) return "₹${(value / 1000).toStringAsFixed(1)}K";
    return "₹${value.toStringAsFixed(0)}";
  }

  void _showSortBottomSheet() {
    final currentSort = ref.read(sortOptionProvider);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Sort by",
                  style: TextStyle(
                    fontSize: R.fs(context, 18),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...["Name (A–Z)", "Stock (Low → High)", "Value (High → Low)"].map((option) {
                final isSelected = currentSort == option;
                return ListTile(
                  leading: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                  title: Text(
                    option,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColors.primary : Colors.black87,
                    ),
                  ),
                  onTap: () {
                    ref.read(sortOptionProvider.notifier).state = option;
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ─── Shimmer Placeholder for Images ─────────────────────
  Widget _buildShimmerImage() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: const Alignment(-1.0, 0.0),
              end: const Alignment(1.0, 0.0),
              transform: GradientRotation(_shimmerController.value * 6.2832),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stateData = ref.watch(filteredProductsProvider);
    final List<Product> filteredProducts = List<Product>.from(stateData["list"] ?? []);
    final paginatedState = ref.watch(productListProvider);
    final hasMore = paginatedState.hasMore;
    final isLoadingMore = paginatedState.isLoadingMore;
    final isRefreshing = paginatedState.isRefreshing;

    final int totalCount = stateData["total"] ?? 0;
    final int inStockCount = stateData["inStock"] ?? 0;
    final int lowStockCount = stateData["lowStock"] ?? 0;
    final int outOfStockCount = stateData["outStock"] ?? 0;
    final int totalUnits = stateData["totalUnits"] ?? 0;
    final double totalValue = (stateData["totalValue"] ?? 0.0) as double;

    final hPad = R.hPad(context, base: 16);
    final imgSz = R.imgSize(context, 0.16);
    final nameFs = R.fs(context, 14);
    final priceFs = R.fs(context, 14);
    final catFs = R.fs(context, 10);
    final stockFs = R.fs(context, 11);
    final badgeFs = R.fs(context, 10);
    final cardRadius = R.radius(context, 10);
    final cardPad = R.sp(context, 10);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton : null,
      body: Stack(
  children: [
    SafeArea(
        child: Column(
          children: [
            // ─── Top Bar ──────────────────────────────────────
            Padding(
              padding: hPad,
              child: Row(
                children: [
                  Expanded(
    child: _isSearching
        ? TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (value) {
              _searchDebounce?.cancel();
              _searchDebounce = Timer(
                const Duration(milliseconds: 400),
                () {
                  ref.read(searchQueryProvider.notifier).state = value.trim();
                  ref.read(productListProvider.notifier).refresh();
                },
              );
            },
            decoration: InputDecoration(
              hintText: "Search products...",
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  _searchDebounce?.cancel();
                  ref.read(searchQueryProvider.notifier).state = '';
                  ref.read(productListProvider.notifier).refresh();
                  setState(() => _isSearching = false);
                },
              ),
            ),
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
                  if (!_isSearching)
                    Row(
                      children: [
                        _circleIconButton(
                          icon: Icons.search,
                          onTap: () => setState(() => _isSearching = true),
                        ),
                        const SizedBox(width: 8),
                        _circleIconButton(
                          icon: Icons.swap_vert,
                          label: "Sort",
                          onTap: _showSortBottomSheet,
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddProductScreen()),
                            );
                            if (result == true) {
                              ref.read(productListProvider.notifier).refresh();
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(R.sp(context, 8)),
                            decoration: const BoxDecoration(
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
            const SizedBox(height: 12),

            // ─── Stats ──────────────────────────────────────
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
                    Expanded(child: _statItem(title: "$totalCount items", value: "")),
                    _statDivider(),
                    Expanded(child: _statItem(title: "$totalUnits units", value: "")),
                    _statDivider(),
                    Expanded(child: _statItem(title: "value ${_formatValue(totalValue)}", value: "")),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ─── Filters ─────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: R.fluid(context, 14, 18)),
              child: Row(
                children: [
                  Expanded(child: _filterTab("All", totalCount)),
                  const SizedBox(width: 4),
                  Expanded(child: _filterTab("In Stock", inStockCount)),
                  const SizedBox(width: 4),
                  Expanded(child: _filterTab("Low Stock", lowStockCount)),
                  const SizedBox(width: 4),
                  Expanded(child: _filterTab("Out Of Stock", outOfStockCount)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ─── Product List ────────────────────────────────
            Expanded(
child: (paginatedState.isInitialLoading && filteredProducts.isEmpty)
    ? _buildShimmerList()
                  : filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                "No products found",
                                style: TextStyle(
                                  fontSize: R.fs(context, 18),
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () async {
                            await ref.read(productListProvider.notifier).refresh();
                          },
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.only(bottom: R.sp(context, 16)),
                            itemCount: filteredProducts.length + (hasMore || isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              // ── Loading / End indicator ──
if (index == filteredProducts.length) {
  if (isLoadingMore) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  if (hasMore) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 20,
      ),
      child: Center(
        child: TweenAnimationBuilder<double>(
  tween: Tween(begin: -3, end: 3),
  duration: const Duration(milliseconds: 900),
  curve: Curves.easeInOut,
  builder: (context, value, child) {
    return Transform.translate(
      offset: Offset(0, value),
      child: const Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 28,
        color: Colors.black26,
      ),
    );
  },
)
      ),
    );
  }

  return const SizedBox(height: 24);
}

                              final p = filteredProducts[index];
                              final qty = p.quantity;
                              final bool isLowStock = qty > 0 && qty <= p.lsl;
                              final bool isOutStock = qty == 0;

                              // ── Highlighted name ──────────
                              final String displayName = p.name;
                              final List<TextSpan> nameSpans = [];
if (searchQuery.isNotEmpty) {
  final lowerName = displayName.toLowerCase();
  final lowerQuery = searchQuery.toLowerCase();
  int start = 0;
  while (true) {
    final found = lowerName.indexOf(lowerQuery, start);
    if (found == -1) break;
    if (found > start) {
      nameSpans.add(TextSpan(text: displayName.substring(start, found)));
    }
    nameSpans.add(TextSpan(
      text: displayName.substring(found, found + lowerQuery.length),
      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
    ));
    start = found + lowerQuery.length;
  }
  if (start < displayName.length) {
    nameSpans.add(TextSpan(text: displayName.substring(start)));
  }
} else {
  nameSpans.add(TextSpan(text: displayName));
}

                              return GestureDetector(
                                onTap: () async {
                                  // Pre-cache image for detail view
                                  if (p.imagePath.startsWith('http')) {
                                    await precacheImage(
                                      CachedNetworkImageProvider(p.imagePath),
                                      context,
                                    );
                                  }
                                  if (!mounted) return;
                                  final checkRefresh = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailsScreen(product: p),
                                    ),
                                  );
                                  if (checkRefresh == true && mounted) {
                                    ref.read(productListProvider.notifier).refresh();
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
                                    border: Border.all(color: Colors.grey.shade300, width: 1),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // ── Image with Hero and Shimmer ──
                                      Hero(
                                        tag: 'product_${p.id}',
                                        child: Container(
                                          width: imgSz,
                                          height: imgSz,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(R.radius(context, 8)),
                                            color: Colors.grey.shade100,
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(R.radius(context, 14)),
                                            child: p.imagePath.isNotEmpty
                                                ? (p.imagePath.startsWith('http')
                                                    ? CachedNetworkImage(
                                                        imageUrl: p.imagePath,
                                                        fit: BoxFit.cover,
                                                        placeholder: (_, __) =>
                                                            _buildShimmerImage(),
                                                        errorWidget: (_, __, ___) =>
                                                            const Icon(Icons.broken_image,
                                                                color: Colors.grey),
                                                      )
                                                    : Image.file(
                                                        File(p.imagePath),
                                                        fit: BoxFit.cover,
                                                      ))
                                                : Icon(
                                                    Icons.inventory_2,
                                                    size: R.icon(context, 40),
                                                    color: Colors.grey,
                                                  ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),

                                      // ── Details ────────────
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Text.rich(
                                                    TextSpan(children: nameSpans),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: nameFs,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  "₹ ${p.sellingPrice.toStringAsFixed(0)}",
                                                  style: TextStyle(
                                                    fontSize: priceFs,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              p.category,
                                              style: TextStyle(
                                                  fontSize: catFs,
                                                  color: Colors.grey.shade600),
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  "Stock: $qty ${p.unit}",
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
                                                        ? Colors.red.withValues(alpha: 0.12)
                                                        : isLowStock
                                                            ? Colors.orange
                                                                .withValues(alpha: 0.12)
                                                            : Colors.green
                                                                .withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(30),
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
            ),
          ],
      ),
    ),

    if (_showTopButton)
      Positioned(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        left: 0,
        right: 0,
        child: Center(
          child: GestureDetector(
            onTap: () {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
              );
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.black54,
                size: 26,
              ),
            ),
          ),
        ),
      ),
  ],
),
    );
  }

  // ─── Helper widgets ──────────────────────────────────────

  Widget _circleIconButton({required IconData icon, String? label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: R.sp(context, 10), vertical: R.sp(context, 8)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(R.radius(context, 30)),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: R.icon(context, 16), color: Colors.black87),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: R.fs(context, 12), color: Colors.black87)),
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
              color: Colors.black87),
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
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: R.sp(context, 2), vertical: R.sp(context, 8)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.brandGradient : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(R.radius(context, 25)),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
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

  // ─── Shimmer Skeleton for Initial Loading ──────────────
  Widget _buildShimmerList() {
    return ListView.builder(
      padding: EdgeInsets.only(bottom: R.sp(context, 16)),
      itemCount: 6,
      itemBuilder: (_, __) {
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: R.sp(context, 16),
            vertical: R.sp(context, 8),
          ),
          padding: EdgeInsets.all(R.sp(context, 10)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(R.radius(context, 10)),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: R.imgSize(context, 0.16),
                height: R.imgSize(context, 0.16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(R.radius(context, 8)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 12,
                      width: 100,
                      color: Colors.grey.shade200,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          height: 12,
                          width: 80,
                          color: Colors.grey.shade200,
                        ),
                        const Spacer(),
                        Container(
                          height: 20,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}