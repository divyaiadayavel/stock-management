import '../../../domain/entities/backup_sync/backup_info.dart';
import '../../../domain/entities/backup_sync/drive_account_info.dart';
import '../../../domain/repositories/backup_sync/backup_sync_repository.dart';
import '../../datasources/backup_sync/google_drive_datasource.dart';
import '../../datasources/backup_sync/local_backup_datasource.dart';
import '../../datasources/settings_remote_datasource.dart'; // IMPORT UPDATED
import '../../models/backup_sync/backup_status_model.dart'; // IMPORT FOR MODEL
import '../../services/backup_sync/data_export_service.dart';

class BackupSyncRepositoryImpl implements BackupSyncRepository {
  final GoogleDriveDatasource _drive;
  final LocalBackupDatasource _local;
  final DataExportService _export;
  final SettingsRemoteDatasource _remote; // NEW

  BackupSyncRepositoryImpl(
    this._drive,
    this._local,
    this._export,
    this._remote, // NEW
  );

  @override
  Future<DriveAccountInfo?> getConnectedAccount() =>
      _drive.getConnectedAccount();

  @override
  Future<DriveAccountInfo?> connectGoogleDrive() async {
    try {
      // ✅ 1. Force disconnect the active cached session so Google presents the account picker screen
      await _drive.signOut();
    } catch (_) {}

    // 2. Trigger the native Google sign-in window modal sheet layout
    final account = await _drive.signIn();
    if (account == null) return null;

    try {
      await _remote.saveBackupStatus(
        BackupStatusModel(
          googleDriveBackup: true,
          autoBackup: true,
          lastSyncAt: DateTime.now(),
        ),
      );
    } catch (e) {
      print("Remote logging error bypassed safely: $e");
    }

    return account;
  }

  @override
  Future<void> disconnectGoogleDrive() async {
    // 1. Cleanly sign out of the native Google authentication layer
    await _drive.signOut();

    try {
      // ✅ 2. Wrapped in a try-catch safety net to prevent server errors
      // from blocking your local app state adjustments
      await _remote.saveBackupStatus(
        BackupStatusModel(googleDriveBackup: false, autoBackup: false),
      );
    } catch (e) {
      print("Remote tracking signout error bypassed: $e");
    }
  }

  @override
  Future<BackupInfo> createLocalBackup() => _local.createLocalBackup();

  @override
  Future<BackupInfo> backupToDrive() async {
    final dbFile = await _local.liveDbFileForUpload;
    final info = await _drive.uploadBackup(dbFile);

    try {
      // ✅ Protected by try-catch to keep server errors from breaking the sync completion status
      await _remote.recordBackupEvent(
        fileName: info.fileName,
        sizeBytes: info.sizeBytes,
        location: 'drive',
      );
    } catch (e) {
      print("Remote backup event logging bypassed safely: $e");
    }

    return info;
  }

  @override
  Future<List<BackupInfo>> getDriveBackups() => _drive.listBackups();

  @override
  Future<void> restoreFromDrive(String fileId) async {
    final dbFile = await _local.liveDbFileForUpload;
    // NOTE: close your active DBHelper database connection before this runs.
    await _drive.downloadBackup(fileId, dbFile.path);
  }

  @override
  Future<void> restoreFromLocal(String filePath) =>
      _local.restoreFromFile(filePath);

  @override
  Future<String> exportDataAsCsv() => _export.exportAsCsv();

  @override
  Future<DateTime?> getLastSyncTime() async {
    final status = await _remote.getBackupStatus();
    if (status.lastSyncAt != null) return status.lastSyncAt;

    // fallback to Drive listing if server has no record yet
    final backups = await _drive.listBackups();
    return backups.isEmpty ? null : backups.first.createdAt;
  }
}
