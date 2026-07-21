// lib/features/settings/domain/entities/backup_sync/backup_info.dart
enum BackupLocation { local, drive }

class BackupInfo {
  final String id; // file path (local) or Drive file id
  final String fileName;
  final DateTime createdAt;
  final int sizeBytes;
  final BackupLocation location;

  const BackupInfo({
    required this.id,
    required this.fileName,
    required this.createdAt,
    required this.sizeBytes,
    required this.location,
  });
}
