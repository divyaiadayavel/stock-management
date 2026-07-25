import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/stock_in.dart';
import '../../domain/usecases/stock_out.dart';

import 'inventory_provider.dart';


/// ===========================================================
/// UseCases
/// ===========================================================

final stockInUseCaseProvider = Provider<StockIn>((ref) {
  return StockIn(
    ref.watch(inventoryRepositoryProvider),
  );
});

final stockOutUseCaseProvider = Provider<StockOut>((ref) {
  return StockOut(
    ref.watch(inventoryRepositoryProvider),
  );
});

/// ===========================================================
/// Inventory Operations
/// ===========================================================

class InventoryOperations extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  InventoryOperations(this.ref)
      : super(const AsyncValue.data(null));

  /// ---------------------------------------------------------
  /// STOCK IN
  /// ---------------------------------------------------------

  Future<bool> stockIn({
    required int productId,
    required int quantity,
    required double unitCost,
    int? supplierId,
    String referenceType = "MANUAL",
    String referenceNumber = "",
    String remarks = "",
  }) async {
    state = const AsyncValue.loading();

    try {
      final success = await ref
          .read(stockInUseCaseProvider)
          .call(
            productId: productId,
            quantity: quantity,
            unitCost: unitCost,
            supplierId: supplierId,
            referenceType: referenceType,
            referenceNumber: referenceNumber,
            remarks: remarks,
          );

      if (success) {
        refreshInventory(ref);

        state = const AsyncValue.data(null);

        return true;
      }

      state = AsyncValue.error(
        Exception("Stock In Failed"),
        StackTrace.current,
      );

      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);

      return false;
    }
  }

  /// ---------------------------------------------------------
  /// STOCK OUT
  /// ---------------------------------------------------------

  Future<bool> stockOut({
    required int productId,
    required int quantity,
    String reason = "",
    String referenceType = "MANUAL",
    String referenceNumber = "",
    String remarks = "",
  }) async {
    state = const AsyncValue.loading();

    try {
      final success = await ref
          .read(stockOutUseCaseProvider)
          .call(
            productId: productId,
            quantity: quantity,
            reason: reason,
            referenceType: referenceType,
            referenceNumber: referenceNumber,
            remarks: remarks,
          );

      if (success) {
        refreshInventory(ref);

        state = const AsyncValue.data(null);

        return true;
      }

      state = AsyncValue.error(
        Exception("Stock Out Failed"),
        StackTrace.current,
      );

      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);

      return false;
    }
  }
}

/// ===========================================================
/// Provider
/// ===========================================================

final inventoryOperationProvider =
    StateNotifierProvider<
        InventoryOperations,
        AsyncValue<void>>((ref) {
  return InventoryOperations(ref);
});