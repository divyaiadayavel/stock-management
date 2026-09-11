import '../repositories/service_management_repository.dart';

class CreateCategory {
  final ServiceManagementRepository repository;
  CreateCategory(this.repository);

  Future<int> call(String name) => repository.createCategory(name);
}
