import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data/datasources/supplier_remote_datasource.dart';
import '../../data/repositories/supplier_repository_impl.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/usecases/delete_supplier.dart';
import '../../domain/usecases/get_suppliers_paginated.dart';
import '../../../../core/network/api_config.dart';

// Dependency Injection Setup Providers
final supplierClientProvider = Provider((ref) => http.Client());

final supplierRemoteDatasourceProvider = Provider((ref) {
  final client = ref.watch(supplierClientProvider);

  return SupplierRemoteDatasource(
    baseUrl: ApiConfig.baseUrl,
    client: client,
  );
});

final supplierRepositoryProvider = Provider((ref) {
  final remoteDS = ref.watch(supplierRemoteDatasourceProvider);
  return SupplierRepositoryImpl(remoteDataSource: remoteDS);
});

final getSuppliersPaginatedProvider = Provider((ref) {
  final repo = ref.watch(supplierRepositoryProvider);
  return GetSuppliersPaginated(repo);
});

final deleteSupplierProvider = Provider((ref) {
  final repo = ref.watch(supplierRepositoryProvider);
  return DeleteSupplier(repo);
});

// State Notifier Matrix Configuration
class SupplierState {
  final List<Supplier> suppliers;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String searchQuery;
  final String error;

  SupplierState({
    required this.suppliers,
    required this.isLoading,
    required this.hasMore,
    required this.page,
    required this.searchQuery,
    required this.error,
  });

  SupplierState copyWith({
    List<Supplier>? suppliers,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? searchQuery,
    String? error,
  }) {
    return SupplierState(
      suppliers: suppliers ?? this.suppliers,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      searchQuery: searchQuery ?? this.searchQuery,
      error: error ?? this.error,
    );
  }
}

class SuppliersNotifier extends StateNotifier<SupplierState> {
  static const int _pageSize = 100;

  final GetSuppliersPaginated _getSuppliers;
  final DeleteSupplier _deleteSupplier;

  SuppliersNotifier({
    required GetSuppliersPaginated getSuppliers,
    required DeleteSupplier deleteSupplier,
  }) : _getSuppliers = getSuppliers,
       _deleteSupplier = deleteSupplier,
       super(
         SupplierState(
           suppliers: [],
           isLoading: false,
           hasMore: true,
           page: 1,
           searchQuery: '',
           error: '',
         ),
       );

  Future<void> fetchAllSuppliers({bool refresh = false}) async {
    if (refresh) {
      // ✅ FIX: Force isLoading: false so refresh is never blocked by a stale loading flag
      state = state.copyWith(
        page: 1,
        hasMore: true,
        suppliers: [],
        isLoading: false,
      );
    }

    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: '');

    try {
      final result = await _getSuppliers(
        page: state.page,
        limit: _pageSize,
        search: state.searchQuery,
        status: 'ACTIVE',
        sort: 'id',
        order: 'DESC',
      );

      final List<Supplier> fetched = List<Supplier>.from(result['data']);

      state = state.copyWith(
        suppliers: [...state.suppliers, ...fetched],
        page: state.page + 1,
        hasMore: fetched.length == _pageSize,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void searchSuppliers(String query) {
    state = state.copyWith(searchQuery: query);
    fetchAllSuppliers(refresh: true);
  }

  Future<bool> removeSupplier(int id) async {
    try {
      await _deleteSupplier(id);
      state = state.copyWith(
        suppliers: state.suppliers.where((s) => s.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final suppliersNotifierProvider =
    StateNotifierProvider<SuppliersNotifier, SupplierState>((ref) {
      return SuppliersNotifier(
        getSuppliers: ref.watch(getSuppliersPaginatedProvider),
        deleteSupplier: ref.watch(deleteSupplierProvider),
      );
    });
