import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../data/datasources/product_remote_datasource.dart';
import '../providers/product_provider.dart'; // <-- ADD THIS to get productRemoteSourceProvider

// ─── Categories & Units (fetched from API) ──────────────────
final categoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final remoteSource = ref.read(productRemoteSourceProvider);
  return await remoteSource.getCategories();
});

final unitsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final remoteSource = ref.read(productRemoteSourceProvider);
  return await remoteSource.getUnits();
});
final selectedSupplierIdProvider =
    StateProvider<int?>((ref) => null);

// ─── Selected IDs ────────────────────────────────────────────
final selectedCategoryIdProvider = StateProvider<int?>((ref) => null);
final selectedUnitIdProvider = StateProvider<int?>((ref) => null);

// ─── Other UI state ──────────────────────────────────────────
final selectedCategoryProvider = StateProvider<String>((ref) => "General");
final selectedSupplierProvider = StateProvider<String?>((ref) => null);
final imageProvider = StateProvider<File?>((ref) => null);
final showGstProvider = StateProvider<bool>((ref) => false);
final profitMarginProvider = StateProvider<double>((ref) => 0.0);
final suppliersProvider = StateProvider<List<String>>((ref) => []);