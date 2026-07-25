import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/backup_sync/google_drive_datasource.dart';
import '../../../data/datasources/settings_remote_datasource.dart';
import '../../../data/repositories/backup_sync/backup_sync_repository_impl.dart';
import '../../../domain/entities/backup_sync/backup_info.dart';
import '../../../domain/entities/backup_sync/drive_account_info.dart';
import '../../../domain/repositories/backup_sync/backup_sync_repository.dart';
import '../../../domain/usecases/backup_sync/backup_to_drive.dart';
import '../../../domain/usecases/backup_sync/connect_google_drive.dart';
import '../../../domain/usecases/backup_sync/disconnect_google_drive.dart';
import '../../../domain/usecases/backup_sync/restore_from_drive.dart';
import '../../../data/models/backup_sync/backup_history_entry_model.dart'; // <-- ADD THIS
import '../settings_provider.dart';

// ── Remote Datasource Provider ──────────────────────────────
final settingsRemoteDatasourceProvider = Provider<SettingsRemoteDatasource>(
  (ref) => SettingsRemoteDatasource(),
);

// ── Repository Provider ──────────────────────────────────────
final backupSyncRepositoryProvider = Provider<BackupSyncRepository>((ref) {
  return BackupSyncRepositoryImpl(
    GoogleDriveDatasource(),
    ref.read(settingsRemoteDatasourceProvider),
  );
});

// ── Use Case Providers ───────────────────────────────────────
final connectGoogleDriveProvider = Provider(
  (ref) => ConnectGoogleDrive(ref.read(backupSyncRepositoryProvider)),
);
final disconnectGoogleDriveProvider = Provider(
  (ref) => DisconnectGoogleDrive(ref.read(backupSyncRepositoryProvider)),
);
final backupToDriveProvider = Provider(
  (ref) => BackupToDrive(ref.read(backupSyncRepositoryProvider)),
);
final restoreFromDriveProvider = Provider(
  (ref) => RestoreFromDrive(ref.read(backupSyncRepositoryProvider)),
);

// ── State ─────────────────────────────────────────────────────
class BackupSyncState {
  final bool isLoading;
  final DriveAccountInfo? account;
  final DateTime? lastSync;
  final String? statusMessage;

  const BackupSyncState({
    this.isLoading = false,
    this.account,
    this.lastSync,
    this.statusMessage,
  });

  BackupSyncState copyWith({
    bool? isLoading,
    DriveAccountInfo? account,
    DateTime? lastSync,
    String? statusMessage,
  }) {
    return BackupSyncState(
      isLoading: isLoading ?? this.isLoading,
      account: account,
      lastSync: lastSync ?? this.lastSync,
      statusMessage: statusMessage,
    );
  }
}

// ── Controller ───────────────────────────────────────────────
final backupSyncControllerProvider =
    StateNotifierProvider.autoDispose<BackupSyncController, BackupSyncState>(
      (ref) => BackupSyncController(ref),
    );

class BackupSyncController extends StateNotifier<BackupSyncState> {
  final Ref ref;
  BackupSyncController(this.ref) : super(const BackupSyncState()) {
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final repo = ref.read(backupSyncRepositoryProvider);
    final account = await repo.getConnectedAccount();
    final status = await repo.getBackupStatus();
    state = BackupSyncState(
      account: account,
      lastSync: status.lastBackupTime,
      isLoading: false,
      statusMessage: null,
    );
  }

  Future<void> refreshStatus() async {
    final repo = ref.read(backupSyncRepositoryProvider);
    final account = await repo.getConnectedAccount();
    final status = await repo.getBackupStatus();
    state = BackupSyncState(
      account: account,
      lastSync: status.lastBackupTime,
      isLoading: false,
      statusMessage: state.statusMessage,
    );
  }

  Future<void> connectDrive() async {
    state = state.copyWith(isLoading: true);
    final account = await ref.read(connectGoogleDriveProvider)();

    if (account != null) {
      await ref
          .read(settingsRepositoryProvider)
          .saveSetting("googleDriveBackup", "true");
      await ref
          .read(backupSyncRepositoryProvider)
          .saveBackupSettings(settings: {'googleDriveBackup': 'true'});
      state = BackupSyncState(
        account: account,
        lastSync: state.lastSync,
        isLoading: false,
        statusMessage: 'Connected successfully',
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> disconnectDrive() async {
    state = state.copyWith(isLoading: true);
    await ref.read(disconnectGoogleDriveProvider)();

    await ref
        .read(settingsRepositoryProvider)
        .saveSetting("googleDriveBackup", "false");
    await ref
        .read(backupSyncRepositoryProvider)
        .saveBackupSettings(settings: {'googleDriveBackup': 'false'});

    state = BackupSyncState(
      account: null,
      lastSync: state.lastSync,
      isLoading: false,
      statusMessage: 'Disconnected successfully',
    );
  }

  Future<BackupInfo?> backupNow() async {
    if (state.account == null) return null;
    state = state.copyWith(isLoading: true, statusMessage: 'Syncing...');
    try {
      final info = await ref.read(backupToDriveProvider)();
      state = state.copyWith(
        isLoading: false,
        lastSync: info.createdAt,
        statusMessage: 'Backup complete',
      );
      return info;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        statusMessage: 'Backup failed: $e',
      );
      return null;
    }
  }

  // Fetch backup history
  Future<List<BackupHistoryEntryModel>> fetchHistory() async {
    final repo = ref.read(backupSyncRepositoryProvider);
    return await repo.getBackupHistory();
  }

  // Restore from Drive by file ID
  Future<void> restoreFromDrive(String driveFileId) async {
    state = state.copyWith(isLoading: true, statusMessage: 'Restoring...');
    try {
      await ref.read(restoreFromDriveProvider)(driveFileId: driveFileId);
      state = state.copyWith(
        isLoading: false,
        statusMessage: 'Restore successful',
      );
      await refreshStatus();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        statusMessage: 'Restore failed: $e',
      );
      rethrow;
    }
  }
}
