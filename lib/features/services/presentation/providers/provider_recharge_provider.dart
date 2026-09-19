// lib/features/services/presentation/providers/provider_recharge_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../settings/service_management/data/models/service_provider_model.dart';
import '../../data/datasources/provider_recharge_remote_datasource.dart';
import '../../data/models/provider_recharge_model.dart';
import '../../data/repositories/provider_recharge_repository_impl.dart';
import '../../domain/repositories/provider_recharge_repository.dart';
import '../../domain/usecases/add_provider_recharge_payment.dart';
import '../../domain/usecases/get_provider_recharges.dart';
import '../../domain/usecases/get_recharge_provider_detail.dart';
import '../../domain/usecases/get_recharge_providers.dart';
import '../../domain/usecases/submit_provider_recharge.dart';

// ─── Dependency wiring ──────────────────────────────────────
final _rechargeHttpClientProvider = Provider<http.Client>(
  (ref) => http.Client(),
);

final providerRechargeRemoteSourceProvider =
    Provider<ProviderRechargeRemoteDataSource>((ref) {
  return ProviderRechargeRemoteDataSource(
    client: ref.watch(_rechargeHttpClientProvider),
  );
});

final providerRechargeRepositoryProvider =
    Provider<ProviderRechargeRepository>((ref) {
  return ProviderRechargeRepositoryImpl(
    ref.watch(providerRechargeRemoteSourceProvider),
  );
});

final _getRechargeProvidersProvider = Provider(
  (ref) => GetRechargeProviders(ref.watch(providerRechargeRepositoryProvider)),
);

final _getRechargeProviderDetailProvider = Provider(
  (ref) =>
      GetRechargeProviderDetail(ref.watch(providerRechargeRepositoryProvider)),
);

final _submitProviderRechargeProvider = Provider(
  (ref) =>
      SubmitProviderRecharge(ref.watch(providerRechargeRepositoryProvider)),
);

final _getProviderRechargesProvider = Provider(
  (ref) => GetProviderRecharges(ref.watch(providerRechargeRepositoryProvider)),
);

final addProviderRechargePaymentUseCaseProvider = Provider(
  (ref) =>
      AddProviderRechargePayment(ref.watch(providerRechargeRepositoryProvider)),
);

// ─── Browse ─────────────────────────────────────────────────
/// All active providers (the "Provider" tab on the Services screen).
final userProvidersProvider =
    FutureProvider<List<ServiceProviderModel>>((ref) {
  return ref.read(_getRechargeProvidersProvider).call();
});

/// Providers of one category.
final userProvidersByCategoryProvider =
    FutureProvider.family<List<ServiceProviderModel>, int>((ref, categoryId) {
  return ref.read(_getRechargeProvidersProvider).call(categoryId: categoryId);
});

/// Provider detail with its questions and live balance. autoDispose so the
/// balance is always re-fetched when the recharge form is reopened.
final userProviderDetailProvider = FutureProvider.autoDispose
    .family<ServiceProviderModel, int>((ref, providerId) {
  return ref.read(_getRechargeProviderDetailProvider).call(providerId);
});

/// Recharge history, optionally scoped to a provider.
final providerRechargeHistoryProvider =
    FutureProvider.family<List<ProviderRechargeModel>, int?>(
        (ref, providerId) {
  return ref.read(_getProviderRechargesProvider).call(providerId: providerId);
});

// ─── In-progress recharge answers, keyed by question id ─────
class ProviderFormAnswersNotifier extends StateNotifier<Map<int, Object?>> {
  ProviderFormAnswersNotifier() : super({});

  void setAnswer(int questionId, Object? value) {
    state = {...state, questionId: value};
  }

  void reset() => state = {};
}

final providerFormAnswersProvider =
    StateNotifierProvider<ProviderFormAnswersNotifier, Map<int, Object?>>(
  (ref) => ProviderFormAnswersNotifier(),
);

// ─── Submit ─────────────────────────────────────────────────
class ProviderRechargeSubmitNotifier
    extends StateNotifier<AsyncValue<ProviderRechargeModel?>> {
  final Ref ref;

  ProviderRechargeSubmitNotifier(this.ref)
      : super(const AsyncValue.data(null));

  Future<ProviderRechargeModel?> submit(ProviderRechargeModel recharge) async {
    state = const AsyncValue.loading();

    try {
      final result =
          await ref.read(_submitProviderRechargeProvider).call(recharge);

      // Balance moved — everything showing it must refetch.
      ref.invalidate(userProvidersProvider);
      ref.invalidate(userProvidersByCategoryProvider);
      ref.invalidate(userProviderDetailProvider(recharge.providerId));
      ref.invalidate(providerRechargeHistoryProvider);

      if (mounted) {
        state = AsyncValue.data(result);
      }

      return result;
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }

      return null;
    }
  }
}

final providerRechargeSubmitProvider = StateNotifierProvider<
    ProviderRechargeSubmitNotifier, AsyncValue<ProviderRechargeModel?>>(
  (ref) => ProviderRechargeSubmitNotifier(ref),
);
