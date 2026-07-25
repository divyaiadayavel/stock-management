// lib/features/settings/data/datasources/backup_sync/google_drive_datasource.dart
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

import '../../../domain/entities/backup_sync/backup_info.dart';
import '../../../domain/entities/backup_sync/drive_account_info.dart';

class GoogleDriveDatasource {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  GoogleSignInAccount? _account;

  Future<DriveAccountInfo?> getConnectedAccount() async {
    final acc = await _googleSignIn.signInSilently();
    _account = acc;
    if (acc == null) return null;
    return DriveAccountInfo(
      email: acc.email,
      displayName: acc.displayName,
      photoUrl: acc.photoUrl,
    );
  }

  Future<DriveAccountInfo?> signIn() async {
    final acc = await _googleSignIn.signIn();
    _account = acc;
    if (acc == null) return null;
    return DriveAccountInfo(
      email: acc.email,
      displayName: acc.displayName,
      photoUrl: acc.photoUrl,
    );
  }

  Future<void> signOut() => _googleSignIn.signOut();

  Future<drive.DriveApi> _client() async {
    _account ??= await _googleSignIn.signInSilently();
    if (_account == null) {
      throw Exception('Not signed in to Google');
    }
    final authClient = await _googleSignIn.authenticatedClient();
    if (authClient == null)
      throw Exception('Could not authenticate with Google');
    return drive.DriveApi(authClient);
  }

  Future<BackupInfo> uploadBackup(File dbFile) async {
    final api = await _client();
    final fileName =
        'catalystack_backup_${DateTime.now().millisecondsSinceEpoch}.db';

    final driveFile = drive.File()..name = fileName;
    final media = drive.Media(dbFile.openRead(), await dbFile.length());
    final uploaded = await api.files.create(driveFile, uploadMedia: media);

    return BackupInfo(
      id: uploaded.id!,
      fileName: fileName,
      createdAt: DateTime.now(),
      sizeBytes: await dbFile.length(),
      location: BackupLocation.drive,
    );
  }

  Future<List<BackupInfo>> listBackups() async {
    final api = await _client();
    final result = await api.files.list(
      spaces: 'drive',
      $fields: 'files(id, name, createdTime, size)',
      orderBy: 'createdTime desc',
    );
    return (result.files ?? []).map((f) {
      return BackupInfo(
        id: f.id!,
        fileName: f.name ?? 'backup.db',
        createdAt: f.createdTime ?? DateTime.now(),
        sizeBytes: int.tryParse(f.size ?? '0') ?? 0,
        location: BackupLocation.drive,
      );
    }).toList();
  }

  Future<File> downloadBackup(String fileId, String saveToPath) async {
    final api = await _client();
    final media =
        await api.files.get(
              fileId,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;

    final file = File(saveToPath);
    final sink = file.openWrite();
    await media.stream.pipe(sink);
    await sink.close();
    return file;
  }
}
