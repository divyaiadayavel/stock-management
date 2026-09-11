import '../entities/receivable_customer.dart';
import '../repositories/reports_repository.dart';

class GetReceivableCustomers {
  final ReportsRepository repository;

  GetReceivableCustomers(this.repository);

  Future<List<ReceivableCustomer>> call() async {
    return await repository.getReceivableCustomers();
  }
}
