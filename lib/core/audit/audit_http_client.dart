import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'audit_constants.dart';
import 'audit_logger.dart';
import 'audit_session.dart';
import 'audit_utils.dart';

/// ===============================================================
/// Audit HTTP Client
/// Stock Management System
/// ===============================================================
///
/// Drop-in replacement for `http.Client`. Every RemoteDataSource in
/// this project already takes `http.Client client` in its
/// constructor and calls `client.get/post/put/delete(...)`, so
/// switching a datasource over to audited requests is a one-line
/// change wherever it's constructed — nothing inside the
/// RemoteDataSource itself needs to change:
///
///   Before:  ProductRemoteDataSource(client: http.Client())
///   After:   ProductRemoteDataSource(client: AuditHttpClient())
///
/// What it does for every request, automatically:
///  - Generates a request ID and attaches it as an `X-Request-ID`
///    header (also sends the current session/user headers).
///  - Resolves the audit *module* from the URL path, e.g.
///    `/api/products/products.php` -> PRODUCTS — see
///    AuditUtils.moduleFromPath. This is what keeps the log clean
///    when one PHP file handles several CRUD actions (products.php,
///    suppliers.php, customers.php, ...): the module stays constant
///    per resource, while the HTTP method (GET/POST/PUT/DELETE) is
///    recorded as the action, so each call is still told apart.
///  - Times the request and logs exactly one of:
///      logApiRequest()  when it's sent
///      logApiResponse() when a response comes back (any status code)
///      logApiError()    if it throws (timeout, no connection, etc.)
///  - Never buffers the response body — the stream is passed straight
///    through, so large downloads/exports (backups, reports) behave
///    exactly as they did with a plain http.Client.
///  - Never lets a logging failure break the real request: anything
///    thrown while logging is caught and only printed in debug mode.
///
/// Note: `http.MultipartRequest` instances created directly and sent
/// via `request.send()` (as in the current image-upload helpers)
/// bypass whatever client they were built with entirely — that's a
/// property of `BaseRequest.send()`, not something this class can see.
/// To audit those calls too, send them through the client instead,
/// e.g. `await auditClient.send(request)`, once that migration
/// happens.
class AuditHttpClient extends http.BaseClient {
  AuditHttpClient({http.Client? inner}) : _inner = inner ?? http.Client();

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final requestId = AuditUtils.generateRequestId();
    final module = AuditUtils.moduleFromPath(request.url.path);
    final endpoint = request.url.toString();
    final method = request.method;
    final requestSize = _requestSize(request);

    request.headers[AuditConstants.headerRequestId] = requestId;

    if (AuditSession.isLoggedIn) {
      request.headers[AuditConstants.headerSession] = AuditSession.sessionId;

      final userId = AuditSession.userId;
      if (userId != null) {
        request.headers[AuditConstants.headerUser] = userId.toString();
      }
    }

    _safeLog(() => AuditLogger.logApiRequest(
          requestId: requestId,
          module: module,
          endpoint: endpoint,
          method: method,
          requestSize: requestSize,
        ));

    final stopwatch = Stopwatch()..start();

    http.StreamedResponse response;
    try {
      response = await _inner.send(request);
    } catch (e) {
      stopwatch.stop();
      _safeLog(() => AuditLogger.logApiError(
            requestId: requestId,
            module: module,
            endpoint: endpoint,
            method: method,
            errorMessage: e.toString(),
            durationMs: stopwatch.elapsedMilliseconds,
            requestSize: requestSize,
          ));
      rethrow;
    }

    var responseSize = 0;
    final controller = StreamController<List<int>>();

    response.stream.listen(
      (chunk) {
        responseSize += chunk.length;
        controller.add(chunk);
      },
      onDone: () {
        stopwatch.stop();
        controller.close();
        _safeLog(() => AuditLogger.logApiResponse(
              requestId: requestId,
              module: module,
              endpoint: endpoint,
              method: method,
              statusCode: response.statusCode,
              durationMs: stopwatch.elapsedMilliseconds,
              requestSize: requestSize,
              responseSize: responseSize,
            ));
      },
      onError: (Object e, StackTrace st) {
        stopwatch.stop();
        controller.addError(e, st);
        _safeLog(() => AuditLogger.logApiError(
              requestId: requestId,
              module: module,
              endpoint: endpoint,
              method: method,
              errorMessage: e.toString(),
              durationMs: stopwatch.elapsedMilliseconds,
              requestSize: requestSize,
            ));
      },
      cancelOnError: true,
    );

    return http.StreamedResponse(
      controller.stream,
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  int? _requestSize(http.BaseRequest request) {
    if (request is http.Request) {
      return request.bodyBytes.length;
    }

    final contentLength = request.contentLength;
    return (contentLength == null || contentLength < 0)
        ? null
        : contentLength;
  }

  /// Audit logging must never take down a real API call — any
  /// failure while logging is swallowed here (and only surfaced in
  /// debug mode).
  void _safeLog(void Function() action) {
    try {
      action();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuditHttpClient logging error: $e');
      }
    }
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
