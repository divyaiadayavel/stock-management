import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/db_helper.dart';

// 1. Create a simple provider for the raw data fetch
final rawProductsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return await DBHelper.getAllProducts();
});

// 2. Create clean StateProviders for your UI filters
final selectedFilterProvider = StateProvider<String>((ref) => "All");
final searchQueryProvider = StateProvider<String>((ref) => "");

// 3. A combined selector provider that handles all sorting, filtering, and counting
final filteredProductsProvider = Provider<Map<String, dynamic>>((ref) {
  final rawAsync = ref.watch(rawProductsProvider);
  final search = ref.watch(searchQueryProvider);
  final filter = ref.watch(selectedFilterProvider);

  return rawAsync.maybeWhen(
    data: (products) {
      List<Map<String, dynamic>> temp = List.from(products);

      // 🔍 Apply Search logic
      if (search.isNotEmpty) {
        temp = temp
            .where(
              (p) => p["name"].toString().toLowerCase().contains(
                search.toLowerCase(),
              ),
            )
            .toList();
      }

      // 📊 Calculate Master Counts dynamically from the absolute source data
      int total = products.length;
      int inStock = products
          .where((p) => (p["quantity"] ?? 0) > (p["lsl"] ?? 10))
          .length;
      int lowStock = products
          .where(
            (p) =>
                (p["quantity"] ?? 0) > 0 &&
                (p["quantity"] ?? 0) <= (p["lsl"] ?? 10),
          )
          .length;
      int outStock = products.where((p) => (p["quantity"] ?? 0) <= 0).length;

      // ⚙️ Apply Filter selection
      if (filter == "In Stock") {
        temp = temp
            .where((p) => (p["quantity"] ?? 0) > (p["lsl"] ?? 10))
            .toList();
      } else if (filter == "Low Stock") {
        temp = temp
            .where(
              (p) =>
                  (p["quantity"] ?? 0) > 0 &&
                  (p["quantity"] ?? 0) <= (p["lsl"] ?? 10),
            )
            .toList();
      } else if (filter == "Out Of Stock") {
        temp = temp.where((p) => (p["quantity"] ?? 0) <= 0).toList();
      }

      // 🔀 Sort Alphabetically
      temp.sort(
        (a, b) => (a["name"] ?? "").toString().toLowerCase().compareTo(
          (b["name"] ?? "").toString().toLowerCase(),
        ),
      );

      return {
        "isLoading": false,
        "list": temp,
        "total": total,
        "inStock": inStock,
        "lowStock": lowStock,
        "outStock": outStock,
      };
    },
    // Safe fallbacks to prevent screen crashes while the database spins up
    orElse: () => {
      "isLoading": true,
      "list": <Map<String, dynamic>>[],
      "total": 0,
      "inStock": 0,
      "lowStock": 0,
      "outStock": 0,
    },
  );
});
