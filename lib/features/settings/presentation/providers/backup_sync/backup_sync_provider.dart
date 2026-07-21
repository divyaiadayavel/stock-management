import 'package:flutter_riverpod/flutter_riverpod.dart';

// Data layer imports
import '../../../data/datasources/backup_sync/google_drive_datasource.dart';
import '../../../data/datasources/backup_sync/local_backup_datasource.dart';
import '../../../data/datasources/settings_remote_datasource.dart'; // IMPORT FOR REMOTE DATASOURCE
import '../../../data/repositories/backup_sync/backup_sync_repository_impl.dart';
import '../../../data/services/backup_sync/data_export_service.dart';

// Domain layer entities & repositories
import '../../../domain/entities/backup_sync/backup_info.dart';
import '../../../domain/entities/backup_sync/drive_account_info.dart';
import '../../../domain/repositories/backup_sync/backup_sync_repository.dart';

// Domain layer use cases
import '../../../domain/usecases/backup_sync/backup_to_drive.dart';
import '../../../domain/usecases/backup_sync/connect_google_drive.dart';
import '../../../domain/usecases/backup_sync/create_local_backup.dart';
import '../../../domain/usecases/backup_sync/disconnect_google_drive.dart';
import '../../../domain/usecases/backup_sync/export_data.dart';
import '../../../domain/usecases/backup_sync/restore_from_drive.dart';
import '../settings_provider.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:stock_management/core/storage/db_helper.dart'; // ✅ Absolute package path import

// ── Remote Datasource Provider ───────────────────────────────────────────────
final settingsRemoteDatasourceProvider = Provider<SettingsRemoteDatasource>(
  (ref) => SettingsRemoteDatasource(),
);

// ── Repository Provider (With remote datasource dependency injected) ──────────
final backupSyncRepositoryProvider = Provider<BackupSyncRepository>((ref) {
  return BackupSyncRepositoryImpl(
    GoogleDriveDatasource(),
    LocalBackupDatasource(),
    DataExportService(),
    ref.read(
      settingsRemoteDatasourceProvider,
    ), // Injected combined remote datasource
  );
});

// ── Use Case Providers ───────────────────────────────────────────────────────
final connectGoogleDriveProvider = Provider(
  (ref) => ConnectGoogleDrive(ref.read(backupSyncRepositoryProvider)),
);
final disconnectGoogleDriveProvider = Provider(
  (ref) => DisconnectGoogleDrive(ref.read(backupSyncRepositoryProvider)),
);
final backupToDriveProvider = Provider(
  (ref) => BackupToDrive(ref.read(backupSyncRepositoryProvider)),
);
final createLocalBackupProvider = Provider(
  (ref) => CreateLocalBackup(ref.read(backupSyncRepositoryProvider)),
);
final restoreFromDriveProvider = Provider(
  (ref) => RestoreFromDrive(ref.read(backupSyncRepositoryProvider)),
);
final exportDataProvider = Provider(
  (ref) => ExportData(ref.read(backupSyncRepositoryProvider)),
);

// ── State Representation ─────────────────────────────────────────────────────
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
      // ✅ FIX 1: Allow account to be explicitly set to null instead of falling back to old state
      account: account,
      lastSync: lastSync ?? this.lastSync,
      statusMessage: statusMessage,
    );
  }
}

// ── State Controller Provider ────────────────────────────────────────────────
final backupSyncControllerProvider =
    StateNotifierProvider.autoDispose<BackupSyncController, BackupSyncState>(
      (ref) => BackupSyncController(ref),
    );

class BackupSyncController extends StateNotifier<BackupSyncState> {
  final Ref ref;
  BackupSyncController(this.ref) : super(const BackupSyncState()) {
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    final repo = ref.read(backupSyncRepositoryProvider);
    final account = await repo.getConnectedAccount();
    final lastSync = await repo.getLastSyncTime();
    // Use an explicit new state initialization map configuration layout
    state = BackupSyncState(
      account: account,
      lastSync: lastSync,
      isLoading: false,
      statusMessage: null,
    );
  }

  Future<void> connectDrive() async {
    state = state.copyWith(isLoading: true);
    final account = await ref.read(connectGoogleDriveProvider)();

    if (account != null) {
      await ref
          .read(settingsRepositoryProvider)
          .saveSetting("googleDriveBackup", "true");

      // ✅ FIX 2: Explicitly pass the fresh account layout profile
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

    // ✅ FIX 3: Instantly clear out the account data object by initializing a clean model
    state = BackupSyncState(
      account: null, // Force null parameter definition values
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

  Future<BackupInfo?> localBackupNow() async {
    state = state.copyWith(isLoading: true);
    try {
      final info = await ref.read(createLocalBackupProvider)();
      state = state.copyWith(
        isLoading: false,
        statusMessage: 'Local backup saved',
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

  Future<String?> exportNow() async {
    state = state.copyWith(isLoading: true);
    try {
      final path = await ref.read(exportDataProvider)();
      state = state.copyWith(
        isLoading: false,
        statusMessage: 'Exported to $path',
      );
      return path;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        statusMessage: 'Export failed: $e',
      );
      return null;
    }
  }

  Future<int?> importCsvNow() async {
    state = state.copyWith(isLoading: true);
    try {
      // 1. Fire up a picker interface targeting plain data files matching CSV format specifications
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        // 2. Read file contents and decode it as standardized text rows
        final csvContent = await file.readAsString();
        final List<List<dynamic>> parsedRows = CsvToListConverter().convert(
          csvContent,
        );

        // 3. Delegate row collection array down into our SQLite transaction processor
        final count = await DBHelper.importProductsFromCsv(parsedRows);

        state = state.copyWith(
          isLoading: false,
          statusMessage: 'Successfully imported $count products',
        );
        return count;
      }

      state = state.copyWith(isLoading: false);
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        statusMessage: 'Import mapping failed: $e',
      );
      return null;
    }
  }
}
