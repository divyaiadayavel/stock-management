import '../../../settings/service_management/data/models/service_model.dart';
import '../repositories/services_repository.dart';

class GetServicesByCategory {
  final ServicesRepository repository;
  GetServicesByCategory(this.repository);

  Future<List<ServiceModel>> call(int categoryId) => repository.getServicesByCategory(categoryId);
}
