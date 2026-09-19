import '../repositories/service_provider_repository.dart';

class DeleteProvider {
  final ServiceProviderRepository repository;
  DeleteProvider(this.repository);

  Future<bool> call(int id) => repository.deleteProvider(id);
}
