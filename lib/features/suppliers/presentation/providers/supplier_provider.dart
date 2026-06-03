import 'package:flutter_riverpod/flutter_riverpod.dart';

final suppliersProvider = StateProvider<List<Map<String, dynamic>>>(
  (ref) => [],
);

final totalSuppliersProvider = StateProvider<int>((ref) => 0);

final totalCategoriesProvider = StateProvider<int>((ref) => 0);

final totalProductsProvider = StateProvider<int>((ref) => 0);

final totalPurchasesProvider = StateProvider<double>((ref) => 0);
