import '../repositories/customer_repository.dart';

class DeleteCustomer {
  final CustomerRepository repository;

  DeleteCustomer(this.repository);

  Future<bool> call(int id) async {
    return await repository.deleteCustomer(id);
  }
}