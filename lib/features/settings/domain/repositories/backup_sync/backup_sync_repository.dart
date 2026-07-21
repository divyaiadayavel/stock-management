// lib/features/settings/domain/repositories/backup_sync_repository.dart
import '../../../domain/entities/backup_sync/backup_info.dart';
import '../../../domain/entities/backup_sync/drive_account_info.dart';

abstract class BackupSyncRepository {
  Future<DriveAccountInfo?> getConnectedAccount();
  Future<DriveAccountInfo?> connectGoogleDrive();
  Future<void> disconnectGoogleDrive();

  Future<BackupInfo> createLocalBackup();
  Future<BackupInfo> backupToDrive();
  Future<void> restoreFromDrive(String fileId);
  Future<void> restoreFromLocal(String filePath);
  Future<List<BackupInfo>> getDriveBackups();

  Future<String> exportDataAsCsv();

  Future<DateTime?> getLastSyncTime();
}
