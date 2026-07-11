import 'package:flutter_riverpod/flutter_riverpod.dart';

// State provider for the main list of customers
final customersProvider = StateProvider<List<Map<String, dynamic>>>(
  (ref) => [],
);

// State provider for the total count of customers
final totalCustomersProvider = StateProvider<int>((ref) => 0);

// State provider for the total receivable amount
final totalReceivableProvider = StateProvider<double>((ref) => 0.0);

// Provider for the filtered list (useful if you add a search bar later)
// Currently, it just passes through the main customer list.
final filteredCustomersProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(customersProvider);
});
