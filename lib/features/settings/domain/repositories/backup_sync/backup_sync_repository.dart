<<<<<<< HEAD
// lib/features/settings/domain/repositories/backup_sync_repository.dart
import '../../../domain/entities/backup_sync/backup_info.dart';
import '../../../domain/entities/backup_sync/drive_account_info.dart';

abstract class BackupSyncRepository {
=======

import '../../entities/backup_sync/backup_info.dart';
import '../../entities/backup_sync/drive_account_info.dart';
import '../../../data/models/backup_sync/backup_status_model.dart';
import '../../../data/models/backup_sync/backup_history_entry_model.dart';

abstract class BackupSyncRepository {
  // Google Drive
>>>>>>> a0c881ee98585da1566c66bc95eb4ccd92b681d3
  Future<DriveAccountInfo?> getConnectedAccount();
  Future<DriveAccountInfo?> connectGoogleDrive();
  Future<void> disconnectGoogleDrive();

<<<<<<< HEAD
  Future<BackupInfo> createLocalBackup();
  Future<BackupInfo> backupToDrive();
  Future<void> restoreFromDrive(String fileId);
  Future<void> restoreFromLocal(String filePath);
  Future<List<BackupInfo>> getDriveBackups();

  Future<String> exportDataAsCsv();

  Future<DateTime?> getLastSyncTime();
}
=======
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
>>>>>>> a0c881ee98585da1566c66bc95eb4ccd92b681d3
