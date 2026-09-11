import '../../data/models/sale_model.dart';

abstract class SalesRepository {
  /// Create a new sale
  Future<int> createSale(SaleModel sale);

  /// Get invoice by Sale ID
  Future<SaleModel?> getInvoice(int saleId);

  /// Record a payment against an existing invoice's outstanding balance.
  /// Returns the updated payment summary (paid_amount, balance_amount,
  /// payment_status, ...) from the server on success.
  Future<Map<String, dynamic>> addPayment({
    required int saleId,
    required String paymentMethod,
    required double amount,
    String? referenceNumber,
    String? remarks,
  });
}