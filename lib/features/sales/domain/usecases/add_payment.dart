import '../repositories/sales_repository.dart';

/// Records a (partial or full) payment against an existing invoice's
/// outstanding balance, e.g. from the "Settle Balance" action on the
/// Invoice screen.
class AddPayment {
  final SalesRepository repository;

  AddPayment(this.repository);

  Future<Map<String, dynamic>> call({
    required int saleId,
    required String paymentMethod,
    required double amount,
    String? referenceNumber,
    String? remarks,
  }) async {
    return await repository.addPayment(
      saleId: saleId,
      paymentMethod: paymentMethod,
      amount: amount,
      referenceNumber: referenceNumber,
      remarks: remarks,
    );
  }
}
