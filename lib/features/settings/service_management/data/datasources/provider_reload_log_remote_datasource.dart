// lib/features/settings/service_management/data/datasources/provider_reload_log_remote_datasource.dart
//
// NEW FILE — additive only.
//
// Talks to `api/services/admin/providers.php?action=reload_history`.
// GET providers.php?action=reload_history[&provider_id=] -> {success, data:[...]}
// See the contract note at the bottom of provider_reload_log_model.dart.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../../core/network/api_config.dart';
import '../models/provider_reload_log_model.dart';

class ProviderReloadLogRemoteDataSource {
  final http.Client client;

  ProviderReloadLogRemoteDataSource({required this.client});

  Map<String, dynamic> _decode(http.Response response) {
    final raw = response.body.trim();

    if (raw.isEmpty) {
      throw Exception(
        'Server returned an empty response (HTTP ${response.statusCode}).',
      );
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw Exception(
        'Server returned an invalid response (HTTP ${response.statusCode}).',
      );
    }

    if (decoded is! Map) {
      throw Exception(
        'Invalid response received from server (HTTP ${response.statusCode}).',
      );
    }

    final body = Map<String, dynamic>.from(decoded);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        body['message']?.toString() ?? 'Server error (${response.statusCode}).',
      );
    }

    if (body['success'] != true) {
      throw Exception(body['message']?.toString() ?? 'Request failed.');
    }

    return body;
  }

  Future<List<ProviderReloadLogModel>> getReloadLogs({int? providerId}) async {
    try {
      final uri = Uri.parse(ApiConfig.getProviderReloadLogs).replace(
        queryParameters: {
          if (providerId != null) 'provider_id': providerId.toString(),
        },
      );

      final response = await client.get(uri, headers: ApiConfig.jsonHeaders);
      final body = _decode(response);

      final rawData = body['data'];
      if (rawData is! List) return [];

      return rawData
          .map(
            (json) => ProviderReloadLogModel.fromMap(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } catch (e, st) {
      debugPrint('ProviderReloadLogs GET Error: $e\n$st');
      rethrow;
    }
  }
}
