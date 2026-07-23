// lib/features/settings/domain/usecases/backup_sync/disconnect_google_drive.dart
import '../../repositories/backup_sync/backup_sync_repository.dart';

class DisconnectGoogleDrive {
  final BackupSyncRepository _repo;
  DisconnectGoogleDrive(this._repo);
  Future<void> call() => _repo.disconnectGoogleDrive();
}
