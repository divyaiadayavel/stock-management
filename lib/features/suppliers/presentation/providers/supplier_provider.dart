import 'package:flutter_riverpod/flutter_riverpod.dart';

final suppliersProvider = StateProvider<List<Map<String, dynamic>>>(
  (ref) => [],
);
final searchSupplierProvider = StateProvider<String>((ref) => '');

final filteredSuppliersProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final suppliers = ref.watch(suppliersProvider);
  final search = ref.watch(searchSupplierProvider);

  if (search.isEmpty) return suppliers;

  return suppliers.where((supplier) {
    return supplier["supplierName"].toString().toLowerCase().contains(
      search.toLowerCase(),
    );
  }).toList();
});
final totalSuppliersProvider = StateProvider<int>((ref) => 0);

final totalCategoriesProvider = StateProvider<int>((ref) => 0);

final totalProductsProvider = StateProvider<int>((ref) => 0);

final totalPurchasesProvider = StateProvider<double>((ref) => 0);
