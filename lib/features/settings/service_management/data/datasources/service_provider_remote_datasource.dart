// lib/features/settings/service_management/data/datasources/service_provider_remote_datasource.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../../core/network/api_config.dart';
import '../models/service_provider_model.dart';

/// Talks to `api/services/admin/providers.php`.
///
/// GET    providers.php?category_id=   -> {success, data:[{...provider, questions:[]}]}
/// GET    providers.php?id=            -> {success, data:{...provider, questions:[]}}
/// POST   providers.php                -> {success, data:{...provider}}
/// PUT    providers.php                -> {success, data:{...provider}}
/// DELETE providers.php?id=            -> {success}
/// POST   providers.php?action=reload  -> {success, data:{...provider}}
class ServiceProviderRemoteDataSource {
  final http.Client client;

  ServiceProviderRemoteDataSource({required this.client});

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
      throw Exception(
        body['message']?.toString() ?? 'Request failed.',
      );
    }

    return body;
  }

  ServiceProviderModel _single(Map<String, dynamic> body) {
    final data = body['data'];

    if (data is! Map) {
      throw Exception('Invalid provider data received from server.');
    }

    return ServiceProviderModel.fromMap(Map<String, dynamic>.from(data));
  }

  Future<List<ServiceProviderModel>> getProviders({int? categoryId}) async {
    try {
      final uri = Uri.parse(ApiConfig.getServiceProviders).replace(
        queryParameters: {
          if (categoryId != null) 'category_id': categoryId.toString(),
        },
      );

      final response = await client.get(uri, headers: ApiConfig.jsonHeaders);
      final body = _decode(response);

      final rawData = body['data'];
      if (rawData is! List) return [];

      return rawData
          .map(
            (json) => ServiceProviderModel.fromMap(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } catch (e, st) {
      debugPrint('Provider GET Error: $e\n$st');
      rethrow;
    }
  }

  Future<ServiceProviderModel> getProviderDetail(int id) async {
    try {
      final uri = Uri.parse(ApiConfig.getServiceProviderDetail)
          .replace(queryParameters: {'id': id.toString()});

      final response = await client.get(uri, headers: ApiConfig.jsonHeaders);

      return _single(_decode(response));
    } catch (e, st) {
      debugPrint('ProviderDetail GET Error: $e\n$st');
      rethrow;
    }
  }

  Future<ServiceProviderModel> createProvider(
    ServiceProviderModel provider,
  ) async {
    try {
      final response = await client.post(
        Uri.parse(ApiConfig.saveServiceProvider),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode(provider.toMap(includeInitialLoad: true)),
      );

      return _single(_decode(response));
    } catch (e, st) {
      debugPrint('Provider POST Error: $e\n$st');
      rethrow;
    }
  }

  Future<ServiceProviderModel> updateProvider(
    ServiceProviderModel provider,
  ) async {
    try {
      final payload = provider.toMap();
      payload['id'] = provider.id;

      final response = await client.put(
        Uri.parse(ApiConfig.saveServiceProvider),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode(payload),
      );

      return _single(_decode(response));
    } catch (e, st) {
      debugPrint('Provider PUT Error: $e\n$st');
      rethrow;
    }
  }

  Future<bool> deleteProvider(int id) async {
    try {
      final response = await client.delete(
        Uri.parse('${ApiConfig.deleteServiceProvider}?id=$id'),
        headers: ApiConfig.jsonHeaders,
      );

      final body = _decode(response);
      return body['success'] == true;
    } catch (e, st) {
      debugPrint('Provider DELETE Error: $e\n$st');
      rethrow;
    }
  }

  Future<ServiceProviderModel> reloadBalance(
    int id,
    double amount, {
    String? note,
  }) async {
    try {
      final response = await client.post(
        Uri.parse(ApiConfig.reloadServiceProviderBalance),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({
          'id': id,
          'amount': amount.toStringAsFixed(2),
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        }),
      );

      return _single(_decode(response));
    } catch (e, st) {
      debugPrint('Provider RELOAD Error: $e\n$st');
      rethrow;
    }
  }
}
