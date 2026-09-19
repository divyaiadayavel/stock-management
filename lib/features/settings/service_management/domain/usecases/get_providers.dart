import '../../data/models/service_provider_model.dart';
import '../repositories/service_provider_repository.dart';

class GetProviders {
  final ServiceProviderRepository repository;
  GetProviders(this.repository);

  Future<List<ServiceProviderModel>> call({int? categoryId}) =>
      repository.getProviders(categoryId: categoryId);
}
