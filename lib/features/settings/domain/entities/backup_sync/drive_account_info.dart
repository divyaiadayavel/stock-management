// lib/features/settings/domain/entities/backup_sync/drive_account_info.dart
class DriveAccountInfo {
  final String email;
  final String? displayName;
  final String? photoUrl;

  const DriveAccountInfo({
    required this.email,
    this.displayName,
    this.photoUrl,
  });
}
