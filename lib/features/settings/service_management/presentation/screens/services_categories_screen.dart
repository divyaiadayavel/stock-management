// lib/features/settings/service_management/presentation/screens/services_categories_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../../../core/utils/validators.dart';

// Dashboard
import '../../../../dashboard/presentation/screens/dashboard_screen.dart';

import '../../data/models/service_category_model.dart';
import '../../data/models/service_model.dart';
import '../../data/models/service_provider_model.dart';
import '../../domain/enums/service_category_type.dart';
import '../providers/service_management_provider.dart';
import '../providers/service_provider_provider.dart';
import 'add_edit_service_screen.dart';
import 'add_provider_screen.dart';
import 'providers_list_screen.dart';

// ═══════════════════════════════════════════════════════
// SERVICES & CATEGORIES  —  SERVICE | PROVIDER
//
// The screen is one list rendered twice under two tabs. A
// category carries a `type`, so a category added on the Service
// tab only ever appears on the Service tab, and the same for
// Provider. The count line and everything downstream follow the
// same type:
//
//   Service category  -> "3 Services",  Add Service,  no wallet
//   Provider category -> "3 Providers", Add Provider, wallet
//                        opens the balances & reload screen
// ═══════════════════════════════════════════════════════

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
  bool _searchOpen = false;

  /// Which tab is showing. Everything on this screen keys off it.
  ServiceCategoryType _tab = ServiceCategoryType.service;

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

  // ─────────────────────────────────────────────
  // HOME → DASHBOARD
  // ─────────────────────────────────────────────
  void _goToDashboard() {
    Navigator.popUntil(context, (route) => route.isFirst);
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

  void _snack(String message, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            error ? Colors.red.shade700 : const Color(0xFF16A34A),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // DELETE CATEGORY
  // ─────────────────────────────────────────────
  Future<void> _confirmDeleteCategory(ServiceCategoryModel category) async {
    final noun = category.type.itemLabelPlural.toLowerCase();

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
          'This removes "${category.name}" and all associated $noun.',
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

    if (confirmed != true) return;

    final removed = await ref
        .read(serviceCategoriesProvider.notifier)
        .removeCategory(category.id);

    if (!mounted) return;

    if (!removed) {
      // The server refuses while the category still holds live
      // services or providers — that guard is deliberate.
      _snack(
        'Could not delete "${category.name}". '
        'Remove its $noun first.',
      );
    }
  }

  // ─────────────────────────────────────────────
  // ADD CATEGORY  (validated through Validators)
  //
  // The dialog adds to whichever tab is open, so there is never a
  // question of which side the category lands on.
  // ─────────────────────────────────────────────
  Future<void> _showAddCategoryDialog() async {
    final ServiceCategoryType type = _tab;

    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController =
        TextEditingController();

    String? nameError;
    String? descriptionError;

    InputDecoration fieldDecoration(String hint, String? errorText) {
      return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: R.fs(context, 14),
          color: const Color(0xFF94A3B8),
        ),
        errorText: errorText,
        errorStyle: TextStyle(
          fontSize: R.fs(context, 11.5),
          color: Colors.red.shade700,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(R.radius(context, 10)),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(R.radius(context, 10)),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
      );
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(R.radius(context, 16)),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add ${type.tabLabel} Category',
                style: TextStyle(
                  fontSize: R.fs(context, 18),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'This category will appear on the '
                '${type.tabLabel} tab only.',
                style: TextStyle(
                  fontSize: R.fs(context, 12),
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
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
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(
                    fontSize: R.fs(context, 14),
                    color: const Color(0xFF0F172A),
                  ),
                  decoration: fieldDecoration(
                    'Enter category name',
                    nameError,
                  ),
                  onChanged: (value) {
                    if (nameError == null) return;

                    setDialogState(() {
                      nameError = Validators.validateCategoryName(value);
                    });
                  },
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
                  decoration: fieldDecoration(
                    'Enter description or note',
                    descriptionError,
                  ),
                  onChanged: (value) {
                    if (descriptionError == null) return;

                    setDialogState(() {
                      descriptionError =
                          Validators.validateDescription(value);
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
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
                final nameCheck =
                    Validators.validateCategoryName(nameController.text);

                final descriptionCheck = Validators.validateDescription(
                  descriptionController.text,
                );

                if (nameCheck != null || descriptionCheck != null) {
                  setDialogState(() {
                    nameError = nameCheck;
                    descriptionError = descriptionCheck;
                  });

                  return;
                }

                Navigator.pop(dialogContext, true);
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
      ),
    );

    if (confirmed != true) return;

    final name = Validators.normalizeName(nameController.text);

    final description =
        Validators.normalizeText(descriptionController.text);

    final added = await ref.read(serviceCategoriesProvider.notifier).addCategory(
          name,
          type: type,
          description: description.isEmpty ? null : description,
        );

    if (!mounted) return;

    if (!added) {
      _snack(
        'Could not add "$name". '
        'A ${type.tabLabel.toLowerCase()} category with that name '
        'may already exist.',
      );

      return;
    }

    // Land the user on the tab the category was added to.
    if (_tab != type) {
      setState(() => _tab = type);
    }
  }

  // ─────────────────────────────────────────────
  // SERVICE | PROVIDER TABS
  // ─────────────────────────────────────────────
  Widget _buildTabBar(BuildContext context, int serviceCount, int providerCount) {
    Widget tab(ServiceCategoryType type, int count) {
      final selected = _tab == type;

      return Expanded(
        child: GestureDetector(
          onTap: () {
            if (_tab == type) return;

            setState(() {
              _tab = type;

              // The two tabs hold different things, so a search
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  type.tabLabel,
                  style: TextStyle(
                    fontSize: R.fs(context, 13.5),
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? AppColors.primary
                        : const Color(0xFF64748B),
                  ),
                ),

                const SizedBox(width: 6),

                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: R.sp(context, 7),
                    vertical: R.sp(context, 2),
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(
                      R.radius(context, 20),
                    ),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: R.fs(context, 11),
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.primary
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
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
          tab(ServiceCategoryType.service, serviceCount),
          tab(ServiceCategoryType.provider, providerCount),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);

    final hPad = R.hPad(context, base: 16);
    final cardRadius = R.radius(context, 14);

    final allCategories =
        categoriesAsync.asData?.value ?? const <ServiceCategoryModel>[];

    final serviceCount = allCategories
        .where((c) => c.type == ServiceCategoryType.service)
        .length;

    final providerCount = allCategories
        .where((c) => c.type == ServiceCategoryType.provider)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      body: SafeArea(
        child: Column(
          children: [
            // ─────────────────────────────────────────
            // HEADER
            //
            // Search starts CLOSED — only the icon shows. Tapping it
            // opens the typing pad in place of the title. It closes
            // itself again (text cleared) when the user taps the
            // close icon, the back button, or the home button — a
            // fresh search is always what you get next time you tap
            // the icon. Leaving the screen entirely (see
            // _clearSearch, called after every push) closes it too.
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
                    onPressed: () {
                      _clearSearch();
                      Navigator.pop(context);
                    },
                  ),

                  const SizedBox(width: 14),

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
                              hintText:
                                  "Search ${_tab.tabLabel.toLowerCase()} "
                                  "categories...",
                              hintStyle: TextStyle(
                                fontSize: R.fs(context, 15),
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          )
                        : Text(
                            "Services & Categories",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                              fontSize: R.fs(context, 18),
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

                  const SizedBox(width: 8),

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
                      onPressed: () {
                        _clearSearch();
                        _goToDashboard();
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ─────────────────────────────────────────
            // SERVICE | PROVIDER TABS
            // ─────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad.left),
              child: _buildTabBar(context, serviceCount, providerCount),
            ),

            const SizedBox(height: 12),

            // ─────────────────────────────────────────
            // CATEGORIES LIST (current tab only)
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
                  final filteredCategories = categories
                      .where((category) => category.type == _tab)
                      .where((category) {
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
                            _tab.isProvider
                                ? Icons.account_balance_wallet_outlined
                                : Icons.category_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),

                          const SizedBox(height: 12),

                          Text(
                            _search.isEmpty
                                ? "No ${_tab.tabLabel.toLowerCase()} "
                                    "categories yet"
                                : "No categories found",
                            style: TextStyle(
                              fontSize: R.fs(context, 16),
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),

                          if (_search.isEmpty) ...[
                            const SizedBox(height: 6),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: R.sp(context, 40),
                              ),
                              child: Text(
                                _tab.isProvider
                                    ? 'Add one to start tracking recharge '
                                        'provider balances.'
                                    : 'Add one to start listing services.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: R.fs(context, 13),
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () =>
                        ref.read(serviceCategoriesProvider.notifier).load(),
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
                                    builder: (_) => CategoryServicesListScreen(
                                      category: category,
                                      categoryColor: categoryColor,
                                    ),
                                  ),
                                ).then((_) => _clearSearch());
                              },
                              onLongPress: () =>
                                  _confirmDeleteCategory(category),
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
                                            : Icons.article_outlined,
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
                                                  fontSize:
                                                      R.fs(context, 15),
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

            // ─────────────────────────────────────────
            // ADD CATEGORY (adds to the open tab)
            // ─────────────────────────────────────────
            Padding(
              padding: EdgeInsets.all(hPad.left),
              child: GestureDetector(
                onTap: _showAddCategoryDialog,
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
                        'Add ${_tab.tabLabel} Category',
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
// CATEGORY DETAIL SCREEN
//
// One screen, two behaviours, decided by `category.type`:
//
//   SERVICE  -> lists services,  "Add Service",  no wallet icon
//   PROVIDER -> lists providers, "Add Provider", wallet icon opens
//               the balances & reload screen
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
  bool _searchOpen = false;

  bool get _isProvider => widget.category.type.isProvider;

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

  // ─────────────────────────────────────────────
  // HOME → DASHBOARD
  // ─────────────────────────────────────────────
  void _goToDashboard() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;

    return text[0].toUpperCase() + text.substring(1);
  }

  static String money(double value) {
    final whole = value.toStringAsFixed(2).split('.').first;
    final buffer = StringBuffer();

    for (var i = 0; i < whole.length; i++) {
      buffer.write(whole[i]);

      final remaining = whole.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
    }

    return '₹${buffer.toString()}';
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
    final confirmed = await _confirmDelete(
      title: 'Delete service?',
      message: 'Are you sure you want to delete "${service.name}"?',
    );

    if (confirmed == true && service.id != null) {
      await ref
          .read(serviceOperationsProvider.notifier)
          .removeService(service.id!);

      ref.invalidate(allServicesProvider);
    }
  }

  // ─────────────────────────────────────────────
  // DELETE PROVIDER
  // ─────────────────────────────────────────────
  Future<void> _confirmDeleteProvider(ServiceProviderModel provider) async {
    final confirmed = await _confirmDelete(
      title: 'Delete provider?',
      message: 'Are you sure you want to delete "${provider.name}"? '
          'Its recharge history is kept.',
    );

    if (confirmed == true && provider.id != null) {
      await ref
          .read(providerOperationsProvider.notifier)
          .removeProvider(provider.id!);
    }
  }

  Future<bool?> _confirmDelete({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(R.radius(context, 16)),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: R.fs(context, 18),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
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
  }

  // ─────────────────────────────────────────────
  // BOTTOM ACTION BUTTON
  // ─────────────────────────────────────────────
  Widget _bottomActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
            Icon(icon, size: 18, color: Colors.white),

            const SizedBox(width: 6),

            Text(
              label,
              style: TextStyle(
                fontSize: R.fs(context, 14),
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),

          const SizedBox(height: 12),

          Text(
            message,
            textAlign: TextAlign.center,
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

  Widget _errorState(Object error, StackTrace stackTrace) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: R.sp(context, 24)),
        child: Text(
          'Failed to load: $error',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: R.fs(context, 14),
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _cardShell({
    required Widget child,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    final cardRadius = R.radius(context, 14);

    return Container(
      margin: EdgeInsets.only(bottom: R.sp(context, 10)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
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
          onTap: onTap,
          onLongPress: onLongPress,
          child: child,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SERVICE LIST BODY
  // ─────────────────────────────────────────────
  Widget _buildServicesBody(BuildContext context) {
    final servicesAsync = ref.watch(allServicesProvider);
    final hPad = R.hPad(context, base: 16);

    return servicesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        ),
      ),

      error: _errorState,

      data: (allServices) {
        final categoryServices = allServices
            .where((s) => s.categoryId == widget.category.id)
            .where(
              (s) =>
                  _search.isEmpty || s.name.toLowerCase().contains(_search),
            )
            .toList();

        if (categoryServices.isEmpty) {
          return _emptyState(
            Icons.notes_rounded,
            _search.isEmpty
                ? "No services in this category yet"
                : "No matching services found",
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.invalidate(allServicesProvider),
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: hPad.left,
              vertical: R.sp(context, 6),
            ),
            itemCount: categoryServices.length,
            itemBuilder: (context, index) {
              final service = categoryServices[index];

              return _cardShell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditServiceScreen(
                        existingServiceId: service.id,
                      ),
                    ),
                  ).then((_) => _clearSearch());
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
              );
            },
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // PROVIDER LIST BODY
  // ─────────────────────────────────────────────
  Widget _buildProvidersBody(BuildContext context) {
    final providersAsync =
        ref.watch(providersByCategoryProvider(widget.category.id));

    final hPad = R.hPad(context, base: 16);

    return providersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        ),
      ),

      error: _errorState,

      data: (providers) {
        final filtered = providers
            .where(
              (p) =>
                  _search.isEmpty || p.name.toLowerCase().contains(_search),
            )
            .toList();

        if (filtered.isEmpty) {
          return _emptyState(
            Icons.account_balance_wallet_outlined,
            _search.isEmpty
                ? "No providers in this category yet"
                : "No matching providers found",
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(providersByCategoryProvider);
            ref.invalidate(allProvidersProvider);
          },
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: hPad.left,
              vertical: R.sp(context, 6),
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final provider = filtered[index];
              final low = provider.isLowBalance;

              return _cardShell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddProviderScreen(
                        existingProviderId: provider.id,
                      ),
                    ),
                  );

                  ref.invalidate(providersByCategoryProvider);
                  _clearSearch();
                },
                onLongPress: () => _confirmDeleteProvider(provider),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: _buildHighlightedTextSpans(
                                  text: provider.name,
                                  query: _search,
                                  defaultStyle: TextStyle(
                                    fontSize: R.fs(context, 15),
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0F172A),
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
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            money(provider.balance),
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
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = R.hPad(context, base: 16);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      body: SafeArea(
        child: Column(
          children: [
            // ─────────────────────────────────────────
            // HEADER
            //
            // Same collapsible search as the categories screen: the
            // icon is all you see until it's tapped, and it snaps
            // shut (text cleared) on close, back, home, or wallet —
            // so it only ever shows up right after you tap it.
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
                    onPressed: () {
                      _clearSearch();
                      Navigator.pop(context);
                    },
                  ),

                  const SizedBox(width: 14),

                  // CATEGORY NAME — swapped for the search field while open
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
                              hintText: _isProvider
                                  ? "Search providers..."
                                  : "Search services...",
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

                  // WALLET — PROVIDER CATEGORIES ONLY
                  //
                  // Balances and reloads only mean something for a
                  // provider category, so a service category never
                  // shows this at all.
                  if (_isProvider)
                    Container(
                      width: 38,
                      height: 38,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                          R.radius(context, 10),
                        ),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        tooltip: 'Balances & reload',
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProvidersListScreen(
                                categoryId: widget.category.id,
                                categoryName: widget.category.name,
                              ),
                            ),
                          );

                          ref.invalidate(providersByCategoryProvider);
                          _clearSearch();
                        },
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

            // ─────────────────────────────────────────
            // LIST — SERVICES OR PROVIDERS
            // ─────────────────────────────────────────
            Expanded(
              child: _isProvider
                  ? _buildProvidersBody(context)
                  : _buildServicesBody(context),
            ),

            // ─────────────────────────────────────────
            // ONE BUTTON, MATCHING THE CATEGORY TYPE
            // ─────────────────────────────────────────
            Padding(
              padding: EdgeInsets.all(hPad.left),
              child: _isProvider
                  ? _bottomActionButton(
                      label: 'Add Provider',
                      icon: Icons.bolt_rounded,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddProviderScreen(
                              presetCategoryId: widget.category.id,
                              presetCategoryName: widget.category.name,
                            ),
                          ),
                        );

                        ref.invalidate(providersByCategoryProvider);
                        _clearSearch();
                      },
                    )
                  : _bottomActionButton(
                      label: 'Add Service',
                      icon: Icons.add,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditServiceScreen(
                            presetCategoryId: widget.category.id,
                            presetCategoryName: widget.category.name,
                          ),
                        ),
                      ).then((_) => _clearSearch()),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
