import 'package:flutter_riverpod/flutter_riverpod.dart';

final invoiceItemsProvider = StateProvider<List<Map<String, dynamic>>>(
  (ref) => [],
);

final subtotalProvider = StateProvider<double>((ref) => 0);

final discountProvider = StateProvider<double>((ref) => 0);

final taxProvider = StateProvider<double>((ref) => 0);

final totalProvider = StateProvider<double>((ref) => 0);
