import '../enums/service_category_type.dart';
import '../repositories/service_management_repository.dart';

class CreateCategory {
  final ServiceManagementRepository repository;
  CreateCategory(this.repository);

  Future<int> call(
    String name, {
    ServiceCategoryType type = ServiceCategoryType.service,
    String? description,
  }) =>
      repository.createCategory(
        name,
        type: type,
        description: description,
      );
}
