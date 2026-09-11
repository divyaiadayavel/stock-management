import '../entities/payable_supplier.dart';
import '../entities/supplier_detail.dart';

abstract class PayableRepository {
  /// Every supplier with a "Due" / "Settled" indication.
  Future<List<PayableSupplier>> getPayableSuppliers();

  /// Full detail for one supplier — summary + every purchase order made
  /// from them, each with its own paid/balance breakdown.
  Future<SupplierDetail> getSupplierDetail(
    String supplierId, {
    String period = 'all',
  });
}
