<<<<<<< HEAD
// lib/features/settings/domain/usecases/backup_sync/restore_from_drive.dart
import '../../repositories/backup_sync/backup_sync_repository.dart';

class RestoreFromDrive {
  final BackupSyncRepository _repo;
  RestoreFromDrive(this._repo);
  Future<void> call(String fileId) => _repo.restoreFromDrive(fileId);
}
=======
import '../../repositories/backup_sync/backup_sync_repository.dart';

class RestoreFromDrive {
  final BackupSyncRepository repository;

  RestoreFromDrive(this.repository);

  Future<void> call({required String driveFileId, int userId = 1}) async {
    await repository.restoreFromDrive(driveFileId: driveFileId, userId: userId);
  }
}
>>>>>>> a0c881ee98585da1566c66bc95eb4ccd92b681d3
