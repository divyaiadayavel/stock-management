// lib/features/services/domain/usecases/add_provider_recharge_payment.dart
import '../repositories/provider_recharge_repository.dart';
import '../../data/models/provider_recharge_model.dart';

/// Records a (partial or full) payment against an existing recharge's
/// outstanding balance — provider-side equivalent of Sales' AddPayment.
class AddProviderRechargePayment {
  final ProviderRechargeRepository repository;

  AddProviderRechargePayment(this.repository);

  Future<ProviderRechargeModel> call({
    required int rechargeId,
    required String paymentMethod,
    required double amount,
  }) {
    return repository.addPayment(
      rechargeId: rechargeId,
      paymentMethod: paymentMethod,
      amount: amount,
    );
  }
}
