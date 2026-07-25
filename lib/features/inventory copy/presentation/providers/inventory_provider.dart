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
    Provider<http.Client>((ref) => http.Client());

final inventoryRemoteDataSourceProvider =
    Provider<InventoryRemoteDataSource>((ref) {
  return InventoryRemoteDataSource(
    client: ref.watch(inventoryHttpClientProvider),
  );
});

final inventoryRepositoryProvider =
    Provider<InventoryRepositoryImpl>((ref) {
  return InventoryRepositoryImpl(
    dataSource: ref.watch(inventoryRemoteDataSourceProvider),
  );
});

/// ===========================================================
/// UseCases
/// ===========================================================

final getInventorySummaryProvider =
    Provider<GetInventorySummary>((ref) {
  return GetInventorySummary(
    ref.watch(inventoryRepositoryProvider),
  );
});

final getInventoryStockProvider =
    Provider<GetInventoryStock>((ref) {
  return GetInventoryStock(
    ref.watch(inventoryRepositoryProvider),
  );
});

final getLowStockProvider =
    Provider<GetLowStock>((ref) {
  return GetLowStock(
    ref.watch(inventoryRepositoryProvider),
  );
});

/// ===========================================================
/// Inventory Summary
/// ===========================================================

final inventorySummaryProvider =
    FutureProvider.autoDispose<InventorySummary>((ref) async {
  ref.watch(inventoryRefreshProvider);

  return await ref
      .watch(getInventorySummaryProvider)
      .call();
});

/// ===========================================================
/// Inventory List
/// ===========================================================

final inventoryProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  ref.watch(inventoryRefreshProvider);

  final filter = ref.watch(inventoryFilterProvider);

  final search = ref.watch(inventorySearchProvider);

  final sortBy = ref.watch(inventorySortProvider);

  return await ref
      .watch(getInventoryStockProvider)
      .call(
        filter: filter,
        search: search,
        sortBy: sortBy,
      );
});

/// ===========================================================
/// Low Stock
/// ===========================================================

final lowStockProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  ref.watch(inventoryRefreshProvider);

  return await ref
      .watch(getLowStockProvider)
      .call();
});

/// ===========================================================
/// Refresh Helper
/// ===========================================================
void refreshInventory(Ref ref) {
  ref.read(inventoryRefreshProvider.notifier).state++;
}

/// ===========================================================
/// Search (autocomplete)
/// ===========================================================
final inventorySearchQueryProvider = StateProvider<String>((ref) => '');

final inventoryProductSearchProvider =
    FutureProvider.autoDispose
        .family<List<Product>, String>((ref, query) async {

  if (query.trim().isEmpty) return [];

  return ref
      .watch(inventoryRepositoryProvider)
      .searchProducts(query);
});