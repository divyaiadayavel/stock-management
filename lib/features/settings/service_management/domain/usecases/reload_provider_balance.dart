import '../../data/models/service_provider_model.dart';
import '../repositories/service_provider_repository.dart';

class ReloadProviderBalance {
  final ServiceProviderRepository repository;
  ReloadProviderBalance(this.repository);

  Future<ServiceProviderModel> call(int id, double amount, {String? note}) =>
      repository.reloadBalance(id, amount, note: note);
}
