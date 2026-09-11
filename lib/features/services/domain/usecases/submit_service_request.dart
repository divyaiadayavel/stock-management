import '../../data/models/service_request_model.dart';
import '../repositories/services_repository.dart';

class SubmitServiceRequest {
  final ServicesRepository repository;
  SubmitServiceRequest(this.repository);

  Future<ServiceRequestModel> call(ServiceRequestModel request) =>
      repository.submitServiceRequest(request);
}
