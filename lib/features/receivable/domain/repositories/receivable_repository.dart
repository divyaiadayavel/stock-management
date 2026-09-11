import '../entities/customer_detail.dart';
import '../entities/receivable_customer.dart';

abstract class ReceivableRepository {
  /// Every customer with a "Due" / "Settled" indication.
  Future<List<ReceivableCustomer>> getReceivableCustomers();

  /// Full detail for one customer — summary + every bill raised to them,
  /// each with its own paid/balance breakdown.
  Future<CustomerDetail> getCustomerDetail(
    String customerId, {
    String period = 'all',
  });
}
