import '../repositories/service_management_repository.dart';

class DeleteCategory {
  final ServiceManagementRepository repository;
  DeleteCategory(this.repository);

  Future<bool> call(int id) => repository.deleteCategory(id);
}
