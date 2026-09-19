// lib/features/services/domain/repositories/provider_recharge_repository.dart
//
// Provider browsing re-uses the models owned by
// features/settings/service_management — that feature stays the source of
// truth for what providers exist; this one only spends their balance.
import '../../../settings/service_management/data/models/service_provider_model.dart';
import '../../data/models/provider_recharge_model.dart';

abstract class ProviderRechargeRepository {
  Future<List<ServiceProviderModel>> getProviders({int? categoryId});
  Future<ServiceProviderModel> getProviderDetail(int providerId);

  Future<ProviderRechargeModel> submitRecharge(ProviderRechargeModel recharge);

  Future<List<ProviderRechargeModel>> getRecharges({int? providerId});

  /// Records a (partial or full) payment against an existing recharge's
  /// outstanding balance — the provider-side equivalent of Sales'
  /// add_payment.php, used by the "Pay Balance" button on the recharge
  /// receipt / Provider Reports.
  Future<ProviderRechargeModel> addPayment({
    required int rechargeId,
    required String paymentMethod,
    required double amount,
  });
}
