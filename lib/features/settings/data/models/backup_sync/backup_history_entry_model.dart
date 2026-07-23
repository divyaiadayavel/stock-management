class BackupHistoryEntryModel {
  final int id;
  final String backupName;
  final String status;
  final String fileName;
  final String? driveFileId;
  final int fileSize;
  final DateTime createdAt;
  final DateTime? completedAt;

  BackupHistoryEntryModel({
    required this.id,
    required this.backupName,
    required this.status,
    required this.fileName,
    this.driveFileId,
    required this.fileSize,
    required this.createdAt,
    this.completedAt,
  });

  factory BackupHistoryEntryModel.fromJson(Map<String, dynamic> json) {
    return BackupHistoryEntryModel(
      id: json['id'] as int,
      backupName: json['backup_name'] ?? '',
      status: json['backup_status'] ?? 'unknown',
      fileName: json['file_name'] ?? '',
      driveFileId: json['drive_file_id'],
      fileSize: json['file_size'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }
}