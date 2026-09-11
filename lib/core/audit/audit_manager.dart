import 'dart:async';

import 'package:flutter/foundation.dart';

import 'audit_logger.dart';
import 'audit_navigation_observer.dart';
import 'audit_storage.dart';

/// ===============================================================
/// Audit Manager
/// Central controller for the audit framework.
/// ===============================================================

class AuditManager {
  AuditManager._();

  /// Shared NavigatorObserver
  static final AuditNavigationObserver navigatorObserver =
      AuditNavigationObserver();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  /// Initialize audit framework
  static Future<void> initialize() async {
    if (_initialized) return;

    // Loads anything logged while the app was previously offline so
    // it isn't lost, and so pendingLogs/flushQueue() see it right away.
    await AuditStorage.init();

    _initialized = true;

    if (kDebugMode) {
      debugPrint('');
      debugPrint('======================================');
      debugPrint(' Audit Framework Initialized');
      debugPrint('======================================');
      debugPrint('');
    }

    // Best-effort: try to sync whatever was queued offline. Never
    // blocks app startup and never throws.
    unawaited(AuditLogger.flushQueue());
  }

  /// Dispose audit framework
  static Future<void> dispose() async {
    _initialized = false;

    if (kDebugMode) {
      debugPrint('');
      debugPrint('======================================');
      debugPrint(' Audit Framework Disposed');
      debugPrint('======================================');
      debugPrint('');
    }
  }
}
