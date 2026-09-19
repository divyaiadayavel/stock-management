// lib/features/settings/service_management/data/repositories/provider_reload_log_repository_impl.dart
//
// NEW FILE — additive only.

import '../../domain/repositories/provider_reload_log_repository.dart';
import '../datasources/provider_reload_log_remote_datasource.dart';
import '../models/provider_reload_log_model.dart';

class ProviderReloadLogRepositoryImpl implements ProviderReloadLogRepository {
  final ProviderReloadLogRemoteDataSource remote;

  ProviderReloadLogRepositoryImpl(this.remote);

  @override
  Future<List<ProviderReloadLogModel>> getReloadLogs({int? providerId}) =>
      remote.getReloadLogs(providerId: providerId);
}
