// lib/features/services/data/repositories/provider_recharge_repository_impl.dart
import '../../../settings/service_management/data/models/service_provider_model.dart';
import '../../domain/repositories/provider_recharge_repository.dart';
import '../datasources/provider_recharge_remote_datasource.dart';
import '../models/provider_recharge_model.dart';

class ProviderRechargeRepositoryImpl implements ProviderRechargeRepository {
  final ProviderRechargeRemoteDataSource remote;

  ProviderRechargeRepositoryImpl(this.remote);

  @override
  Future<List<ServiceProviderModel>> getProviders({int? categoryId}) =>
      remote.getProviders(categoryId: categoryId);

  @override
  Future<ServiceProviderModel> getProviderDetail(int providerId) =>
      remote.getProviderDetail(providerId);

  @override
  Future<ProviderRechargeModel> submitRecharge(
    ProviderRechargeModel recharge,
  ) =>
      remote.submitRecharge(recharge);

  @override
  Future<List<ProviderRechargeModel>> getRecharges({int? providerId}) =>
      remote.getRecharges(providerId: providerId);

  @override
  Future<ProviderRechargeModel> addPayment({
    required int rechargeId,
    required String paymentMethod,
    required double amount,
  }) =>
      remote.addPayment(
        rechargeId: rechargeId,
        paymentMethod: paymentMethod,
        amount: amount,
      );
}
