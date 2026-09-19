import '../../../settings/service_management/data/models/service_provider_model.dart';
import '../repositories/provider_recharge_repository.dart';

class GetRechargeProviders {
  final ProviderRechargeRepository repository;
  GetRechargeProviders(this.repository);

  Future<List<ServiceProviderModel>> call({int? categoryId}) =>
      repository.getProviders(categoryId: categoryId);
}
