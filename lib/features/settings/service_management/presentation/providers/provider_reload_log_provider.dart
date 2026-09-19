// lib/features/settings/service_management/presentation/providers/provider_reload_log_provider.dart
//
// NEW FILE — additive only. Wires its own http.Client/datasource/repository
// exactly like provider_recharge_provider.dart does for recharges, so
// service_provider_provider.dart is left completely untouched.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../data/datasources/provider_reload_log_remote_datasource.dart';
import '../../data/models/provider_reload_log_model.dart';
import '../../data/repositories/provider_reload_log_repository_impl.dart';
import '../../domain/repositories/provider_reload_log_repository.dart';
import '../../domain/usecases/get_provider_reload_logs.dart';

final _reloadLogHttpClientProvider = Provider<http.Client>(
  (ref) => http.Client(),
);

final providerReloadLogRemoteSourceProvider =
    Provider<ProviderReloadLogRemoteDataSource>((ref) {
  return ProviderReloadLogRemoteDataSource(
    client: ref.watch(_reloadLogHttpClientProvider),
  );
});

final providerReloadLogRepositoryProvider =
    Provider<ProviderReloadLogRepository>((ref) {
  return ProviderReloadLogRepositoryImpl(
    ref.watch(providerReloadLogRemoteSourceProvider),
  );
});

final _getProviderReloadLogsProvider = Provider(
  (ref) => GetProviderReloadLogs(ref.watch(providerReloadLogRepositoryProvider)),
);

/// Reload/initial-load history, optionally scoped to one provider.
/// This is the data source Provider Reports' "Reload Amount" tab reads from.
final providerReloadLogHistoryProvider =
    FutureProvider.family<List<ProviderReloadLogModel>, int?>(
        (ref, providerId) {
  return ref
      .read(_getProviderReloadLogsProvider)
      .call(providerId: providerId);
});
