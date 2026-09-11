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

  final bool isConnected;

  final DriveAccountInfo? account;

  final DateTime? lastSync;

  final String? statusMessage;

  const BackupSyncState({
    this.isLoading = false,
    this.isConnected = false,
    this.account,
    this.lastSync,
    this.statusMessage,
  });

  BackupSyncState copyWith({
    bool? isLoading,
    bool? isConnected,
    DriveAccountInfo? account,
    DateTime? lastSync,
    String? statusMessage,
  }) {
    return BackupSyncState(
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      account: account ?? this.account,
      lastSync: lastSync ?? this.lastSync,
      statusMessage: statusMessage ?? this.statusMessage,
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
    final status = await repo.getBackupStatus();
    DriveAccountInfo? account;
    if (status.googleDriveBackup) {
      account = await repo.getConnectedAccount();
    }
    state = BackupSyncState(
      isLoading: false,
      isConnected:
          status.googleDriveBackup, // <-- don't require account != null
      account: account,
      lastSync: status.lastBackupTime,
      statusMessage: null,
    );
  }

  Future<void> refreshStatus() async {
    final repo = ref.read(backupSyncRepositoryProvider);
    final account = await repo.getConnectedAccount();
    final status = await repo.getBackupStatus();
    state = BackupSyncState(
      isLoading: false,
      isConnected: status.googleDriveBackup, // <-- same fix
      account: account,
      lastSync: status.lastBackupTime,
      statusMessage: state.statusMessage,
    );
  }

  Future<void> connectDrive() async {
    state = state.copyWith(isLoading: true);

    try {
      final account = await ref.read(connectGoogleDriveProvider)();

      print("ACCOUNT = $account");

      if (account == null) {
        state = state.copyWith(
          isLoading: false,
          isConnected: false,
          account: null,
          statusMessage: 'Google Sign In cancelled',
        );
        return;
      }

      try {
        await ref
            .read(settingsRepositoryProvider)
            .saveSetting("googleDriveBackup", "true");

        await ref
            .read(backupSyncRepositoryProvider)
            .saveBackupSettings(
              settings: {
                'googleDriveBackup': 'true',
                'googleDriveEmail': account.email,
                'googleDriveDisplayName': account.displayName ?? '',
              },
            );
      } catch (e) {
        print("Save backup settings error: $e");
      }

      state = BackupSyncState(
        isLoading: false,
        isConnected: true,
        account: account,
        lastSync: state.lastSync,
        statusMessage: 'Connected successfully',
      );
    } catch (e) {
      print("Google Drive connect error: $e");

      state = state.copyWith(
        isLoading: false,
        isConnected: false,
        account: null,
        statusMessage: 'Connection failed',
      );
    }
  }

  Future<void> disconnectDrive() async {
    state = state.copyWith(isLoading: true);

    try {
      await ref.read(disconnectGoogleDriveProvider)();

      try {
        await ref
            .read(settingsRepositoryProvider)
            .saveSetting("googleDriveBackup", "false");

        await ref
            .read(backupSyncRepositoryProvider)
            .saveBackupSettings(
              settings: {
                'googleDriveBackup': 'false',
                'googleDriveEmail': '',
                'googleDriveDisplayName': '',
              },
            );
      } catch (e) {
        print("Disconnect save settings error: $e");
      }

      state = BackupSyncState(
        isLoading: false,
        isConnected: false,
        account: null,
        lastSync: state.lastSync,
        statusMessage: 'Disconnected successfully',
      );
    } catch (e) {
      print("Disconnect error: $e");

      state = state.copyWith(
        isLoading: false,
        statusMessage: 'Disconnect failed',
      );
    }
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
        isConnected: false,
        account: null,
        isLoading: false,
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
