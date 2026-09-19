import '../../data/models/provider_recharge_model.dart';
import '../repositories/provider_recharge_repository.dart';

class GetProviderRecharges {
  final ProviderRechargeRepository repository;
  GetProviderRecharges(this.repository);

  Future<List<ProviderRechargeModel>> call({int? providerId}) =>
      repository.getRecharges(providerId: providerId);
}
