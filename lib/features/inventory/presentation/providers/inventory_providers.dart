// =========================================================
// lib/providers/inventory_providers.dart
// =========================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/db_helper.dart';

/// Active filter chip on Inventory screen: all | low | out | expiring
final inventoryFilterProvider = StateProvider<String>((ref) => 'all');

/// Search text on Inventory screen
final inventorySearchProvider = StateProvider<String>((ref) => '');

/// 🆕 Sorting type state: name_asc | stock_asc | value_desc
final inventorySortProvider = StateProvider<String>((ref) => 'name_asc');

/// Summary counts: {all, low, out, expiring}
final inventorySummaryProvider = FutureProvider.autoDispose<Map<String, int>>((
  ref,
) async {
  ref.watch(productsRefreshProvider);
  return DBHelper.getInventorySummary();
});

/// Bump this to force every inventory-related provider to refetch
final productsRefreshProvider = StateProvider<int>((ref) => 0);

/// Filtered product list driven by filter + search + sort
final productsListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      ref.watch(productsRefreshProvider);
      final filter = ref.watch(inventoryFilterProvider);
      final query = ref.watch(inventorySearchProvider);
      final sortBy = ref.watch(inventorySortProvider); // 🆕 Watch sort choice

      // Pass filter, query, AND sorting directly to the database layer
      return DBHelper.getProductsFiltered(
        filter: filter,
        query: query,
        sortBy: sortBy,
      );
    });

/// Low stock list for Low Stock Center screen
final lowStockListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      ref.watch(productsRefreshProvider);
      return DBHelper.getLowStockProducts();
    });

final lowStockRestockValueProvider = FutureProvider.autoDispose<double>((
  ref,
) async {
  ref.watch(productsRefreshProvider);
  return DBHelper.getLowStockRestockValue();
});

/// Product search (typeahead) used inside Stock In / Stock Out screens
final productSearchQueryProvider = StateProvider<String>((ref) => '');

final productSearchResultsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final query = ref.watch(productSearchQueryProvider);
      if (query.trim().isEmpty) return [];
      return DBHelper.searchProductsByName(query);
    });

/// Helper to call after any stock in/out/adjust action succeeds
void refreshInventory(WidgetRef ref) {
  ref.read(productsRefreshProvider.notifier).state++;
}
