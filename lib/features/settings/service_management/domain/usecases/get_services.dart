import '../../data/models/service_model.dart';
import '../repositories/service_management_repository.dart';

class GetServices {
  final ServiceManagementRepository repository;
  GetServices(this.repository);

  Future<List<ServiceModel>> call({int? categoryId}) =>
      repository.getServices(categoryId: categoryId);
}
