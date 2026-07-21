// lib/features/settings/domain/usecases/backup_sync/restore_from_drive.dart
import '../../repositories/backup_sync/backup_sync_repository.dart';

class RestoreFromDrive {
  final BackupSyncRepository _repo;
  RestoreFromDrive(this._repo);
  Future<void> call(String fileId) => _repo.restoreFromDrive(fileId);
}
