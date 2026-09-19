import '../../../settings/service_management/data/models/service_provider_model.dart';
import '../repositories/provider_recharge_repository.dart';

class GetRechargeProviderDetail {
  final ProviderRechargeRepository repository;
  GetRechargeProviderDetail(this.repository);

  Future<ServiceProviderModel> call(int providerId) =>
      repository.getProviderDetail(providerId);
}
