import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/models/product_model.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';

// ─── Dependencies ────────────────────────────────────────────
final httpClientProvider = Provider<http.Client>((ref) => http.Client());

final productRemoteSourceProvider = Provider<ProductRemoteDataSource>((ref) {
  return ProductRemoteDataSource(client: ref.watch(httpClientProvider));
});

// ─── UI Filter, Search & Sort States ──────────────────────
final selectedFilterProvider = StateProvider<String>((ref) => "All");
final searchQueryProvider = StateProvider<String>((ref) => "");
final sortOptionProvider = StateProvider<String>((ref) => "Name (A–Z)");

// ─── ProductListNotifier (Pagination with server‑side search) ──
class ProductListState {
  final List<Product> items;
  final int page;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool isRefreshing;
  final bool hasMore;
  final String? error;

  const ProductListState({
    this.items = const [],
    this.page = 1,
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.hasMore = true,
    this.error,
  });

  ProductListState copyWith({
    List<Product>? items,
    int? page,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool? hasMore,
    Object? error = _errorSentinel,
  }) {
    return ProductListState(
      items: items ?? this.items,
      page: page ?? this.page,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasMore: hasMore ?? this.hasMore,
      error: identical(error, _errorSentinel) ? this.error : error as String?,
    );
  }
}

const _errorSentinel = Object();

class ProductListNotifier extends StateNotifier<ProductListState> {
  final Ref ref;
  static const int _limit = 500;

  ProductListNotifier(this.ref) : super(const ProductListState());

  // Load first page (initial or refresh) – uses current search
  // Future<void> loadProducts() async {
  //   state = state.copyWith(
  //     isInitialLoading: true,
  //     error: null,
  //     page: 1,
  //     hasMore: true,
  //   );

  //   try {
  //     final search = ref.read(searchQueryProvider).trim();

  //     final result = await ref.read(productRemoteSourceProvider)
  //         .getProductsFromServer(
  //           page: 1,
  //           limit: _limit,
  //           search: search,
  //         );

  //     state = state.copyWith(
  //       items: result.items,
  //       page: 1,
  //       hasMore: result.total > _limit,
  //       isInitialLoading: false,
  //       error: null,
  //     );
  //   } catch (e) {
  //     state = state.copyWith(
  //       isInitialLoading: false,
  //       error: e.toString(),
  //     );
  //   }
  // }
  Future<void> loadProducts({String? searchOverride}) async {
    state = state.copyWith(
      isInitialLoading: true,
      error: null,
      page: 1,
      hasMore: true,
    );

    try {
      final search = searchOverride != null
          ? searchOverride.trim()
          : ref.read(searchQueryProvider).trim();

      final result = await ref
          .read(productRemoteSourceProvider)
          .getProductsFromServer(page: 1, limit: _limit, search: search);

      state = state.copyWith(
        items: result.items,
        page: 1,
        hasMore: result.total > _limit,
        isInitialLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isInitialLoading: false, error: e.toString());
    }
  }

  // Load next page – passes the same search term
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isInitialLoading) return;

    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final search = ref.read(searchQueryProvider).trim();
      final nextPage = state.page + 1;
      final remoteSource = ref.read(productRemoteSourceProvider);
      final result = await remoteSource.getProductsFromServer(
        page: nextPage,
        limit: _limit,
        search: search,
      );

      final totalPages = (_limit > 0) ? (result.total / _limit).ceil() : 0;
      final newItems = [...state.items, ...result.items];

      state = state.copyWith(
        items: newItems,
        page: nextPage,
        hasMore: nextPage < totalPages,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  // Pull‑to‑refresh – reloads page 1 without clearing the list
  Future<void> refresh() async {
    state = state.copyWith(
      isRefreshing: true,
      error: null,
      page: 1,
      hasMore: true,
      isLoadingMore: false,
    );
    try {
      final search = ref.read(searchQueryProvider).trim();
      final remoteSource = ref.read(productRemoteSourceProvider);
      final result = await remoteSource.getProductsFromServer(
        page: 1,
        limit: _limit,
        search: search,
      );
      state = state.copyWith(
        items: result.items,
        page: 1,
        hasMore: result.total > _limit,
        isRefreshing: false,
      );
    } catch (e) {
      state = state.copyWith(isRefreshing: false, error: e.toString());
    }
  }
}

final productListProvider =
    StateNotifierProvider<ProductListNotifier, ProductListState>((ref) {
      return ProductListNotifier(ref);
    });

final supplierListProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final remote = ref.read(productRemoteSourceProvider);
  return remote.getSuppliersFromServer();
});

// ─── ProductOperations ──────────────────────────────────────
class ProductOperations extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  ProductOperations(this.ref) : super(const AsyncValue.data(null));

  Future<bool> addProduct(Product product) async {
    state = const AsyncValue.loading();

    try {
      final newId = await ref
          .read(productRemoteSourceProvider)
          .addProductToServer(product);

      if (newId <= 0) {
        throw Exception('Unable to add product.');
      }

      await ref.read(productListProvider.notifier).refresh();
      await ref.read(dashboardProvider.notifier).refresh();

      state = const AsyncValue.data(null);

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> modifyProduct(Product product) async {
    state = const AsyncValue.loading();

    try {
      final success = await ref
          .read(productRemoteSourceProvider)
          .updateProductOnServer(product);

      if (!success) {
        throw Exception('Unable to update product.');
      }

      await ref.read(productListProvider.notifier).refresh();
      await ref.read(dashboardProvider.notifier).refresh();

      state = const AsyncValue.data(null);

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      final success = await ref
          .read(productRemoteSourceProvider)
          .deleteProductFromServer(id);
      if (success) {
        ref.read(productListProvider.notifier).refresh();
        ref.read(dashboardProvider.notifier).refresh(); // ⚡ Refresh dashboard
        return true;
      }
    } catch (_) {}
    return false;
  }
}

final productOperationsProvider =
    StateNotifierProvider<ProductOperations, AsyncValue<void>>((ref) {
      return ProductOperations(ref);
    });

// ─── Filtered & Sorted List (client‑side) ──────────────────
final filteredProductsProvider = Provider<Map<String, dynamic>>((ref) {
  final paginatedState = ref.watch(productListProvider);
  final filter = ref.watch(selectedFilterProvider);
  final sortOption = ref.watch(sortOptionProvider);

  if (paginatedState.isInitialLoading) {
    return {
      "isLoading": true,
      "list": <Product>[],
      "total": 0,
      "inStock": 0,
      "lowStock": 0,
      "outStock": 0,
      "totalUnits": 0,
      "totalValue": 0.0,
    };
  }

  List<Product> temp = List.from(paginatedState.items);

  // ── Apply status filter ──
  if (filter == "In Stock") {
    temp = temp.where((p) => p.quantity > p.lsl).toList();
  } else if (filter == "Low Stock") {
    temp = temp.where((p) => p.quantity > 0 && p.quantity <= p.lsl).toList();
  } else if (filter == "Out Of Stock") {
    temp = temp.where((p) => p.quantity <= 0).toList();
  }

  // ── Apply sorting ──
  switch (sortOption) {
    case "Name (A–Z)":
      temp.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      break;
    case "Stock (Low → High)":
      temp.sort((a, b) => a.quantity.compareTo(b.quantity));
      break;
    case "Price (High → Low)":
    case "Value (High → Low)":
      temp.sort((a, b) {
        final priceA = a.sellingPrice;
        final priceB = b.sellingPrice;

        if (priceB > priceA) return 1;
        if (priceB < priceA) return -1;

        // Equal price tie-breaker: Alphabetical order A-Z
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      break;
    default:
      temp.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  // ── Stats (from full list) ──
  final all = paginatedState.items;
  int total = all.length;
  int inStock = all.where((p) => p.quantity > p.lsl).length;
  int lowStock = all.where((p) => p.quantity > 0 && p.quantity <= p.lsl).length;
  int outStock = all.where((p) => p.quantity <= 0).length;
  int totalUnits = 0;
  double totalValue = 0.0;
  for (var p in all) {
    totalUnits += p.quantity;
    totalValue += (p.quantity * p.sellingPrice);
  }

  return {
    "isLoading": false,
    "list": temp,
    "total": total,
    "inStock": inStock,
    "lowStock": lowStock,
    "outStock": outStock,
    "totalUnits": totalUnits,
    "totalValue": totalValue,
  };
});
