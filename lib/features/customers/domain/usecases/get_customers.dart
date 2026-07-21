import '../../data/models/customer_model.dart';
import '../repositories/customer_repository.dart';

class GetCustomers {
  final CustomerRepository repository;

  GetCustomers(this.repository);

  Future<List<CustomerModel>> call({String search = ""}) async {
    return await repository.getCustomers(search: search);
  }
}