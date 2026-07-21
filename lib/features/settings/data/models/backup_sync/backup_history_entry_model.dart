// lib/features/settings/data/models/backup_history_entry_model.dart
class BackupHistoryEntryModel {
  final String fileName;
  final int sizeBytes;
  final String location; // "drive" | "local"
  final DateTime createdAt;

  BackupHistoryEntryModel({
    required this.fileName,
    required this.sizeBytes,
    required this.location,
    required this.createdAt,
  });

  factory BackupHistoryEntryModel.fromJson(Map<String, dynamic> json) {
    return BackupHistoryEntryModel(
      fileName: json['fileName']?.toString() ?? '',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      location: json['location']?.toString() ?? 'drive',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
