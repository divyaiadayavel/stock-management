// lib/features/settings/domain/usecases/backup_sync/backup_to_drive.dart
import '../../entities/backup_sync/backup_info.dart';
import '../../repositories/backup_sync/backup_sync_repository.dart';

class BackupToDrive {
  final BackupSyncRepository _repo;
  BackupToDrive(this._repo);
  Future<BackupInfo> call() => _repo.backupToDrive();
}
