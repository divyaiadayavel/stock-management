import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final imageProvider = StateProvider.autoDispose<File?>((ref) => null);

final selectedCategoryProvider = StateProvider.autoDispose<String>(
  (ref) => "Electronics",
);

final selectedSupplierProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

final profitMarginProvider = StateProvider.autoDispose<double>((ref) => 0);

final showGstProvider = StateProvider.autoDispose<bool>((ref) => false);

final suppliersProvider = StateProvider.autoDispose<List<String>>((ref) => []);

final discountProvider = StateProvider.autoDispose<double>((ref) => 0);
