// lib/features/services/presentation/screens/services_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../settings/service_management/data/models/service_category_model.dart';
import '../../../settings/service_management/data/models/service_provider_model.dart';
import '../../../settings/service_management/domain/enums/service_category_type.dart';

import '../providers/provider_recharge_provider.dart';
import '../providers/services_provider.dart';
import 'provider_recharge_form_screen.dart';
import 'service_form_screen.dart';

// ═══════════════════════════════════════════════════════
// SERVICES  —  SERVICE | PROVIDER
//
// Same split as the admin Services & Categories screen: a category
// belongs to one tab only, decided by `category.type`. Tapping a
// Service category opens its services; tapping a Provider category
// opens its providers (balance + health), which is where a recharge
// starts.
//
// There is no flat "every provider, no category" list here anymore
// — providers are reached the same way services are: through their
// category, so both tabs behave identically from the user's side.
// ═══════════════════════════════════════════════════════

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  // Search starts CLOSED — only the icon shows until it's tapped.
  bool _searchOpen = false;

  ServiceCategoryType _tab = ServiceCategoryType.service;

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

  // ─────────────────────────────────────────────
  // Close the search field: clears the typed text and drops the
  // filter. Called whenever we come back to this screen from
  // somewhere else (or switch tabs / hit back), so a search left
  // open on a previous visit never lingers into the next one — it
  // only ever shows up right after you tap the icon.
  // ─────────────────────────────────────────────
  void _clearSearch() {
    if (!mounted) return;
    if (!_searchOpen && _search.isEmpty && _searchController.text.isEmpty) {
      return;
    }

    setState(() {
      _searchOpen = false;
      _search = '';
      _searchController.clear();
    });
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

  // ─────────────────────────────────────────────
  // SERVICE | PROVIDER TABS
  // ─────────────────────────────────────────────
  Widget _buildTabBar(BuildContext context) {
    Widget tab(ServiceCategoryType type) {
      final selected = _tab == type;

      return Expanded(
        child: GestureDetector(
          onTap: () {
            if (_tab == type) return;

            setState(() {
              _tab = type;

              // The two tabs hold different categories, so a search
              // typed on one should not silently filter the other.
              _searchOpen = false;
              _search = '';
              _searchController.clear();
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: EdgeInsets.symmetric(vertical: R.sp(context, 10)),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(R.radius(context, 9)),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              type.tabLabel,
              style: TextStyle(
                fontSize: R.fs(context, 13.5),
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.primary : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(R.sp(context, 4)),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(R.radius(context, 11)),
      ),
      child: Row(
        children: [
          tab(ServiceCategoryType.service),
          tab(ServiceCategoryType.provider),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = _tab.isProvider
        ? ref.watch(userProviderTypeCategoriesProvider)
        : ref.watch(userServiceTypeCategoriesProvider);

    final hPad = R.hPad(context, base: 16);
    final cardRadius = R.radius(context, 14);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header App Bar ─────────────────────────────────────
            //
            // Search starts CLOSED — only the icon shows. Tapping it
            // opens the typing pad in place of the title. It closes
            // itself again (text cleared) when the user taps the
            // close icon, the back button, or switches tabs — a
            // fresh search is always what you get next time you tap
            // the icon. Leaving the screen entirely (see
            // _clearSearch, called after every push) closes it too.
            // ─────────────────────────────────────────────────────
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
                    onPressed: () {
                      _clearSearch();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 12),

                  // TITLE — swapped for the search field while open
                  Expanded(
                    child: _searchOpen
                        ? TextField(
                            controller: _searchController,
                            autofocus: true,
                            onChanged: (v) {
                              setState(() => _search = v.trim().toLowerCase());
                            },
                            style: TextStyle(
                              fontSize: R.fs(context, 15),
                              color: const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: "Search ${_tab.tabLabel.toLowerCase()} "
                                  "categories...",
                              hintStyle: TextStyle(
                                fontSize: R.fs(context, 15),
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          )
                        : Text(
                            "Services",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                              fontSize: R.fs(context, 20),
                            ),
                          ),
                  ),

                  const SizedBox(width: 8),

                  // SEARCH TOGGLE
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      _searchOpen ? Icons.close_rounded : Icons.search_rounded,
                      color: const Color(0xFF475569),
                      size: 22,
                    ),
                    onPressed: () {
                      if (_searchOpen) {
                        _clearSearch();
                      } else {
                        setState(() => _searchOpen = true);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ─── Service | Provider tabs ──────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad.left),
              child: _buildTabBar(context),
            ),
            const SizedBox(height: 12),

            // ─── Categories List (current tab only) ───────────────────
            Expanded(
              child: categoriesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad.left),
                    child: Text(
                      'Failed to load: $e',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: R.fs(context, 14),
                        color: Colors.grey.shade700,
                      ),
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
                            _tab.isProvider
                                ? Icons.account_balance_wallet_outlined
                                : Icons.miscellaneous_services_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _search.isEmpty
                                ? "No ${_tab.tabLabel.toLowerCase()} "
                                    "categories available"
                                : "No matching categories found",
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
                                    builder: (_) => category.type.isProvider
                                        ? CategoryProvidersViewScreen(
                                            category: category,
                                            categoryColor: categoryColor,
                                          )
                                        : CategoryServicesViewScreen(
                                            category: category,
                                            categoryColor: categoryColor,
                                          ),
                                  ),
                                ).then((_) => _clearSearch());
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
                                      child: Icon(
                                        category.type.isProvider
                                            ? Icons.bolt_rounded
                                            : Icons.apps_outlined,
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
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(
                                                    0xFF0F172A,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          // "3 Services" on the Service tab,
                                          // "3 Providers" on the Provider tab.
                                          Text(
                                            category.itemCountLabel,
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

// ═══════════════════════════════════════════════════════
// SCREEN: CATEGORY SERVICES VIEW  (unchanged behaviour)
// ═══════════════════════════════════════════════════════
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

  // Search starts CLOSED — only the icon shows until it's tapped.
  bool _searchOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Close the search field: clears the typed text and drops the
  // filter. Called whenever we come back to this screen from
  // somewhere else, so a search left open on a previous visit
  // never lingers into the next one.
  // ─────────────────────────────────────────────
  void _clearSearch() {
    if (!mounted) return;
    if (!_searchOpen && _search.isEmpty && _searchController.text.isEmpty) {
      return;
    }

    setState(() {
      _searchOpen = false;
      _search = '';
      _searchController.clear();
    });
  }

  void _goToDashboard() {
    Navigator.popUntil(context, (route) => route.isFirst);
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
            //
            // Same collapsible search as the parent screen: the icon
            // is all you see until it's tapped, and it snaps shut
            // (text cleared) on close, back, or home.
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
                    onPressed: () {
                      _clearSearch();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 12),

                  // TITLE — swapped for the search field while open
                  Expanded(
                    child: _searchOpen
                        ? TextField(
                            controller: _searchController,
                            autofocus: true,
                            onChanged: (v) {
                              setState(() => _search = v.trim().toLowerCase());
                            },
                            style: TextStyle(
                              fontSize: R.fs(context, 15),
                              color: const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: "Search services...",
                              hintStyle: TextStyle(
                                fontSize: R.fs(context, 15),
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          )
                        : Text(
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

                  const SizedBox(width: 8),

                  // SEARCH TOGGLE
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      _searchOpen ? Icons.close_rounded : Icons.search_rounded,
                      color: const Color(0xFF475569),
                      size: 22,
                    ),
                    onPressed: () {
                      if (_searchOpen) {
                        _clearSearch();
                      } else {
                        setState(() => _searchOpen = true);
                      }
                    },
                  ),

                  const SizedBox(width: 8),

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
                      onPressed: () {
                        _clearSearch();
                        _goToDashboard();
                      },
                    ),
                  ),
                ],
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
                                ).then((_) => _clearSearch());
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

// ═══════════════════════════════════════════════════════
// SCREEN: CATEGORY PROVIDERS VIEW  (new — mirrors the screen above)
//
// Same shell as CategoryServicesViewScreen, listing providers of
// this category instead of services. Balance and health are shown
// on the tile; tapping a provider opens the recharge form.
// ═══════════════════════════════════════════════════════
class CategoryProvidersViewScreen extends ConsumerStatefulWidget {
  final ServiceCategoryModel category;
  final Color categoryColor;

  const CategoryProvidersViewScreen({
    super.key,
    required this.category,
    required this.categoryColor,
  });

  @override
  ConsumerState<CategoryProvidersViewScreen> createState() =>
      _CategoryProvidersViewScreenState();
}

class _CategoryProvidersViewScreenState
    extends ConsumerState<CategoryProvidersViewScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  // Search starts CLOSED — only the icon shows until it's tapped.
  bool _searchOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Close the search field: clears the typed text and drops the
  // filter. Called whenever we come back to this screen from
  // somewhere else, so a search left open on a previous visit
  // never lingers into the next one.
  // ─────────────────────────────────────────────
  void _clearSearch() {
    if (!mounted) return;
    if (!_searchOpen && _search.isEmpty && _searchController.text.isEmpty) {
      return;
    }

    setState(() {
      _searchOpen = false;
      _search = '';
      _searchController.clear();
    });
  }

  void _goToDashboard() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  static String _money(double value) {
    final whole = value.toStringAsFixed(2).split('.').first;
    final buffer = StringBuffer();

    for (var i = 0; i < whole.length; i++) {
      buffer.write(whole[i]);

      final remaining = whole.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
    }

    return '\u20B9${buffer.toString()}';
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
    final providersAsync = ref.watch(
      userProvidersByCategoryProvider(widget.category.id),
    );
    final hPad = R.hPad(context, base: 16);
    final cardRadius = R.radius(context, 14);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header Top Bar ───
            //
            // Same collapsible search as the other screens: the icon
            // is all you see until it's tapped, and it snaps shut
            // (text cleared) on close, back, or home.
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
                    onPressed: () {
                      _clearSearch();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 12),

                  // TITLE — swapped for the search field while open
                  Expanded(
                    child: _searchOpen
                        ? TextField(
                            controller: _searchController,
                            autofocus: true,
                            onChanged: (v) {
                              setState(() => _search = v.trim().toLowerCase());
                            },
                            style: TextStyle(
                              fontSize: R.fs(context, 15),
                              color: const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: "Search providers...",
                              hintStyle: TextStyle(
                                fontSize: R.fs(context, 15),
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          )
                        : Text(
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

                  const SizedBox(width: 8),

                  // SEARCH TOGGLE
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      _searchOpen ? Icons.close_rounded : Icons.search_rounded,
                      color: const Color(0xFF475569),
                      size: 22,
                    ),
                    onPressed: () {
                      if (_searchOpen) {
                        _clearSearch();
                      } else {
                        setState(() => _searchOpen = true);
                      }
                    },
                  ),

                  const SizedBox(width: 8),

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
                      onPressed: () {
                        _clearSearch();
                        _goToDashboard();
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ─── Providers List ───
            Expanded(
              child: providersAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Failed to load providers: $e',
                    style: TextStyle(
                      fontSize: R.fs(context, 14),
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                data: (providers) {
                  final filteredProviders = providers.where((p) {
                    if (_search.isEmpty) return true;
                    return p.name.toLowerCase().contains(_search);
                  }).toList();

                  if (filteredProviders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _search.isEmpty
                                ? "No providers in this category yet"
                                : "No matching providers found",
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
                      ref.invalidate(
                        userProvidersByCategoryProvider(widget.category.id),
                      );
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: hPad.left,
                        vertical: R.sp(context, 6),
                      ),
                      itemCount: filteredProviders.length,
                      itemBuilder: (context, index) {
                        final ServiceProviderModel provider =
                            filteredProviders[index];
                        final low = provider.isLowBalance;

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
                                if (provider.id == null) return;

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProviderRechargeFormScreen(
                                      providerId: provider.id!,
                                    ),
                                  ),
                                ).then((_) => _clearSearch());
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
                                        color: widget.categoryColor,
                                        borderRadius: BorderRadius.circular(
                                          R.radius(context, 8),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.bolt_rounded,
                                        size: 20,
                                        color: Colors.white,
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
                                                text: provider.name,
                                                query: _search,
                                                defaultStyle: TextStyle(
                                                  fontSize: R.fs(context, 15),
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(
                                                    0xFF0F172A,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            provider.healthLabel,
                                            style: TextStyle(
                                              fontSize: R.fs(context, 11.5),
                                              fontWeight: FontWeight.w700,
                                              color: low
                                                  ? const Color(0xFFDC2626)
                                                  : const Color(0xFF16A34A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _money(provider.balance),
                                          style: TextStyle(
                                            fontSize: R.fs(context, 15),
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Balance',
                                          style: TextStyle(
                                            fontSize: R.fs(context, 11),
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
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
