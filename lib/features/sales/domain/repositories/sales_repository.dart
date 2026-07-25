import '../../data/models/sale_model.dart';

abstract class SalesRepository {
  /// Create a new sale
  Future<int> createSale(SaleModel sale);

  /// Get invoice by Sale ID
  Future<SaleModel?> getInvoice(int saleId);
}