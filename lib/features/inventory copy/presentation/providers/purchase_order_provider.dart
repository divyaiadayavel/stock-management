import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/purchase_order.dart';

import '../../domain/usecases/create_purchase_order.dart';
import '../../domain/usecases/receive_purchase_order.dart';

import 'inventory_provider.dart';
import 'inventory_filter_provider.dart';

/// ===========================================================
/// UseCases
/// ===========================================================

final createPurchaseOrderUseCaseProvider =
    Provider<CreatePurchaseOrder>((ref) {
  return CreatePurchaseOrder(
    ref.watch(inventoryRepositoryProvider),
  );
});

final receivePurchaseOrderUseCaseProvider =
    Provider<ReceivePurchaseOrder>((ref) {
  return ReceivePurchaseOrder(
    ref.watch(inventoryRepositoryProvider),
  );
});

/// ===========================================================
/// Purchase Order List
/// ===========================================================

final purchaseOrdersProvider =
    FutureProvider.autoDispose<List<PurchaseOrder>>((ref) async {
  ref.watch(inventoryRefreshProvider);

  return await ref
      .watch(inventoryRepositoryProvider)
      .getPurchaseOrders();
});

/// ===========================================================
/// Purchase Order Details
/// ===========================================================

final purchaseOrderDetailsProvider =
    FutureProvider.family.autoDispose<PurchaseOrder?, int>(
        (ref, purchaseOrderId) async {
  return await ref
      .watch(inventoryRepositoryProvider)
      .getPurchaseOrder(purchaseOrderId);
});

/// ===========================================================
/// Purchase Order Operations
/// ===========================================================

class PurchaseOrderOperations
    extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  PurchaseOrderOperations(this.ref)
      : super(const AsyncValue.data(null));

  /// ---------------------------------------------------------
  /// CREATE PURCHASE ORDER
  /// ---------------------------------------------------------

  Future<bool> createPurchaseOrder(
      PurchaseOrder purchaseOrder) async {
    state = const AsyncValue.loading();

    try {
      final success = await ref
          .read(createPurchaseOrderUseCaseProvider)
          .call(purchaseOrder);

      if (success) {
        refreshInventory(ref);

        state = const AsyncValue.data(null);

        return true;
      }

      state = AsyncValue.error(
        Exception("Purchase Order Creation Failed"),
        StackTrace.current,
      );

      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);

      return false;
    }
  }

  /// ---------------------------------------------------------
  /// RECEIVE PURCHASE ORDER
  /// ---------------------------------------------------------

  Future<bool> receivePurchaseOrder({
    required int purchaseOrderId,
    required List<Map<String, dynamic>> receivedItems,
    String remarks = "",
  }) async {
    state = const AsyncValue.loading();

    try {
      final success = await ref
          .read(receivePurchaseOrderUseCaseProvider)
          .call(
            purchaseOrderId: purchaseOrderId,
            receivedItems: receivedItems,
            remarks: remarks,
          );

      if (success) {
        refreshInventory(ref);

        state = const AsyncValue.data(null);

        return true;
      }

      state = AsyncValue.error(
        Exception("Receive Purchase Order Failed"),
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

final purchaseOrderOperationProvider =
    StateNotifierProvider<
        PurchaseOrderOperations,
        AsyncValue<void>>((ref) {
  return PurchaseOrderOperations(ref);
});