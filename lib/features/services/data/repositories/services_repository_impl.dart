// lib/features/services/data/repositories/services_repository_impl.dart
import '../../../settings/service_management/data/models/service_category_model.dart';
import '../../../settings/service_management/data/models/service_model.dart';
import '../../domain/repositories/services_repository.dart';
import '../datasources/services_remote_datasource.dart';
import '../models/service_request_model.dart';

class ServicesRepositoryImpl implements ServicesRepository {
  final ServicesRemoteDataSource remote;

  ServicesRepositoryImpl(this.remote);

  @override
  Future<List<ServiceCategoryModel>> getCategories() => remote.getCategories();

  @override
  Future<List<ServiceModel>> getServicesByCategory(int categoryId) => remote.getServicesByCategory(categoryId);

  @override
  Future<ServiceModel> getServiceDetail(int serviceId) => remote.getServiceDetail(serviceId);

  @override
  Future<ServiceRequestModel> submitServiceRequest(ServiceRequestModel request) =>
      remote.submitServiceRequest(request);

  @override
  Future<List<ServiceRequestModel>> getMyServiceRequests() => remote.getMyServiceRequests();
}
