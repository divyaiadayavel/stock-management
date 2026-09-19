// lib/features/settings/service_management/data/datasources/service_management_remote_datasource.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../../core/network/api_config.dart';
import '../../domain/enums/service_category_type.dart';
import '../models/service_category_model.dart';
import '../models/service_model.dart';

/// Talks to:
/// - api/services/categories.php
/// - api/services/services.php
///
/// Expected API contract:
///
/// GET  categories.php
///      -> {success, data:[{id,name,services_count}]}
///
/// POST categories.php
///      -> {success, id}
///
/// DELETE categories.php?id=
///      -> {success, message?}
///
/// GET  services.php?category_id=
///      -> {success, data:[...]}
///
/// GET  services.php?id=
///      -> {success, data:{...}}
///
/// POST services.php
///      -> {success, id}
///
/// PUT services.php
///      -> {success}
///
/// DELETE services.php?id=
///      -> {success}
class ServiceManagementRemoteDataSource {
  final http.Client client;

  ServiceManagementRemoteDataSource({required this.client});

  // ─────────────────────────────────────────────────────────────
  // RESPONSE DECODER
  // ─────────────────────────────────────────────────────────────

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.trim().isEmpty) {
      throw Exception('Server returned an empty response.');
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (e) {
      debugPrint('JSON Decode Error: $e');
      debugPrint('Response body: ${response.body}');

      throw Exception('Invalid JSON response received from server.');
    }

    if (decoded is! Map) {
      throw Exception('Invalid response received from server.');
    }

    final body = Map<String, dynamic>.from(decoded);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        body['message']?.toString() ?? 'Server error (${response.statusCode}).',
      );
    }

    return body;
  }

  // ─────────────────────────────────────────────────────────────
  // CATEGORIES
  // ─────────────────────────────────────────────────────────────

  /// Get categories.
  ///
  /// If [type] is null, both Service and Provider categories
  /// are returned.
  Future<List<ServiceCategoryModel>> getCategories({
    ServiceCategoryType? type,
  }) async {
    try {
      final uri = Uri.parse(
        ApiConfig.getServiceCategories,
      ).replace(queryParameters: {if (type != null) 'type': type.apiValue});

      debugPrint('GET CATEGORIES: $uri');

      final response = await client.get(uri, headers: ApiConfig.jsonHeaders);

      debugPrint('GET CATEGORIES STATUS: ${response.statusCode}');

      final body = _decode(response);

      if (body['success'] != true) {
        throw Exception(
          body['message']?.toString() ?? 'Unable to load categories.',
        );
      }

      final rawData = body['data'];

      if (rawData is! List) {
        return [];
      }

      return rawData
          .map(
            (json) => ServiceCategoryModel.fromMap(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } catch (e, st) {
      debugPrint('ServiceCategory GET Error: $e\n$st');

      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CREATE CATEGORY
  // ─────────────────────────────────────────────────────────────

  Future<int> createCategory(
    String name, {
    ServiceCategoryType type = ServiceCategoryType.service,
    String? description,
  }) async {
    try {
      final payload = {
        'name': name.trim(),
        'type': type.apiValue,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      };

      debugPrint('CREATE CATEGORY PAYLOAD: $payload');

      final response = await client.post(
        Uri.parse(ApiConfig.saveServiceCategory),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode(payload),
      );

      debugPrint('CREATE CATEGORY STATUS: ${response.statusCode}');

      final body = _decode(response);

      if (body['success'] != true) {
        throw Exception(
          body['message']?.toString() ?? 'Unable to add category.',
        );
      }

      final data = body['data'];

      final rawId = data is Map ? data['id'] : body['id'];

      return int.tryParse(rawId?.toString() ?? '') ?? 0;
    } catch (e, st) {
      debugPrint('ServiceCategory POST Error: $e\n$st');

      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE CATEGORY
  // ─────────────────────────────────────────────────────────────

  Future<bool> deleteCategory(int id) async {
    try {
      final uri = Uri.parse(
        ApiConfig.deleteServiceCategory,
      ).replace(queryParameters: {'id': id.toString()});

      debugPrint('========================================');
      debugPrint('DELETE CATEGORY');
      debugPrint('CATEGORY ID: $id');
      debugPrint('DELETE URL: $uri');

      final response = await client.delete(uri, headers: ApiConfig.jsonHeaders);

      debugPrint(
        'DELETE CATEGORY STATUS: '
        '${response.statusCode}',
      );

      debugPrint(
        'DELETE CATEGORY RESPONSE: '
        '${response.body}',
      );

      final body = _decode(response);

      // Successful deletion.
      if (body['success'] == true) {
        debugPrint('CATEGORY $id DELETED SUCCESSFULLY');

        debugPrint('========================================');

        return true;
      }

      // IMPORTANT:
      // Do not simply return false here.
      //
      // If PHP sends:
      //
      // {
      //   "success": false,
      //   "message": "Category has services"
      // }
      //
      // we want to expose that real message.
      final message = body['message']?.toString();

      debugPrint(
        'CATEGORY DELETE FAILED: '
        '${message ?? 'Unknown server error'}',
      );

      debugPrint('========================================');

      throw Exception(message ?? 'Server refused to delete category.');
    } catch (e, st) {
      debugPrint('ServiceCategory DELETE Error: $e\n$st');

      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SERVICES
  // ─────────────────────────────────────────────────────────────

  Future<List<ServiceModel>> getServices({int? categoryId}) async {
    try {
      final uri = Uri.parse(ApiConfig.getServices).replace(
        queryParameters: {
          if (categoryId != null) 'category_id': categoryId.toString(),
        },
      );

      debugPrint('GET SERVICES: $uri');

      final response = await client.get(uri, headers: ApiConfig.jsonHeaders);

      final body = _decode(response);

      if (body['success'] != true) {
        throw Exception(
          body['message']?.toString() ?? 'Unable to load services.',
        );
      }

      final rawData = body['data'];

      if (rawData is! List) {
        return [];
      }

      return rawData
          .map(
            (json) =>
                ServiceModel.fromMap(Map<String, dynamic>.from(json as Map)),
          )
          .toList();
    } catch (e, st) {
      debugPrint('Service GET Error: $e\n$st');

      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SERVICE DETAIL
  // ─────────────────────────────────────────────────────────────

  Future<ServiceModel> getServiceDetail(int id) async {
    try {
      final uri = Uri.parse(
        ApiConfig.getServiceDetail,
      ).replace(queryParameters: {'id': id.toString()});

      final response = await client.get(uri, headers: ApiConfig.jsonHeaders);

      final body = _decode(response);

      if (body['success'] != true) {
        throw Exception(
          body['message']?.toString() ?? 'Unable to load service.',
        );
      }

      final data = body['data'];

      if (data is! Map) {
        throw Exception('Invalid service data received from server.');
      }

      return ServiceModel.fromMap(Map<String, dynamic>.from(data));
    } catch (e, st) {
      debugPrint('ServiceDetail GET Error: $e\n$st');

      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CREATE SERVICE
  // ─────────────────────────────────────────────────────────────

  Future<int> createService(ServiceModel service) async {
    try {
      final payload = service.toMap();

      debugPrint('CREATE SERVICE PAYLOAD: $payload');

      final response = await client.post(
        Uri.parse(ApiConfig.saveService),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode(payload),
      );

      final body = _decode(response);

      if (body['success'] != true) {
        throw Exception(
          body['message']?.toString() ?? 'Unable to save service.',
        );
      }

      final data = body['data'];

      final rawId = data is Map ? data['id'] : body['id'];

      return int.tryParse(rawId?.toString() ?? '') ?? 0;
    } catch (e, st) {
      debugPrint('Service POST Error: $e\n$st');

      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE SERVICE
  // ─────────────────────────────────────────────────────────────

  Future<bool> updateService(ServiceModel service) async {
    try {
      final payload = service.toMap();

      payload['id'] = service.id;

      final response = await client.put(
        Uri.parse(ApiConfig.saveService),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode(payload),
      );

      final data = _decode(response);

      if (data['success'] == true) {
        return true;
      }

      throw Exception(
        data['message']?.toString() ?? 'Unable to update service.',
      );
    } catch (e, st) {
      debugPrint('Service PUT Error: $e\n$st');

      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE SERVICE
  // ─────────────────────────────────────────────────────────────

  Future<bool> deleteService(int id) async {
    try {
      final uri = Uri.parse(
        ApiConfig.deleteService,
      ).replace(queryParameters: {'id': id.toString()});

      debugPrint('DELETE SERVICE: $uri');

      final response = await client.delete(uri, headers: ApiConfig.jsonHeaders);

      final data = _decode(response);

      if (data['success'] == true) {
        return true;
      }

      throw Exception(
        data['message']?.toString() ?? 'Unable to delete service.',
      );
    } catch (e, st) {
      debugPrint('Service DELETE Error: $e\n$st');

      rethrow;
    }
  }
}
