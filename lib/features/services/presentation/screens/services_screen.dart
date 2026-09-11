// lib/features/services/presentation/screens/services_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../settings/service_management/data/models/service_category_model.dart';

import '../providers/services_provider.dart';
import 'service_form_screen.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  final List<Color> _categoryColors = const [
    Color(0xFF2563EB),
    Color(0xFF16A34A),
    Color(0xFFEAB308),
    Color(0xFF9333EA),
    Color(0xFFEA580C),
    Color(0xFF0D9488),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getColorForIndex(int index) {
    return _categoryColors[index % _categoryColors.length];
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  List<TextSpan> _buildHighlightedTextSpans({
    required String text,
    required String query,
    required TextStyle defaultStyle,
  }) {
    final String formattedText = _capitalizeFirstLetter(text);
    if (query.isEmpty) {
      return [TextSpan(text: formattedText, style: defaultStyle)];
    }

    final List<TextSpan> spans = [];
    final lowerText = formattedText.toLowerCase();
    int start = 0;

    while (true) {
      final found = lowerText.indexOf(query, start);
      if (found == -1) break;

      if (found > start) {
        spans.add(
          TextSpan(
            text: formattedText.substring(start, found),
            style: defaultStyle,
          ),
        );
      }

      spans.add(
        TextSpan(
          text: formattedText.substring(found, found + query.length),
          style: defaultStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      );

      start = found + query.length;
    }

    if (start < formattedText.length) {
      spans.add(
        TextSpan(text: formattedText.substring(start), style: defaultStyle),
      );
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(userServiceCategoriesProvider);
    final hPad = R.hPad(context, base: 16);
    final cardRadius = R.radius(context, 14);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header App Bar ─────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: hPad.left,
                vertical: R.sp(context, 10),
              ),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.black87,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Services",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                      fontSize: R.fs(context, 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ─── Search Bar ──────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad.left),
              child: TextField(
                controller: _searchController,
                onChanged: (v) =>
                    setState(() => _search = v.trim().toLowerCase()),
                style: TextStyle(
                  fontSize: R.fs(context, 14),
                  color: const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: "Search categories...",
                  hintStyle: TextStyle(
                    fontSize: R.fs(context, 14),
                    color: const Color(0xFF94A3B8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF94A3B8),
                  ),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: Color(0xFF94A3B8),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                        )
                      : null,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: R.sp(context, 12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(R.radius(context, 12)),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(R.radius(context, 12)),
                    borderSide: const BorderSide(
                      color: AppColors.cyanDim,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ─── Categories List ─────────────────────────────────────
            Expanded(
              child: categoriesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Failed to load services: $e',
                    style: TextStyle(
                      fontSize: R.fs(context, 14),
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                data: (categories) {
                  final filteredCategories = categories.where((c) {
                    if (_search.isEmpty) return true;
                    return c.name.toLowerCase().contains(_search);
                  }).toList();

                  if (filteredCategories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.miscellaneous_services_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "No categories available",
                            style: TextStyle(
                              fontSize: R.fs(context, 16),
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      ref.invalidate(userServiceCategoriesProvider);
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: hPad.left,
                        vertical: R.sp(context, 6),
                      ),
                      itemCount: filteredCategories.length,
                      itemBuilder: (context, index) {
                        final category = filteredCategories[index];
                        final categoryColor = _getColorForIndex(index);

                        return Container(
                          margin: EdgeInsets.only(bottom: R.sp(context, 12)),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(cardRadius),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(cardRadius),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CategoryServicesViewScreen(
                                      category: category,
                                      categoryColor: categoryColor,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: EdgeInsets.all(R.sp(context, 14)),
                                child: Row(
                                  children: [
                                    Container(
                                      width: R.sp(context, 42),
                                      height: R.sp(context, 42),
                                      decoration: BoxDecoration(
                                        color: categoryColor,
                                        borderRadius: BorderRadius.circular(
                                          R.radius(context, 10),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.apps_outlined,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text.rich(
                                            TextSpan(
                                              children:
                                                  _buildHighlightedTextSpans(
                                                    text: category.name,
                                                    query: _search,
                                                    defaultStyle: TextStyle(
                                                      fontSize: R.fs(
                                                        context,
                                                        15,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: const Color(
                                                        0xFF0F172A,
                                                      ),
                                                    ),
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${category.servicesCount} Services',
                                            style: TextStyle(
                                              fontSize: R.fs(context, 12),
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 22,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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
}

// ─── Screen: Category Services List View ─────────────────────────────
class CategoryServicesViewScreen extends ConsumerStatefulWidget {
  final ServiceCategoryModel category;
  final Color categoryColor;

  const CategoryServicesViewScreen({
    super.key,
    required this.category,
    required this.categoryColor,
  });

  @override
  ConsumerState<CategoryServicesViewScreen> createState() =>
      _CategoryServicesViewScreenState();
}

class _CategoryServicesViewScreenState
    extends ConsumerState<CategoryServicesViewScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // HOME → DASHBOARD
  // ─────────────────────────────────────────────
  void _goToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  List<TextSpan> _buildHighlightedTextSpans({
    required String text,
    required String query,
    required TextStyle defaultStyle,
  }) {
    final String formattedText = _capitalizeFirstLetter(text);
    if (query.isEmpty) {
      return [TextSpan(text: formattedText, style: defaultStyle)];
    }

    final List<TextSpan> spans = [];
    final lowerText = formattedText.toLowerCase();
    int start = 0;

    while (true) {
      final found = lowerText.indexOf(query, start);
      if (found == -1) break;

      if (found > start) {
        spans.add(
          TextSpan(
            text: formattedText.substring(start, found),
            style: defaultStyle,
          ),
        );
      }

      spans.add(
        TextSpan(
          text: formattedText.substring(found, found + query.length),
          style: defaultStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      );

      start = found + query.length;
    }

    if (start < formattedText.length) {
      spans.add(
        TextSpan(text: formattedText.substring(start), style: defaultStyle),
      );
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(
      servicesForCategoryProvider(widget.category.id),
    );
    final hPad = R.hPad(context, base: 16);
    final cardRadius = R.radius(context, 14);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header Top Bar ───
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: hPad.left,
                vertical: R.sp(context, 10),
              ),
              child: Row(
                children: [
                  // BACK BUTTON
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.black87,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),

                  const SizedBox(width: 12),

                  // TITLE
                  Expanded(
                    child: Text(
                      _capitalizeFirstLetter(widget.category.name),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        fontSize: R.fs(context, 18),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // HOME BUTTON - RIGHT CORNER
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(
                        R.radius(context, 10),
                      ),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.home_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      tooltip: 'Dashboard',
                      onPressed: _goToDashboard,
                    ),
                  ),
                ],
              ),
            ),

            // ─── Search Bar ───
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad.left),
              child: TextField(
                controller: _searchController,
                onChanged: (v) =>
                    setState(() => _search = v.trim().toLowerCase()),
                style: TextStyle(
                  fontSize: R.fs(context, 14),
                  color: const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: "Search services...",
                  hintStyle: TextStyle(
                    fontSize: R.fs(context, 14),
                    color: const Color(0xFF94A3B8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF94A3B8),
                  ),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: Color(0xFF94A3B8),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                        )
                      : null,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: R.sp(context, 12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(R.radius(context, 12)),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(R.radius(context, 12)),
                    borderSide: const BorderSide(
                      color: AppColors.cyanDim,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ─── Services List ───
            Expanded(
              child: servicesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Failed to load services: $e',
                    style: TextStyle(
                      fontSize: R.fs(context, 14),
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                data: (services) {
                  final filteredServices = services.where((s) {
                    if (_search.isEmpty) return true;
                    return s.name.toLowerCase().contains(_search);
                  }).toList();

                  if (filteredServices.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notes_rounded,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _search.isEmpty
                                ? "No services in this category yet"
                                : "No matching services found",
                            style: TextStyle(
                              fontSize: R.fs(context, 16),
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: hPad.left,
                      vertical: R.sp(context, 6),
                    ),
                    itemCount: filteredServices.length,
                    itemBuilder: (context, index) {
                      final service = filteredServices[index];

                      return Container(
                        margin: EdgeInsets.only(bottom: R.sp(context, 10)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(cardRadius),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(cardRadius),
                            onTap: () {
                              if (service.id != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ServiceFormScreen(
                                      serviceId: service.id!,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: R.sp(context, 16),
                                vertical: R.sp(context, 14),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: R.sp(context, 38),
                                    height: R.sp(context, 38),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(
                                        R.radius(context, 8),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.notes_rounded,
                                      size: 20,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text.rich(
                                      TextSpan(
                                        children: _buildHighlightedTextSpans(
                                          text: service.name,
                                          query: _search,
                                          defaultStyle: TextStyle(
                                            fontSize: R.fs(context, 15),
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
