// lib/features/settings/domain/usecases/backup_sync/create_local_backup.dart
import '../../entities/backup_sync/backup_info.dart';
import '../../repositories/backup_sync/backup_sync_repository.dart';

class CreateLocalBackup {
  final BackupSyncRepository _repo;
  CreateLocalBackup(this._repo);
  Future<BackupInfo> call() => _repo.createLocalBackup();
}
