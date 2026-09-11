
import '../../entities/backup_sync/backup_info.dart';
import '../../entities/backup_sync/drive_account_info.dart';
import '../../../data/models/backup_sync/backup_status_model.dart';
import '../../../data/models/backup_sync/backup_history_entry_model.dart';

abstract class BackupSyncRepository {
  // Google Drive
  Future<DriveAccountInfo?> getConnectedAccount();
  Future<DriveAccountInfo?> connectGoogleDrive();
  Future<void> disconnectGoogleDrive();

  // Status
  Future<BackupStatusModel> getBackupStatus({int userId = 1});
  Future<DateTime?> getLastSyncTime({int userId = 1});

  // Backup to Drive (full flow: create + upload + complete)
  Future<BackupInfo> backupToDrive({int userId = 1});

  // Restore from Drive (download + upload to server)
  Future<void> restoreFromDrive({required String driveFileId, int userId = 1});

  // History
  Future<List<BackupHistoryEntryModel>> getBackupHistory({int userId = 1});

  // Settings
  Future<void> saveBackupSettings({int userId = 1, required Map<String, String> settings});
}