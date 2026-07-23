import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../domain/entities/backup_sync/backup_info.dart';
import '../../../domain/entities/backup_sync/drive_account_info.dart';
import '../../../domain/repositories/backup_sync/backup_sync_repository.dart';
import '../../datasources/backup_sync/google_drive_datasource.dart';
import '../../datasources/settings_remote_datasource.dart';
import '../../models/backup_sync/backup_status_model.dart';
import '../../models/backup_sync/backup_history_entry_model.dart';

class BackupSyncRepositoryImpl implements BackupSyncRepository {
  final GoogleDriveDatasource _driveDatasource;
  final SettingsRemoteDatasource _remoteDatasource;

  BackupSyncRepositoryImpl(this._driveDatasource, this._remoteDatasource);

  @override
  Future<DriveAccountInfo?> getConnectedAccount() =>
      _driveDatasource.getConnectedAccount();

  @override
  Future<DriveAccountInfo?> connectGoogleDrive() =>
      _driveDatasource.signIn();

  @override
  Future<void> disconnectGoogleDrive() =>
      _driveDatasource.signOut();

  @override
  Future<BackupStatusModel> getBackupStatus({int userId = 1}) =>
      _remoteDatasource.getBackupStatus(userId: userId);

  @override
  Future<DateTime?> getLastSyncTime({int userId = 1}) async {
    final status = await getBackupStatus(userId: userId);
    return status.lastBackupTime;
  }

  @override
  Future<BackupInfo> backupToDrive({int userId = 1}) async {
    final zipBytes = await _remoteDatasource.createBackup(userId: userId);
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(p.join(tempDir.path, 'temp_backup.zip'));
    await tempFile.writeAsBytes(zipBytes);

    final driveInfo = await _driveDatasource.uploadBackup(tempFile);

    await _remoteDatasource.completeBackup(
      userId: userId,
      driveFileId: driveInfo.id,
      fileName: driveInfo.fileName,
      fileSize: driveInfo.sizeBytes,
      status: 'success',
    );

    await tempFile.delete();
    return driveInfo;
  }

  @override
  Future<void> restoreFromDrive({
    required String driveFileId,
    int userId = 1,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(p.join(tempDir.path, 'restore_backup.zip'));
    await _driveDatasource.downloadBackup(driveFileId, tempFile.path);
    await _remoteDatasource.restoreBackup(
      userId: userId,
      backupFile: tempFile,
    );
    await tempFile.delete();
  }

  @override
  Future<List<BackupHistoryEntryModel>> getBackupHistory({int userId = 1}) =>
      _remoteDatasource.getBackupHistory(userId: userId);

  @override
  Future<void> saveBackupSettings({
    int userId = 1,
    required Map<String, String> settings,
  }) async {
    await _remoteDatasource.saveBackupSettings(
      userId: userId,
      settings: settings,
    );
  }
}