/// ===============================================================
/// Audit Constants
/// Stock Management System
/// ===============================================================

class AuditConstants {
  AuditConstants._();

  /// ----------------------------
  /// Application
  /// ----------------------------

  static const String appName = 'Stock Management';

  static const String appVersion = '1.0.0';

  /// ----------------------------
  /// Event Types
  /// ----------------------------

  static const String login = 'LOGIN';

  static const String logout = 'LOGOUT';

  static const String create = 'CREATE';

  static const String update = 'UPDATE';

  static const String delete = 'DELETE';

  static const String view = 'VIEW';

  static const String search = 'SEARCH';

  static const String filter = 'FILTER';

  static const String print = 'PRINT';

  static const String export = 'EXPORT';

  static const String importData = 'IMPORT';

  static const String sync = 'SYNC';

  static const String api = 'API';

  static const String navigation = 'NAVIGATION';

  static const String error = 'ERROR';

  /// ----------------------------
  /// Modules
  /// ----------------------------

  static const String auth = 'AUTH';

  static const String dashboard = 'DASHBOARD';

  static const String products = 'PRODUCTS';

  static const String customers = 'CUSTOMERS';

  static const String suppliers = 'SUPPLIERS';

  static const String inventory = 'INVENTORY';

  static const String sales = 'SALES';

  static const String reports = 'REPORTS';

  static const String settings = 'SETTINGS';

  static const String printer = 'PRINTER';

  // Added so every /api/<module>/... endpoint used by AuditHttpClient
  // (see ApiConfig) maps to a proper module instead of falling back to
  // the generic API constant.
  static const String purchases = 'PURCHASES';

  static const String staff = 'STAFF';

  static const String backup = 'BACKUP';

  /// ----------------------------
  /// Status
  /// ----------------------------

  static const String success = 'SUCCESS';

  static const String failed = 'FAILED';

  static const String pending = 'PENDING';

  /// ----------------------------
  /// Storage Keys
  /// ----------------------------

  static const String sessionKey = 'audit_session';

  static const String userKey = 'audit_user';

  static const String deviceKey = 'audit_device';

  /// ----------------------------
  /// HTTP
  /// ----------------------------

  static const String headerSession = 'X-Session-ID';

  static const String headerUser = 'X-User-ID';

  static const String headerDevice = 'X-Device-ID';

  static const String headerAppVersion = 'X-App-Version';

  // Correlates a single HTTP call across its request/response/error
  // log entries, and is forwarded to the PHP backend so server-side
  // logs can be matched back to this exact client request.
  static const String headerRequestId = 'X-Request-ID';

  /// ----------------------------
  /// Navigation
  /// ----------------------------

  static const String unknownScreen = 'Unknown Screen';

  static const String initialScreen = 'App Start';

  /// ----------------------------
  /// Local Log Storage
  /// ----------------------------

  // Folder created under the app's documents directory (NOT inside
  // lib/ — that folder is compiled into the app bundle and isn't
  // writable at runtime on Android/iOS).
  static const String logDirectoryName = 'audit_logs';

  static const String logFilePrefix = 'audit';

  static const String logFileExtension = 'log';

  // Small bookkeeping file listing only events not yet confirmed
  // uploaded to the PHP backend — separate from the permanent daily
  // .log files so retry/sync never has to touch the full audit trail.
  static const String pendingFileName = 'pending_sync.queue';

  // Safety cap on the in-memory pending queue so a long offline
  // stretch can't grow unbounded; the on-disk daily logs still keep
  // the full history regardless of this cap.
  static const int maxQueueSize = 500;
}
