// ============================================================
// lib/features/inventory/presentation/providers/inventory_providers.dart
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../products/data/models/product_model.dart';

import '../../data/datasources/inventory_remote_datasource.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../domain/entities/inventory_summary.dart';
import '../../domain/repositories/inventory_repository.dart';


// ============================================================
// NETWORK
// ============================================================

final inventoryHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();

  ref.onDispose(client.close);

  return client;
});


// ============================================================
// DATA SOURCE
// ============================================================

final inventoryRemoteDataSourceProvider =
    Provider<InventoryRemoteDataSource>((ref) {
  return InventoryRemoteDataSource(
    client: ref.read(inventoryHttpClientProvider),
  );
});


// ============================================================
// REPOSITORY
// ============================================================

final inventoryRepositoryProvider =
    Provider<InventoryRepository>((ref) {
  return InventoryRepositoryImpl(
    dataSource: ref.read(
      inventoryRemoteDataSourceProvider,
    ),
  );
});


// ============================================================
// UI FILTER STATE
// ============================================================

/// Active filter:
///
/// all
/// low
/// out
/// expiring
/// expired
final inventoryFilterProvider =
    StateProvider<String>((ref) => 'all');


/// Search text on Inventory screen.
final inventorySearchProvider =
    StateProvider<String>((ref) => '');


/// Sorting:
///
/// name_asc
/// stock_asc
/// value_desc
final inventorySortProvider =
    StateProvider<String>((ref) => 'name_asc');


// ============================================================
// REFRESH STATE
// ============================================================

/// Increment this value after any successful inventory
/// operation to force inventory providers to refetch.
final productsRefreshProvider =
    StateProvider<int>((ref) => 0);


// ============================================================
// INVENTORY SUMMARY
// ============================================================

final inventorySummaryProvider =
    FutureProvider.autoDispose<InventorySummary>((ref) async {
  ref.watch(productsRefreshProvider);

  final repository = ref.read(
    inventoryRepositoryProvider,
  );

  return repository.getInventorySummary();
});


// ============================================================
// INVENTORY PRODUCTS
// ============================================================

final inventoryProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  ref.watch(productsRefreshProvider);

  final filter = ref.watch(
    inventoryFilterProvider,
  );

  final search = ref.watch(
    inventorySearchProvider,
  );

  final sortBy = ref.watch(
    inventorySortProvider,
  );

  final repository = ref.read(
    inventoryRepositoryProvider,
  );

  return repository.getInventoryProducts(
    page: 1,
    limit: 500,
    filter: filter.isEmpty ? 'all' : filter,
    search: search.trim(),
    sortBy: sortBy,
  );
});


// ============================================================
// LOW STOCK PRODUCTS
// ============================================================

final lowStockListProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  ref.watch(productsRefreshProvider);

  final repository = ref.read(
    inventoryRepositoryProvider,
  );

  return repository.getLowStockProducts();
});


// ============================================================
// LOW STOCK RESTOCK VALUE
// ============================================================
//
// IMPORTANT:
//

//
//   (lsl * 2 - quantity) * purchase_price
//
// Your new remote inventory data source does NOT currently expose
// a getLowStockRestockValue() API.
//
// Therefore we must NOT silently calculate an incorrect value
// on Flutter.
//
// For now this provider derives the value only when the Product
// model contains the required low-stock-limit field.
//
// If your Product model does not contain that field, this returns
// 0 until the backend exposes a dedicated restock-value field.
//
// ============================================================

final lowStockRestockValueProvider =
    FutureProvider.autoDispose<double>((ref) async {
  ref.watch(productsRefreshProvider);

  final products = await ref.watch(
    lowStockListProvider.future,
  );

  double total = 0;

  for (final product in products) {
    // Current Product model does not expose `lsl`.
    //
    // Do not invent a restock quantity here.
    //
    // Backend should eventually return:
    //
    // suggested_qty
    //
    // and:
    //
    // restock_value
    //
    // for an exact calculation.
  }

  return total;
});


// ============================================================
// PRODUCT SEARCH
// ============================================================

final productSearchQueryProvider =
    StateProvider<String>((ref) => '');


final productSearchResultsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final query = ref.watch(
    productSearchQueryProvider,
  );

  final trimmedQuery = query.trim();

  if (trimmedQuery.isEmpty) {
    return [];
  }

  final repository = ref.read(
    inventoryRepositoryProvider,
  );

  return repository.searchProducts(
    trimmedQuery,
  );
});


// ============================================================
// INVENTORY REFRESH HELPER
// ============================================================

void refreshInventory(WidgetRef ref) {
  ref
      .read(productsRefreshProvider.notifier)
      .state++;
}