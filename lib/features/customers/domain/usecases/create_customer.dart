import '../../data/models/customer_model.dart';
import '../repositories/customer_repository.dart';

class CreateCustomer {
  final CustomerRepository repository;

  CreateCustomer(this.repository);

  Future<int> call(CustomerModel customer) async {
    return await repository.createCustomer(customer);
  }
}