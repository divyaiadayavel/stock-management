// ===========================================================
// lib/features/inventory/presentation/providers/inventory_provider.dart
// ===========================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../data/datasources/inventory_remote_datasource.dart';
import '../../data/repositories/inventory_repository_impl.dart';

import '../../domain/entities/inventory_summary.dart';
import '../../../products/data/models/product_model.dart';

import '../../domain/usecases/get_inventory_summary.dart';
import '../../domain/usecases/get_inventory_stock.dart';
import '../../domain/usecases/get_low_stock.dart';

import 'inventory_filter_provider.dart';


/// ===========================================================
/// Dependencies
/// ===========================================================

final inventoryHttpClientProvider =
    Provider<http.Client>((ref) {
  return http.Client();
});


final inventoryRemoteDataSourceProvider =
    Provider<InventoryRemoteDataSource>((ref) {
  return InventoryRemoteDataSource(
    client: ref.watch(
      inventoryHttpClientProvider,
    ),
  );
});


final inventoryRepositoryProvider =
    Provider<InventoryRepositoryImpl>((ref) {
  return InventoryRepositoryImpl(
    dataSource: ref.watch(
      inventoryRemoteDataSourceProvider,
    ),
  );
});


/// ===========================================================
/// UseCases
/// ===========================================================

final getInventorySummaryProvider =
    Provider<GetInventorySummary>((ref) {
  return GetInventorySummary(
    ref.watch(
      inventoryRepositoryProvider,
    ),
  );
});


final getInventoryStockProvider =
    Provider<GetInventoryStock>((ref) {
  return GetInventoryStock(
    ref.watch(
      inventoryRepositoryProvider,
    ),
  );
});


final getLowStockProvider =
    Provider<GetLowStock>((ref) {
  return GetLowStock(
    ref.watch(
      inventoryRepositoryProvider,
    ),
  );
});


/// ===========================================================
/// Inventory Summary
///
/// Backend:
/// GET inventory.php?action=summary
///
/// Provides:
/// - total products
/// - low stock count
/// - out of stock count
/// - expiring count
/// - expired count
/// ===========================================================

final inventorySummaryProvider =
    FutureProvider.autoDispose<InventorySummary>(
  (ref) async {

    // Re-run when refresh trigger changes.
    ref.watch(
      inventoryRefreshProvider,
    );

    return ref
        .watch(
          getInventorySummaryProvider,
        )
        .call();
  },
);


/// ===========================================================
/// Inventory Product List
///
/// The backend is the single source of truth for filtering.
///
/// Supported filters:
/// - all
/// - low
/// - out
/// - expiring
/// - expired
///
/// Search and sorting are also passed to the backend.
/// ===========================================================

final inventoryProductsProvider =
    FutureProvider.autoDispose<List<Product>>(
  (ref) async {

    // Re-run when refresh trigger changes.
    ref.watch(
      inventoryRefreshProvider,
    );

    // Current inventory filter.
    final filter = ref.watch(
      inventoryFilterProvider,
    );

    // Current search query.
    final search = ref.watch(
      inventorySearchProvider,
    );

    // Current sort option.
    final sortBy = ref.watch(
      inventorySortProvider,
    );

    return ref
        .watch(
          getInventoryStockProvider,
        )
        .call(
          filter: filter,
          search: search,
          sortBy: sortBy,
        );
  },
);


/// ===========================================================
/// Low Stock Products
///
/// Kept for screens/use cases that specifically need
/// low-stock products independently of the main filter list.
///
/// This does NOT control the StockScreen filter.
/// ===========================================================

final lowStockProductsProvider =
    FutureProvider.autoDispose<List<Product>>(
  (ref) async {

    ref.watch(
      inventoryRefreshProvider,
    );

    return ref
        .watch(
          getLowStockProvider,
        )
        .call();
  },
);


/// ===========================================================
/// Refresh Helper
///
/// Incrementing this trigger refreshes:
/// - inventory summary
/// - inventory product list
/// - low stock list
/// ===========================================================

void refreshInventory(Ref ref) {
  ref
      .read(
        inventoryRefreshProvider.notifier,
      )
      .state++;
}


/// ===========================================================
/// Search Query
///
/// Used by product autocomplete/search functionality.
///
/// This is intentionally separate from
/// inventorySearchProvider, which controls the StockScreen
/// inventory list search.
/// ===========================================================

final inventorySearchQueryProvider =
    StateProvider<String>((ref) => '');


/// ===========================================================
/// Product Search / Autocomplete
///
/// Calls the backend search endpoint.
///
/// Empty queries return an empty list and do not make
/// unnecessary network requests.
/// ===========================================================

final inventoryProductSearchProvider =
    FutureProvider.autoDispose
        .family<List<Product>, String>(
  (ref, query) async {

    final trimmedQuery =
        query.trim();

    if (trimmedQuery.isEmpty) {
      return [];
    }

    return ref
        .watch(
          inventoryRepositoryProvider,
        )
        .searchProducts(
          trimmedQuery,
        );
  },
);