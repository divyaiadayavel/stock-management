import '../../data/models/provider_recharge_model.dart';
import '../repositories/provider_recharge_repository.dart';

class SubmitProviderRecharge {
  final ProviderRechargeRepository repository;
  SubmitProviderRecharge(this.repository);

  Future<ProviderRechargeModel> call(ProviderRechargeModel recharge) =>
      repository.submitRecharge(recharge);
}
