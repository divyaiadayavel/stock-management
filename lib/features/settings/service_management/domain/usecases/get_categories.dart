import '../../data/models/service_category_model.dart';
import '../enums/service_category_type.dart';
import '../repositories/service_management_repository.dart';

class GetCategories {
  final ServiceManagementRepository repository;
  GetCategories(this.repository);

  Future<List<ServiceCategoryModel>> call({ServiceCategoryType? type}) =>
      repository.getCategories(type: type);
}
