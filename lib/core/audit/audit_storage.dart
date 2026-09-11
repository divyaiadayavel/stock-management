import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'audit_constants.dart';
import 'audit_models.dart';

/// ===============================================================
/// Audit Storage
/// Stock Management System
/// ===============================================================
///
/// Every audit event is written to two places on disk, under the
/// app's *documents* directory (never under `lib/` — that folder is
/// compiled into the app bundle and is not writable at runtime on
/// Android/iOS):
///
///   <AppDocuments>/audit_logs/audit_YYYYMMDD.log
///     Permanent, append-only, human-readable text log (JSON per
///     line). Nothing is ever removed from these files — this is
///     the actual audit trail.
///
///   <AppDocuments>/audit_logs/pending_sync.queue
///     Small bookkeeping file mirroring only the events not yet
///     confirmed uploaded to the PHP backend. Rewritten (not
///     appended) whenever entries are confirmed sent, so app
///     restarts don't re-upload old, already-synced history.
///
/// An in-memory list mirrors the pending queue for fast access from
/// AuditLogger without hitting disk on every call.
class AuditStorage {
  AuditStorage._();

  static final List<AuditEvent> _pending = [];

  static bool _initialized = false;

  static Directory? _logDirectory;

  // Serializes all disk writes so concurrent log calls can't
  // interleave and corrupt a file.
  static Future<void> _writeLock = Future.value();

  static bool get isInitialized => _initialized;

  /// Loads any events left over from a previous session that were
  /// never confirmed uploaded. Call once during app startup, before
  /// relying on [getAll]/[count].
  static Future<void> init() async {
    if (_initialized) return;

    try {
      _logDirectory = await _resolveLogDirectory();
      await _loadPendingQueue();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuditStorage init error: $e');
      }
    } finally {
      _initialized = true;
    }
  }

  static Future<Directory> _resolveLogDirectory() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final dir = Directory(
      '${baseDir.path}/${AuditConstants.logDirectoryName}',
    );

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return dir;
  }

  static File _dailyLogFile(DateTime date) {
    final stamp =
        '${date.year}${_pad(date.month)}${_pad(date.day)}';

    return File(
      '${_logDirectory!.path}/${AuditConstants.logFilePrefix}_$stamp.${AuditConstants.logFileExtension}',
    );
  }

  static File get _pendingFile => File(
        '${_logDirectory!.path}/${AuditConstants.pendingFileName}',
      );

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static Future<void> _loadPendingQueue() async {
    final file = _pendingFile;

    if (!await file.exists()) return;

    final lines = await file.readAsLines();

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      try {
        _pending.add(AuditEvent.fromJson(jsonDecode(line)));
      } catch (e) {
        // Skip a malformed line rather than losing the whole queue.
        if (kDebugMode) {
          debugPrint('AuditStorage: skipped malformed pending line: $e');
        }
      }
    }
  }

  /// Adds one event to the pending queue and persists it: appended to
  /// today's permanent log file, and to the pending-sync file.
  static void save(AuditEvent event) {
    _pending.add(event);

    if (_pending.length > AuditConstants.maxQueueSize) {
      _pending.removeAt(0);
    }

    _persist(event);
  }

  static void saveAll(List<AuditEvent> events) {
    for (final event in events) {
      save(event);
    }
  }

  static void _persist(AuditEvent event) {
    _writeLock = _writeLock.then((_) async {
      try {
        _logDirectory ??= await _resolveLogDirectory();

        final line = '${jsonEncode(event.toJson())}\n';

        await _dailyLogFile(event.createdAt).writeAsString(
          line,
          mode: FileMode.append,
          flush: true,
        );

        await _pendingFile.writeAsString(
          line,
          mode: FileMode.append,
          flush: true,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('AuditStorage write error: $e');
        }
      }
    });
  }

  static List<AuditEvent> getAll() => List.unmodifiable(_pending);

  static int count() => _pending.length;

  static bool isEmpty() => _pending.isEmpty;

  static void removeFirst() {
    if (_pending.isNotEmpty) {
      _pending.removeAt(0);
    }
    _rewritePendingFile();
  }

  /// Drops a batch of events from the pending queue once
  /// [AuditApiService] has confirmed they were uploaded successfully.
  /// The permanent daily log files are untouched — only the small
  /// sync-tracking file is rewritten.
  static void removeSent(List<AuditEvent> sent) {
    _pending.removeWhere(sent.contains);
    _rewritePendingFile();
  }

  static void clear() {
    _pending.clear();
    _rewritePendingFile();
  }

  static void _rewritePendingFile() {
    _writeLock = _writeLock.then((_) async {
      try {
        _logDirectory ??= await _resolveLogDirectory();

        final buffer =
            _pending.map((e) => jsonEncode(e.toJson())).join('\n');

        await _pendingFile.writeAsString(
          _pending.isEmpty ? '' : '$buffer\n',
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('AuditStorage rewrite error: $e');
        }
      }
    });
  }
}
