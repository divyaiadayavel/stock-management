// lib/features/settings/service_management/domain/repositories/service_management_repository.dart
import '../../data/models/service_category_model.dart';
import '../../data/models/service_model.dart';
import '../enums/service_category_type.dart';

abstract class ServiceManagementRepository {
  /// Omit [type] to load both tabs in one call.
  Future<List<ServiceCategoryModel>> getCategories({
    ServiceCategoryType? type,
  });

  Future<int> createCategory(
    String name, {
    ServiceCategoryType type,
    String? description,
  });

  Future<bool> deleteCategory(int id);

  Future<List<ServiceModel>> getServices({int? categoryId});
  Future<ServiceModel> getServiceDetail(int id);
  Future<int> createService(ServiceModel service);
  Future<bool> updateService(ServiceModel service);
  Future<bool> deleteService(int id);
}
