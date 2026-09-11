// lib/features/services/domain/repositories/services_repository.dart
//
// Category/service browsing re-uses the exact same models produced by
// features/settings/service_management — that feature is the source of
// truth for what services & questions exist; this feature only adds the
// ability to submit an answer set against them.
import '../../../settings/service_management/data/models/service_category_model.dart';
import '../../../settings/service_management/data/models/service_model.dart';
import '../../data/models/service_request_model.dart';

abstract class ServicesRepository {
  Future<List<ServiceCategoryModel>> getCategories();
  Future<List<ServiceModel>> getServicesByCategory(int categoryId);
  Future<ServiceModel> getServiceDetail(int serviceId);

  /// Submits a filled form. Returns the created request (with the
  /// server-assigned invoice number) on success.
  Future<ServiceRequestModel> submitServiceRequest(ServiceRequestModel request);

  Future<List<ServiceRequestModel>> getMyServiceRequests();
}
