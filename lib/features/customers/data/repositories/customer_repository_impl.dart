import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_datasource.dart';
import '../models/customer_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;

  CustomerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CustomerModel>> getCustomers({String search = ""}) async {
    return await remoteDataSource.getCustomersFromServer(search: search);
  }

  @override
  Future<int> createCustomer(CustomerModel customer) async {
    return await remoteDataSource.addCustomerToServer(customer);
  }

  @override
  Future<bool> updateCustomer(CustomerModel customer) async {
    return await remoteDataSource.updateCustomerOnServer(customer);
  }

  @override
  Future<bool> deleteCustomer(int id) async {
    return await remoteDataSource.deleteCustomerFromServer(id);
  }
}