// lib/features/settings/service_management/domain/repositories/provider_reload_log_repository.dart
//
// NEW FILE — additive only. Kept as its own small repository instead of
// adding a method to ServiceProviderRepository, so the existing repository
// interface/impl/datasource are left completely untouched.

import '../../data/models/provider_reload_log_model.dart';

abstract class ProviderReloadLogRepository {
  Future<List<ProviderReloadLogModel>> getReloadLogs({int? providerId});
}
