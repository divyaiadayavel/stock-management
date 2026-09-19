// lib/features/settings/service_management/domain/usecases/get_provider_reload_logs.dart
//
// NEW FILE — additive only.

import '../../data/models/provider_reload_log_model.dart';
import '../repositories/provider_reload_log_repository.dart';

class GetProviderReloadLogs {
  final ProviderReloadLogRepository repository;
  GetProviderReloadLogs(this.repository);

  Future<List<ProviderReloadLogModel>> call({int? providerId}) =>
      repository.getReloadLogs(providerId: providerId);
}
