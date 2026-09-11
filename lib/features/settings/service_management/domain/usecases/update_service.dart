import '../../data/models/service_model.dart';
import '../repositories/service_management_repository.dart';

class UpdateService {
  final ServiceManagementRepository repository;
  UpdateService(this.repository);

  Future<bool> call(ServiceModel service) => repository.updateService(service);
}
