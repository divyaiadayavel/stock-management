import '../../domain/repositories/sales_repository.dart';
import '../datasources/sales_remote_datasource.dart';
import '../models/sale_model.dart';

class SalesRepositoryImpl implements SalesRepository {
  final SalesRemoteDataSource remoteDataSource;

  SalesRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<int> createSale(SaleModel sale) async {
    return await remoteDataSource.createSaleOnServer(sale);
  }

  @override
  Future<SaleModel?> getInvoice(int saleId) async {
    return await remoteDataSource.getInvoiceFromServer(saleId);
  }

  @override
  Future<Map<String, dynamic>> addPayment({
    required int saleId,
    required String paymentMethod,
    required double amount,
    String? referenceNumber,
    String? remarks,
  }) async {
    return await remoteDataSource.addPaymentOnServer(
      saleId: saleId,
      paymentMethod: paymentMethod,
      amount: amount,
      referenceNumber: referenceNumber,
      remarks: remarks,
    );
  }
}