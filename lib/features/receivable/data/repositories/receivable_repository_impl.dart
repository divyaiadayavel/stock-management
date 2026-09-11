import '../../domain/entities/customer_detail.dart';
import '../../domain/entities/receivable_customer.dart';
import '../../domain/repositories/receivable_repository.dart';
import '../datasources/receivable_remote_datasource.dart';

class ReceivableRepositoryImpl implements ReceivableRepository {
  final ReceivableRemoteDataSource remoteDataSource;

  ReceivableRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ReceivableCustomer>> getReceivableCustomers() async {
    return await remoteDataSource.getReceivableCustomers();
  }

  @override
  Future<CustomerDetail> getCustomerDetail(
    String customerId, {
    String period = 'all',
  }) async {
    return await remoteDataSource.getCustomerDetail(customerId, period: period);
  }
}
