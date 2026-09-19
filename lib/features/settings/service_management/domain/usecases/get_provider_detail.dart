import '../../data/models/service_provider_model.dart';
import '../repositories/service_provider_repository.dart';

class GetProviderDetail {
  final ServiceProviderRepository repository;
  GetProviderDetail(this.repository);

  Future<ServiceProviderModel> call(int id) => repository.getProviderDetail(id);
}
