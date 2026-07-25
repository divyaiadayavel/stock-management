import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data/datasources/supplier_remote_datasource.dart';
import '../../data/repositories/supplier_repository_impl.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/usecases/delete_supplier.dart';
import '../../domain/usecases/get_suppliers_paginated.dart';

// Dependency Injection Setup Providers
final supplierClientProvider = Provider((ref) => http.Client());

final supplierRemoteDatasourceProvider = Provider((ref) {
  final client = ref.watch(supplierClientProvider);
  // Set your corporate backend base connection path endpoint here
  return SupplierRemoteDatasource(
    baseUrl: 'https://nonredemptive-gyrational-pauletta.ngrok-free.dev/public_html', 
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
  final String error;
  final int page;
  final bool hasMore;
  final String searchQuery;

  SupplierState({
    required this.suppliers,
    required this.isLoading,
    required this.error,
    required this.page,
    required this.hasMore,
    required this.searchQuery,
  });

  SupplierState copyWith({
    List<Supplier>? suppliers,
    bool? isLoading,
    String? error,
    int? page,
    bool? hasMore,
    String? searchQuery,
  }) {
    return SupplierState(
      suppliers: suppliers ?? this.suppliers,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class SupplierNotifier extends StateNotifier<SupplierState> {
  final GetSuppliersPaginated _getSuppliers;
  final DeleteSupplier _deleteSupplier;

  SupplierNotifier({
    required GetSuppliersPaginated getSuppliers,
    required DeleteSupplier deleteSupplier,
  })  : _getSuppliers = getSuppliers,
        _deleteSupplier = deleteSupplier,
        super(SupplierState(
          suppliers: [],
          isLoading: false,
          error: '',
          page: 1,
          hasMore: true,
          searchQuery: '',
        ));

  Future<void> fetchAllSuppliers({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(page: 1, hasMore: true, suppliers: []);
    }

    if (!state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoading: true, error: '');

    try {
      final result = await _getSuppliers(
        page: state.page,
        limit: 15,
        search: state.searchQuery,
        status: 'ACTIVE',
      );

      final List<Supplier> fetched = List<Supplier>.from(result['data']);

      state = state.copyWith(
        suppliers: [...state.suppliers, ...fetched],
        page: state.page + 1,
        hasMore: fetched.isNotEmpty,
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

final suppliersNotifierProvider = StateNotifierProvider<SupplierNotifier, SupplierState>((ref) {
  final getSuppliers = ref.watch(getSuppliersPaginatedProvider);
  final deleteSupplier = ref.watch(deleteSupplierProvider);
  return SupplierNotifier(getSuppliers: getSuppliers, deleteSupplier: deleteSupplier);
});