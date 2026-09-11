// lib/features/settings/service_management/presentation/screens/services_categories_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/responsive_helper.dart';

// Dashboard
import '../../../../dashboard/presentation/screens/dashboard_screen.dart';

import '../../data/models/service_category_model.dart';
import '../../data/models/service_model.dart';
import '../providers/service_management_provider.dart';
import 'add_edit_service_screen.dart';

class ServicesCategoriesScreen extends ConsumerStatefulWidget {
  const ServicesCategoriesScreen({super.key});

  @override
  ConsumerState<ServicesCategoriesScreen> createState() =>
      _ServicesCategoriesScreenState();
}

class _ServicesCategoriesScreenState
    extends ConsumerState<ServicesCategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  final List<Color> _categoryColors = const [
    Color(0xFF2563EB),
    Color(0xFF16A34A),
    Color(0xFF9333EA),
    Color(0xFFEAB308),
    Color(0xFFEA580C),
    Color(0xFF0D9488),
  ];

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

      if (found == -1) {
        break;
      }

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

  // ─────────────────────────────────────────────
  // DELETE CATEGORY
  // ─────────────────────────────────────────────
  Future<void> _confirmDeleteCategory(ServiceCategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(R.radius(context, 16)),
        ),
        title: Text(
          'Delete category?',
          style: TextStyle(
            fontSize: R.fs(context, 18),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This removes "${category.name}" and all associated services.',
          style: TextStyle(
            fontSize: R.fs(context, 13),
            color: Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(serviceCategoriesProvider.notifier)
          .removeCategory(category.id);
    }
  }

  // ─────────────────────────────────────────────
  // ADD CATEGORY
  // ─────────────────────────────────────────────
  Future<void> _showAddCategoryDialog() async {
    final TextEditingController nameController = TextEditingController();

    final TextEditingController descriptionController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(R.radius(context, 16)),
        ),
        title: Text(
          'Add Category',
          style: TextStyle(
            fontSize: R.fs(context, 18),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Name',
              style: TextStyle(
                fontSize: R.fs(context, 13),
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 6),

            TextField(
              controller: nameController,
              autofocus: true,
              style: TextStyle(
                fontSize: R.fs(context, 14),
                color: const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'Enter category name',
                hintStyle: TextStyle(
                  fontSize: R.fs(context, 14),
                  color: const Color(0xFF94A3B8),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: R.sp(context, 12),
                  vertical: R.sp(context, 12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(R.radius(context, 10)),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(R.radius(context, 10)),
                  borderSide: const BorderSide(
                    color: AppColors.cyanDim,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            Text(
              'Description / Note (Optional)',
              style: TextStyle(
                fontSize: R.fs(context, 13),
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 6),

            TextField(
              controller: descriptionController,
              maxLines: 3,
              style: TextStyle(
                fontSize: R.fs(context, 14),
                color: const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'Enter description or note',
                hintStyle: TextStyle(
                  fontSize: R.fs(context, 14),
                  color: const Color(0xFF94A3B8),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: EdgeInsets.all(R.sp(context, 12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(R.radius(context, 10)),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(R.radius(context, 10)),
                  borderSide: const BorderSide(
                    color: AppColors.cyanDim,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: R.fs(context, 14),
                color: Colors.grey.shade700,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: Text(
              'Add',
              style: TextStyle(
                fontSize: R.fs(context, 14),
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final name = nameController.text.trim();

      if (name.isNotEmpty) {
        await ref.read(serviceCategoriesProvider.notifier).addCategory(name);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);
    final servicesAsync = ref.watch(allServicesProvider);

    final hPad = R.hPad(context, base: 16);
    final cardRadius = R.radius(context, 14);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      body: SafeArea(
        child: Column(
          children: [
            // ─────────────────────────────────────────
            // HEADER
            // ─────────────────────────────────────────
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

                  const SizedBox(width: 14),

                  // TITLE
                  Expanded(
                    child: Text(
                      "Services & Categories",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        fontSize: R.fs(context, 18),
                      ),
                    ),
                  ),

                  // HOME BUTTON - RIGHT SIDE
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

            // ─────────────────────────────────────────
            // SEARCH BAR
            // ─────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad.left),
              child: TextField(
                controller: _searchController,
                onChanged: (v) {
                  setState(() => _search = v.trim().toLowerCase());
                },
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

                            setState(() {
                              _search = '';
                            });
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

            // ─────────────────────────────────────────
            // CATEGORIES LIST
            // ─────────────────────────────────────────
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
                    'Failed to load: $e',
                    style: TextStyle(
                      fontSize: R.fs(context, 14),
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),

                data: (categories) {
                  final services =
                      servicesAsync.asData?.value ?? const <ServiceModel>[];

                  final filteredCategories = categories.where((category) {
                    if (_search.isEmpty) {
                      return true;
                    }

                    return category.name.toLowerCase().contains(_search);
                  }).toList();

                  if (filteredCategories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),

                          const SizedBox(height: 12),

                          Text(
                            "No categories found",
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
                    itemCount: filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = filteredCategories[index];

                      final categoryColor = _getColorForIndex(index);

                      final categoryServicesCount = services
                          .where((s) => s.categoryId == category.id)
                          .length;

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
                                  builder: (_) => CategoryServicesListScreen(
                                    category: category,
                                    categoryColor: categoryColor,
                                  ),
                                ),
                              );
                            },
                            onLongPress: () => _confirmDeleteCategory(category),
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
                                      Icons.article_outlined,
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
                                                    fontSize: R.fs(context, 15),
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(
                                                      0xFF0F172A,
                                                    ),
                                                  ),
                                                ),
                                          ),
                                        ),

                                        const SizedBox(height: 3),

                                        Text(
                                          '$categoryServicesCount Services',
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
                  );
                },
              ),
            ),

            // ─────────────────────────────────────────
            // ADD CATEGORY BUTTON
            // ─────────────────────────────────────────
            Padding(
              padding: EdgeInsets.all(hPad.left),
              child: GestureDetector(
                onTap: () => _showAddCategoryDialog(),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: R.sp(context, 14)),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(R.radius(context, 12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, size: 18, color: Colors.white),

                      const SizedBox(width: 6),

                      Text(
                        'Add Category',
                        style: TextStyle(
                          fontSize: R.fs(context, 14),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// CATEGORY SERVICES LIST SCREEN
// ═══════════════════════════════════════════════════════

class CategoryServicesListScreen extends ConsumerStatefulWidget {
  final ServiceCategoryModel category;
  final Color categoryColor;

  const CategoryServicesListScreen({
    super.key,
    required this.category,
    required this.categoryColor,
  });

  @override
  ConsumerState<CategoryServicesListScreen> createState() =>
      _CategoryServicesListScreenState();
}

class _CategoryServicesListScreenState
    extends ConsumerState<CategoryServicesListScreen> {
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

      if (found == -1) {
        break;
      }

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

  // ─────────────────────────────────────────────
  // DELETE SERVICE
  // ─────────────────────────────────────────────
  Future<void> _confirmDeleteService(ServiceModel service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(R.radius(context, 16)),
        ),
        title: Text(
          'Delete service?',
          style: TextStyle(
            fontSize: R.fs(context, 18),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${service.name}"?',
          style: TextStyle(
            fontSize: R.fs(context, 13),
            color: Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && service.id != null) {
      await ref
          .read(serviceOperationsProvider.notifier)
          .removeService(service.id!);

      ref.invalidate(allServicesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(allServicesProvider);

    final hPad = R.hPad(context, base: 16);
    final cardRadius = R.radius(context, 14);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      body: SafeArea(
        child: Column(
          children: [
            // ─────────────────────────────────────────
            // HEADER
            // ─────────────────────────────────────────
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

                  const SizedBox(width: 14),

                  // CATEGORY NAME
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

                  // HOME BUTTON - RIGHT SIDE
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

            // ─────────────────────────────────────────
            // SEARCH BAR
            // ─────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad.left),
              child: TextField(
                controller: _searchController,
                onChanged: (v) {
                  setState(() => _search = v.trim().toLowerCase());
                },
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

                            setState(() {
                              _search = '';
                            });
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

            // ─────────────────────────────────────────
            // SERVICES LIST
            // ─────────────────────────────────────────
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

                data: (allServices) {
                  final categoryServices = allServices
                      .where((s) => s.categoryId == widget.category.id)
                      .where(
                        (s) =>
                            _search.isEmpty ||
                            s.name.toLowerCase().contains(_search),
                      )
                      .toList();

                  if (categoryServices.isEmpty) {
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
                    itemCount: categoryServices.length,
                    itemBuilder: (context, index) {
                      final service = categoryServices[index];

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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddEditServiceScreen(
                                    existingServiceId: service.id,
                                  ),
                                ),
                              );
                            },
                            onLongPress: () => _confirmDeleteService(service),
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

            // ─────────────────────────────────────────
            // ADD SERVICE BUTTON
            // ─────────────────────────────────────────
            Padding(
              padding: EdgeInsets.all(hPad.left),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditServiceScreen(
                      presetCategoryId: widget.category.id,
                      presetCategoryName: widget.category.name,
                    ),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: R.sp(context, 14)),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(R.radius(context, 12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, size: 18, color: Colors.white),

                      const SizedBox(width: 6),

                      Text(
                        'Add Service',
                        style: TextStyle(
                          fontSize: R.fs(context, 14),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
