import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'audit_models.dart';

/// ===============================================================
/// Audit API Service
/// Stock Management System
/// ===============================================================

class AuditApiService {
  AuditApiService._();

  /// Replace with your audit endpoint later.
  static String auditUrl = '';

  static Future<bool> send(AuditEvent event) async {
    if (auditUrl.isEmpty) {
      if (kDebugMode) {
        debugPrint('Audit API URL not configured.');
      }
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse(auditUrl),
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(event.toJson()),
      );

      if (kDebugMode) {
        debugPrint(
          'Audit API Response: ${response.statusCode}',
        );
      }

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Audit API Error: $e');
      }
      return false;
    }
  }

  static Future<bool> sendBatch(
    List<AuditEvent> events,
  ) async {
    if (auditUrl.isEmpty) {
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse(auditUrl),
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          events.map((e) => e.toJson()).toList(),
        ),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}