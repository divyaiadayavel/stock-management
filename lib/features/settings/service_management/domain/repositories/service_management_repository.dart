// lib/features/settings/service_management/domain/repositories/service_management_repository.dart
import '../../data/models/service_category_model.dart';
import '../../data/models/service_model.dart';

abstract class ServiceManagementRepository {
  Future<List<ServiceCategoryModel>> getCategories();
  Future<int> createCategory(String name);
  Future<bool> deleteCategory(int id);

  Future<List<ServiceModel>> getServices({int? categoryId});
  Future<ServiceModel> getServiceDetail(int id);
  Future<int> createService(ServiceModel service);
  Future<bool> updateService(ServiceModel service);
  Future<bool> deleteService(int id);
}
