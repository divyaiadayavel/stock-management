// lib/features/settings/data/models/backup_status_model.dart
class BackupStatusModel {
  final bool googleDriveBackup;
  final bool autoBackup;
  final DateTime? lastSyncAt;
  final String? driveEmail;

  BackupStatusModel({
    required this.googleDriveBackup,
    required this.autoBackup,
    this.lastSyncAt,
    this.driveEmail,
  });

  factory BackupStatusModel.fromJson(Map<String, dynamic> json) {
    return BackupStatusModel(
      googleDriveBackup:
          json['googleDriveBackup'] == true ||
          json['googleDriveBackup'] == 'true',
      autoBackup: json['autoBackup'] == true || json['autoBackup'] == 'true',
      lastSyncAt: json['lastSyncAt'] != null
          ? DateTime.tryParse(json['lastSyncAt'].toString())
          : null,
      driveEmail: json['driveEmail']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'googleDriveBackup': googleDriveBackup,
    'autoBackup': autoBackup,
    if (lastSyncAt != null) 'lastSyncAt': lastSyncAt!.toIso8601String(),
    if (driveEmail != null) 'driveEmail': driveEmail,
  };
}
