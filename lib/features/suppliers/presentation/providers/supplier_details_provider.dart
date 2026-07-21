import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/usecases/get_supplier_by_id.dart';
import 'supplier_provider.dart';

final getSupplierByIdUseCaseProvider = Provider((ref) {
  final repo = ref.watch(supplierRepositoryProvider);
  return GetSupplierById(repo);
});

class SupplierDetailsState {
  final Supplier? supplier;
  final bool isLoading;
  final String error;

  SupplierDetailsState({
    this.supplier,
    required this.isLoading,
    required this.error,
  });

  SupplierDetailsState copyWith({
    Supplier? supplier,
    bool? isLoading,
    String? error,
  }) {
    return SupplierDetailsState(
      supplier: supplier ?? this.supplier,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class SupplierDetailsNotifier extends StateNotifier<SupplierDetailsState> {
  final GetSupplierById _getSupplierById;

  SupplierDetailsNotifier({
    required GetSupplierById getSupplierById,
  })  : _getSupplierById = getSupplierById,
        super(SupplierDetailsState(isLoading: false, error: ''));

  Future<void> loadSupplierDetails(int id) async {
    state = SupplierDetailsState(isLoading: true, error: '', supplier: null);

    try {
      final data = await _getSupplierById(id);
      state = SupplierDetailsState(isLoading: false, error: '', supplier: data);
    } catch (e) {
      state = SupplierDetailsState(isLoading: false, error: e.toString(), supplier: null);
    }
  }
}

final supplierDetailsNotifierProvider = StateNotifierProvider<SupplierDetailsNotifier, SupplierDetailsState>((ref) {
  final getSupplierById = ref.watch(getSupplierByIdUseCaseProvider);
  return SupplierDetailsNotifier(getSupplierById: getSupplierById);
});