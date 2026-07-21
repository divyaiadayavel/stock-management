// lib/features/settings/domain/usecases/backup_sync/export_data.dart
import '../../repositories/backup_sync/backup_sync_repository.dart';

class ExportData {
  final BackupSyncRepository _repo;
  ExportData(this._repo);
  Future<String> call() => _repo.exportDataAsCsv();
}
