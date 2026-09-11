import '../../../settings/service_management/data/models/service_category_model.dart';
import '../repositories/services_repository.dart';

class GetServiceCategories {
  final ServicesRepository repository;
  GetServiceCategories(this.repository);

  Future<List<ServiceCategoryModel>> call() => repository.getCategories();
}
