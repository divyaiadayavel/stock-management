import '../../data/models/service_provider_model.dart';
import '../repositories/service_provider_repository.dart';

class UpdateProvider {
  final ServiceProviderRepository repository;
  UpdateProvider(this.repository);

  Future<ServiceProviderModel> call(ServiceProviderModel provider) =>
      repository.updateProvider(provider);
}
