// lib/features/settings/data/datasources/backup_sync/local_backup_datasource.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../../../core/storage/db_helper.dart'; // IMPORT FOR YOUR DB HELPER
import '../../../domain/entities/backup_sync/backup_info.dart';

class LocalBackupDatasource {
  Future<File> _getLiveDbFile() async {
    // 🔹 DYNAMIC RESOLUTION: Asks DBHelper directly for the absolute working db path
    final dbPath = await DBHelper.getDbPath();
    return File(dbPath);
  }

  Future<Directory> _getBackupDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${dir.path}/backups');
    if (!await backupDir.exists()) await backupDir.create(recursive: true);
    return backupDir;
  }

  Future<BackupInfo> createLocalBackup() async {
    final liveDb = await _getLiveDbFile();
    if (!await liveDb.exists()) {
      throw Exception("Live database file not found at path: ${liveDb.path}");
    }

    final backupDir = await _getBackupDir();
    final fileName = 'backup_${DateTime.now().millisecondsSinceEpoch}.db';
    final copy = await liveDb.copy('${backupDir.path}/$fileName');

    return BackupInfo(
      id: copy.path,
      fileName: fileName,
      createdAt: DateTime.now(),
      sizeBytes: await copy.length(),
      location: BackupLocation.local,
    );
  }

  /// Call this only after closing the active sqflite Database instance,
  /// otherwise the file is locked and this will fail.
  Future<void> restoreFromFile(String sourcePath) async {
    final liveDb = await _getLiveDbFile();
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw Exception("Source backup file data missing: $sourcePath");
    }
    await source.copy(liveDb.path);
  }

  Future<File> get liveDbFileForUpload => _getLiveDbFile();
}
