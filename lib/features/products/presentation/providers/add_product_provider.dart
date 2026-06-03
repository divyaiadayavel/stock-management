import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final imageProvider = StateProvider<File?>((ref) => null);

final selectedCategoryProvider = StateProvider<String>((ref) => "Electronics");

final selectedSupplierProvider = StateProvider<String?>((ref) => null);

final profitMarginProvider = StateProvider<double>((ref) => 0);

final showGstProvider = StateProvider<bool>((ref) => false);

final suppliersProvider = StateProvider<List<String>>((ref) => []);
