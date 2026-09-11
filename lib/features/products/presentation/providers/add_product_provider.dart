import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../../settings/presentation/providers/settings_provider.dart';

// ─── Categories & Units (fetched from API) ──────────────────
// Removed .autoDispose to prevent unexpected disposal during step navigation
final categoriesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(settingsRepositoryProvider).getCategories();
});

final unitsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(settingsRepositoryProvider).getUnits();
});

final selectedSupplierIdProvider = StateProvider<int?>((ref) => null);

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