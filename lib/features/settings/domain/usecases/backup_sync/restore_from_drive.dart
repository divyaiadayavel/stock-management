import '../../repositories/backup_sync/backup_sync_repository.dart';

class RestoreFromDrive {
  final BackupSyncRepository repository;

  RestoreFromDrive(this.repository);

  Future<void> call({required String driveFileId, int userId = 1}) async {
    await repository.restoreFromDrive(driveFileId: driveFileId, userId: userId);
  }
}