import '../../data/models/service_model.dart';
import '../repositories/service_management_repository.dart';

class GetServiceDetails {
  final ServiceManagementRepository repository;
  GetServiceDetails(this.repository);

  Future<ServiceModel> call(int id) => repository.getServiceDetail(id);
}
