import '../../../settings/service_management/data/models/service_model.dart';
import '../repositories/services_repository.dart';

class GetServiceDetails {
  final ServicesRepository repository;
  GetServiceDetails(this.repository);

  Future<ServiceModel> call(int serviceId) => repository.getServiceDetail(serviceId);
}
