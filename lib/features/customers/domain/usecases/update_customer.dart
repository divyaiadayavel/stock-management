import '../../data/models/customer_model.dart';
import '../repositories/customer_repository.dart';

class UpdateCustomer {
  final CustomerRepository repository;

  UpdateCustomer(this.repository);

  Future<bool> call(CustomerModel customer) async {
    return await repository.updateCustomer(customer);
  }
}