// lib/features/settings/domain/usecases/backup_sync/connect_google_drive.dart
import '../../entities/backup_sync/drive_account_info.dart';
import '../../repositories/backup_sync/backup_sync_repository.dart';

class ConnectGoogleDrive {
  final BackupSyncRepository _repo;
  ConnectGoogleDrive(this._repo);
  Future<DriveAccountInfo?> call() => _repo.connectGoogleDrive();
}
