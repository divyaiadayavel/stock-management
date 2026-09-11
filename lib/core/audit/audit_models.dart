/// ===============================================================
/// Audit Event Model
/// Stock Management System
/// ===============================================================

class AuditEvent {
  final String sessionId;
  final int? userId;
  final String userName;
  final String userRole;

  final String module;
  final String event;

  final String action;

  final String screen;

  final String description;

  final String status;

  final String deviceId;

  final String appVersion;

  final String ipAddress;

  final String endpoint;

  final String method;

  final DateTime createdAt;

  final Map<String, dynamic> metadata;

  // ---------------------------------------------------------------
  // API-specific fields (optional — only populated for entries
  // raised through AuditHttpClient / AuditLogger.logApiRequest(),
  // logApiResponse() and logApiError()). Business-event entries
  // created through AuditLogger.log() / logBusiness() simply leave
  // these null.
  // ---------------------------------------------------------------

  /// Correlates the request, response and error log lines for one
  /// single HTTP call.
  final String? requestId;

  /// HTTP status code of the response, once received.
  final int? statusCode;

  /// Wall-clock time the request took, end to end, in milliseconds.
  final int? durationMs;

  /// Size of the outgoing request body in bytes, if known.
  final int? requestSize;

  /// Size of the response body in bytes, if known.
  final int? responseSize;

  const AuditEvent({
    required this.sessionId,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.module,
    required this.event,
    required this.action,
    required this.screen,
    required this.description,
    required this.status,
    required this.deviceId,
    required this.appVersion,
    required this.ipAddress,
    required this.endpoint,
    required this.method,
    required this.createdAt,
    this.metadata = const {},
    this.requestId,
    this.statusCode,
    this.durationMs,
    this.requestSize,
    this.responseSize,
  });

  Map<String, dynamic> toJson() {
    return {
      "session_id": sessionId,
      "user_id": userId,
      "user_name": userName,
      "user_role": userRole,
      "module": module,
      "event": event,
      "action": action,
      "screen": screen,
      "description": description,
      "status": status,
      "device_id": deviceId,
      "app_version": appVersion,
      "ip_address": ipAddress,
      "endpoint": endpoint,
      "method": method,
      "created_at": createdAt.toIso8601String(),
      "metadata": metadata,
      if (requestId != null) "request_id": requestId,
      if (statusCode != null) "status_code": statusCode,
      if (durationMs != null) "duration_ms": durationMs,
      if (requestSize != null) "request_size": requestSize,
      if (responseSize != null) "response_size": responseSize,
    };
  }

  factory AuditEvent.fromJson(Map<String, dynamic> json) {
    return AuditEvent(
      sessionId: json["session_id"] ?? "",
      userId: json["user_id"],
      userName: json["user_name"] ?? "",
      userRole: json["user_role"] ?? "",
      module: json["module"] ?? "",
      event: json["event"] ?? "",
      action: json["action"] ?? "",
      screen: json["screen"] ?? "",
      description: json["description"] ?? "",
      status: json["status"] ?? "",
      deviceId: json["device_id"] ?? "",
      appVersion: json["app_version"] ?? "",
      ipAddress: json["ip_address"] ?? "",
      endpoint: json["endpoint"] ?? "",
      method: json["method"] ?? "",
      createdAt: DateTime.tryParse(
            json["created_at"] ?? "",
          ) ??
          DateTime.now(),
      metadata: json["metadata"] == null
          ? {}
          : Map<String, dynamic>.from(json["metadata"]),
      requestId: json["request_id"],
      statusCode: json["status_code"] is int
          ? json["status_code"] as int
          : int.tryParse(json["status_code"]?.toString() ?? ''),
      durationMs: json["duration_ms"] is int
          ? json["duration_ms"] as int
          : int.tryParse(json["duration_ms"]?.toString() ?? ''),
      requestSize: json["request_size"] is int
          ? json["request_size"] as int
          : int.tryParse(json["request_size"]?.toString() ?? ''),
      responseSize: json["response_size"] is int
          ? json["response_size"] as int
          : int.tryParse(json["response_size"]?.toString() ?? ''),
    );
  }

  AuditEvent copyWith({
    String? sessionId,
    int? userId,
    String? userName,
    String? userRole,
    String? module,
    String? event,
    String? action,
    String? screen,
    String? description,
    String? status,
    String? deviceId,
    String? appVersion,
    String? ipAddress,
    String? endpoint,
    String? method,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
    String? requestId,
    int? statusCode,
    int? durationMs,
    int? requestSize,
    int? responseSize,
  }) {
    return AuditEvent(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      module: module ?? this.module,
      event: event ?? this.event,
      action: action ?? this.action,
      screen: screen ?? this.screen,
      description: description ?? this.description,
      status: status ?? this.status,
      deviceId: deviceId ?? this.deviceId,
      appVersion: appVersion ?? this.appVersion,
      ipAddress: ipAddress ?? this.ipAddress,
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
      requestId: requestId ?? this.requestId,
      statusCode: statusCode ?? this.statusCode,
      durationMs: durationMs ?? this.durationMs,
      requestSize: requestSize ?? this.requestSize,
      responseSize: responseSize ?? this.responseSize,
    );
  }

  @override
  String toString() {
    final base = 'AuditEvent(session=$sessionId, user=$userName, '
        'module=$module, event=$event, action=$action, status=$status';

    if (requestId == null) {
      return '$base)';
    }

    return '$base, requestId=$requestId, statusCode=$statusCode, '
        'durationMs=$durationMs)';
  }
}
