import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'audit_api_service.dart';
import 'audit_constants.dart';
import 'audit_models.dart';
import 'audit_session.dart';
import 'audit_storage.dart';

/// ===============================================================
/// Audit Logger
/// Stock Management System
/// ===============================================================
///
/// Two kinds of entries are recorded:
///  - Business events -> log() / logBusiness()
///       user-driven actions: Save Product, Delete Product,
///       Create Sale, Print Invoice, Settings Changed, Permission
///       Denied, etc.
///  - API events -> logApiRequest() / logApiResponse() / logApiError()
///       raised automatically by AuditHttpClient for every HTTP call.
///
/// Every event is written straight to AuditStorage (in-memory queue +
/// local text log file), so nothing is lost if the PHP backend is
/// unreachable or the device is offline. Call [flushQueue] to attempt
/// uploading whatever is pending.
class AuditLogger {
  AuditLogger._();

  /// Read-only view of everything still waiting to be synced.
  static List<AuditEvent> get pendingLogs => AuditStorage.getAll();

  // ---------------------------------------------------------------
  // Business events
  // ---------------------------------------------------------------

  /// Generic business/UI event. Signature is unchanged from the
  /// original logger so existing call sites (auth_controller.dart,
  /// audit_navigation_observer.dart) keep working with no edits.
  static void log({
    required String module,
    required String event,
    required String action,
    required String description,
    String status = AuditConstants.success,
    String screen = '',
    String endpoint = '',
    String method = '',
    String ipAddress = '',
    Map<String, dynamic> metadata = const {},
  }) {
    _record(
      AuditEvent(
        sessionId: AuditSession.sessionId,
        userId: AuditSession.userId,
        userName: AuditSession.userName,
        userRole: AuditSession.userRole,
        module: module,
        event: event,
        action: action,
        screen: screen,
        description: description,
        status: status,
        deviceId: AuditSession.deviceId,
        appVersion: AuditSession.appVersion,
        ipAddress: ipAddress,
        endpoint: endpoint,
        method: method,
        createdAt: DateTime.now(),
        metadata: metadata,
      ),
    );
  }

  /// Named alias of [log] for the explicit business events (Delete
  /// Product, Save Product, Create Sale, Cancel Sale, Print Invoice,
  /// Export Report, Backup, Restore, Settings Changed, Permission
  /// Denied, ...) — kept separate from the HTTP-driven API log
  /// methods below purely for call-site clarity.
  static void logBusiness({
    required String module,
    required String event,
    required String action,
    required String description,
    String status = AuditConstants.success,
    String screen = '',
    Map<String, dynamic> metadata = const {},
  }) {
    log(
      module: module,
      event: event,
      action: action,
      description: description,
      status: status,
      screen: screen,
      metadata: metadata,
    );
  }

  // ---------------------------------------------------------------
  // API events (called by AuditHttpClient — one request produces up
  // to two calls: logApiRequest() when it's sent, then exactly one
  // of logApiResponse() or logApiError() when it finishes)
  // ---------------------------------------------------------------

  static void logApiRequest({
    required String requestId,
    required String module,
    required String endpoint,
    required String method,
    int? requestSize,
  }) {
    _record(
      AuditEvent(
        sessionId: AuditSession.sessionId,
        userId: AuditSession.userId,
        userName: AuditSession.userName,
        userRole: AuditSession.userRole,
        module: module,
        event: AuditConstants.api,
        action: method,
        screen: '',
        description: '$method $endpoint',
        status: AuditConstants.pending,
        deviceId: AuditSession.deviceId,
        appVersion: AuditSession.appVersion,
        ipAddress: '',
        endpoint: endpoint,
        method: method,
        createdAt: DateTime.now(),
        requestId: requestId,
        requestSize: requestSize,
      ),
    );
  }

  static void logApiResponse({
    required String requestId,
    required String module,
    required String endpoint,
    required String method,
    required int statusCode,
    required int durationMs,
    int? requestSize,
    int? responseSize,
  }) {
    final ok = statusCode >= 200 && statusCode < 300;

    _record(
      AuditEvent(
        sessionId: AuditSession.sessionId,
        userId: AuditSession.userId,
        userName: AuditSession.userName,
        userRole: AuditSession.userRole,
        module: module,
        event: AuditConstants.api,
        action: method,
        screen: '',
        description:
            '$method $endpoint -> $statusCode (${durationMs}ms)',
        status: ok ? AuditConstants.success : AuditConstants.failed,
        deviceId: AuditSession.deviceId,
        appVersion: AuditSession.appVersion,
        ipAddress: '',
        endpoint: endpoint,
        method: method,
        createdAt: DateTime.now(),
        requestId: requestId,
        statusCode: statusCode,
        durationMs: durationMs,
        requestSize: requestSize,
        responseSize: responseSize,
      ),
    );
  }

  static void logApiError({
    required String requestId,
    required String module,
    required String endpoint,
    required String method,
    required String errorMessage,
    int? durationMs,
    int? requestSize,
  }) {
    _record(
      AuditEvent(
        sessionId: AuditSession.sessionId,
        userId: AuditSession.userId,
        userName: AuditSession.userName,
        userRole: AuditSession.userRole,
        module: module,
        event: AuditConstants.error,
        action: method,
        screen: '',
        description: '$method $endpoint failed: $errorMessage',
        status: AuditConstants.failed,
        deviceId: AuditSession.deviceId,
        appVersion: AuditSession.appVersion,
        ipAddress: '',
        endpoint: endpoint,
        method: method,
        createdAt: DateTime.now(),
        requestId: requestId,
        durationMs: durationMs,
        requestSize: requestSize,
      ),
    );
  }

  // ---------------------------------------------------------------
  // Queue management / sync
  // ---------------------------------------------------------------

  static void clear() => AuditStorage.clear();

  static void removeFirst() => AuditStorage.removeFirst();

  static String exportJson() {
    return jsonEncode(
      AuditStorage.getAll().map((e) => e.toJson()).toList(),
    );
  }

  /// Attempts to upload every pending event to the PHP audit
  /// endpoint as one batch. On success the uploaded events are
  /// dropped from the pending queue (the permanent local .log files
  /// are left untouched either way). Safe to call anytime — e.g. on
  /// app start, after reconnecting, or on a timer — since it's a
  /// no-op when the queue is empty or the API isn't configured yet.
  static Future<void> flushQueue() async {
    if (AuditStorage.isEmpty()) return;

    final batch = AuditStorage.getAll();

    try {
      final ok = await AuditApiService.sendBatch(batch);
      if (ok) {
        AuditStorage.removeSent(batch);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuditLogger flushQueue error: $e');
      }
    }
  }

  // ---------------------------------------------------------------

  static void _record(AuditEvent event) {
    AuditStorage.save(event);
    _print(event);
  }

  static void _print(AuditEvent event) {
    if (!kDebugMode) return;

    debugPrint('');
    debugPrint('================ AUDIT LOG ================');
    debugPrint('Module      : ${event.module}');
    debugPrint('Event       : ${event.event}');
    debugPrint('Action      : ${event.action}');
    debugPrint('Description : ${event.description}');
    debugPrint('Status      : ${event.status}');
    debugPrint('User        : ${event.userName}');
    debugPrint('Session     : ${event.sessionId}');
    debugPrint('Screen      : ${event.screen}');
    debugPrint('Endpoint    : ${event.endpoint}');
    debugPrint('Method      : ${event.method}');
    if (event.requestId != null) {
      debugPrint('Request ID  : ${event.requestId}');
      debugPrint('Status Code : ${event.statusCode}');
      debugPrint('Duration    : ${event.durationMs}ms');
    }
    debugPrint('Time        : ${event.createdAt}');
    debugPrint('===========================================');
    debugPrint('');
  }
}
