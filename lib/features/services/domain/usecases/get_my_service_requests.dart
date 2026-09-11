import '../../data/models/service_request_model.dart';
import '../repositories/services_repository.dart';

class GetMyServiceRequests {
  final ServicesRepository repository;
  GetMyServiceRequests(this.repository);

  Future<List<ServiceRequestModel>> call() => repository.getMyServiceRequests();
}
