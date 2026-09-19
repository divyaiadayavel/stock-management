// lib/features/settings/service_management/data/repositories/service_management_repository_impl.dart
import '../../domain/enums/service_category_type.dart';
import '../../domain/repositories/service_management_repository.dart';
import '../datasources/service_management_remote_datasource.dart';
import '../models/service_category_model.dart';
import '../models/service_model.dart';

class ServiceManagementRepositoryImpl implements ServiceManagementRepository {
  final ServiceManagementRemoteDataSource remote;

  ServiceManagementRepositoryImpl(this.remote);

  @override
  Future<List<ServiceCategoryModel>> getCategories({
    ServiceCategoryType? type,
  }) =>
      remote.getCategories(type: type);

  @override
  Future<int> createCategory(
    String name, {
    ServiceCategoryType type = ServiceCategoryType.service,
    String? description,
  }) =>
      remote.createCategory(
        name,
        type: type,
        description: description,
      );

  @override
  Future<bool> deleteCategory(int id) => remote.deleteCategory(id);

  @override
  Future<List<ServiceModel>> getServices({int? categoryId}) =>
      remote.getServices(categoryId: categoryId);

  @override
  Future<ServiceModel> getServiceDetail(int id) => remote.getServiceDetail(id);

  @override
  Future<int> createService(ServiceModel service) => remote.createService(service);

  @override
  Future<bool> updateService(ServiceModel service) => remote.updateService(service);

  @override
  Future<bool> deleteService(int id) => remote.deleteService(id);
}
