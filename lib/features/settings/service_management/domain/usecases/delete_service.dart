import '../repositories/service_management_repository.dart';

class DeleteService {
  final ServiceManagementRepository repository;
  DeleteService(this.repository);

  Future<bool> call(int id) => repository.deleteService(id);
}
