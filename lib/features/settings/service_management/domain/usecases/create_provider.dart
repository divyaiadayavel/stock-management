import '../../data/models/service_provider_model.dart';
import '../repositories/service_provider_repository.dart';

class CreateProvider {
  final ServiceProviderRepository repository;
  CreateProvider(this.repository);

  Future<ServiceProviderModel> call(ServiceProviderModel provider) =>
      repository.createProvider(provider);
}
