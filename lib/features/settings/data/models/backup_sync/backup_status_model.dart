<<<<<<< HEAD
// lib/features/settings/data/models/backup_status_model.dart
class BackupStatusModel {
  final bool googleDriveBackup;
  final bool autoBackup;
  final DateTime? lastSyncAt;
  final String? driveEmail;
=======
class BackupStatusModel {
  final bool googleDriveBackup;
  final bool autoBackup;
  final String backupFrequency;
  final DateTime? lastBackupTime;
  final String? lastBackupStatus;
>>>>>>> a0c881ee98585da1566c66bc95eb4ccd92b681d3

  BackupStatusModel({
    required this.googleDriveBackup,
    required this.autoBackup,
<<<<<<< HEAD
    this.lastSyncAt,
    this.driveEmail,
=======
    required this.backupFrequency,
    this.lastBackupTime,
    this.lastBackupStatus,
>>>>>>> a0c881ee98585da1566c66bc95eb4ccd92b681d3
  });

  factory BackupStatusModel.fromJson(Map<String, dynamic> json) {
    return BackupStatusModel(
<<<<<<< HEAD
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
=======
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
>>>>>>> a0c881ee98585da1566c66bc95eb4ccd92b681d3
