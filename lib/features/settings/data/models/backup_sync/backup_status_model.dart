class BackupStatusModel {
  final bool googleDriveBackup;
  final bool autoBackup;
  final String backupFrequency;
  final DateTime? lastBackupTime;
  final String? lastBackupStatus;

  BackupStatusModel({
    required this.googleDriveBackup,
    required this.autoBackup,
    required this.backupFrequency,
    this.lastBackupTime,
    this.lastBackupStatus,
  });

  factory BackupStatusModel.fromJson(Map<String, dynamic> json) {
    return BackupStatusModel(
      googleDriveBackup: json['googleDriveBackup'] == 'true',
      autoBackup: json['autoBackup'] == 'true',
      backupFrequency: json['backupFrequency'] ?? 'daily',
      lastBackupTime: json['lastBackupTime'] != null
          ? DateTime.parse(json['lastBackupTime'])
          : null,
      lastBackupStatus: json['lastBackupStatus'],
    );
  }
}