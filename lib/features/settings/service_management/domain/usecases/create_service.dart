import '../../data/models/service_model.dart';
import '../repositories/service_management_repository.dart';

class CreateService {
  final ServiceManagementRepository repository;
  CreateService(this.repository);

  Future<int> call(ServiceModel service) => repository.createService(service);
}
