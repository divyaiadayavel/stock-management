import '../../data/models/customer_model.dart';

abstract class CustomerRepository {
  Future<List<CustomerModel>> getCustomers({String search = ""});
  Future<int> createCustomer(CustomerModel customer);
  Future<bool> updateCustomer(CustomerModel customer);
  Future<bool> deleteCustomer(int id);
}