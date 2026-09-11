// lib/features/settings/service_management/data/datasources/service_management_remote_datasource.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../../core/network/api_config.dart';
import '../models/service_category_model.dart';
import '../models/service_model.dart';

/// Talks to `api/services/categories.php` and `api/services/services.php`.
///
/// Expected PHP contract (mirrors the `products`/`customers` endpoints
/// already in this app — see ApiConfig for the exact URLs):
///
/// GET  categories.php                 -> {success, data:[{id,name,services_count}]}
/// POST categories.php {name}          -> {success, id}
/// DELETE categories.php?id=           -> {success}
///
/// GET  services.php?category_id=      -> {success, data:[{...service, questions:[...]}]}
/// GET  services.php?id=               -> {success, data:{...service, questions:[...]}}
/// POST services.php {service+questions[]} -> {success, id}
/// PUT  services.php {id, service+questions[]} -> {success}
/// DELETE services.php?id=             -> {success}
class ServiceManagementRemoteDataSource {
  final http.Client client;

  ServiceManagementRemoteDataSource({required this.client});

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.trim().isEmpty) {
      throw Exception('Server returned an empty response.');
    }
    final decoded = jsonDecode(response.body);
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

  // ── CATEGORIES ───────────────────────────────────────────

  Future<List<ServiceCategoryModel>> getCategories() async {
    try {
      final response = await client.get(
        Uri.parse(ApiConfig.getServiceCategories),
        headers: ApiConfig.jsonHeaders,
      );
      final body = _decode(response);
      if (body['success'] != true) {
        throw Exception(body['message']?.toString() ?? 'Unable to load categories.');
      }
      final rawData = body['data'];
      if (rawData is! List) return [];
      return rawData
          .map((json) => ServiceCategoryModel.fromMap(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e, st) {
      debugPrint('ServiceCategory GET Error: $e\n$st');
      rethrow;
    }
  }

Future<int> createCategory(String name) async {
  try {
    final response = await client.post(
      Uri.parse(ApiConfig.saveServiceCategory),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode({'name': name.trim()}),
    );
    final body = _decode(response);
    if (body['success'] != true) {
      throw Exception(body['message']?.toString() ?? 'Unable to add category.');
    }
    final data = body['data'];
    final rawId = data is Map ? data['id'] : body['id'];
    return int.tryParse(rawId?.toString() ?? '') ?? 0;
  } catch (e, st) {
    debugPrint('ServiceCategory POST Error: $e\n$st');
    rethrow;
  }
}

  Future<bool> deleteCategory(int id) async {
    try {
      final response = await client.delete(
        Uri.parse('${ApiConfig.deleteServiceCategory}?id=$id'),
        headers: ApiConfig.jsonHeaders,
      );
      final data = _decode(response);
      return data['success'] == true;
    } catch (e, st) {
      debugPrint('ServiceCategory DELETE Error: $e\n$st');
      rethrow;
    }
  }

  // ── SERVICES ─────────────────────────────────────────────

  Future<List<ServiceModel>> getServices({int? categoryId}) async {
    try {
      final uri = Uri.parse(ApiConfig.getServices).replace(
        queryParameters: {
          if (categoryId != null) 'category_id': categoryId.toString(),
        },
      );
      final response = await client.get(uri, headers: ApiConfig.jsonHeaders);
      final body = _decode(response);
      if (body['success'] != true) {
        throw Exception(body['message']?.toString() ?? 'Unable to load services.');
      }
      final rawData = body['data'];
      if (rawData is! List) return [];
      return rawData
          .map((json) => ServiceModel.fromMap(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e, st) {
      debugPrint('Service GET Error: $e\n$st');
      rethrow;
    }
  }

  Future<ServiceModel> getServiceDetail(int id) async {
    try {
      final uri = Uri.parse(ApiConfig.getServiceDetail).replace(
        queryParameters: {'id': id.toString()},
      );
      final response = await client.get(uri, headers: ApiConfig.jsonHeaders);
      final body = _decode(response);
      if (body['success'] != true) {
        throw Exception(body['message']?.toString() ?? 'Unable to load service.');
      }
      final data = body['data'];
      if (data is! Map) throw Exception('Invalid service data received from server.');
      return ServiceModel.fromMap(Map<String, dynamic>.from(data));
    } catch (e, st) {
      debugPrint('ServiceDetail GET Error: $e\n$st');
      rethrow;
    }
  }

Future<int> createService(ServiceModel service) async {
  try {
    final response = await client.post(
      Uri.parse(ApiConfig.saveService),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode(service.toMap()),
    );
    final body = _decode(response);
    if (body['success'] != true) {
      throw Exception(body['message']?.toString() ?? 'Unable to save service.');
    }
    final data = body['data'];
    final rawId = data is Map ? data['id'] : body['id'];
    return int.tryParse(rawId?.toString() ?? '') ?? 0;
  } catch (e, st) {
    debugPrint('Service POST Error: $e\n$st');
    rethrow;
  }
}

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
      return data['success'] == true;
    } catch (e, st) {
      debugPrint('Service PUT Error: $e\n$st');
      rethrow;
    }
  }

  Future<bool> deleteService(int id) async {
    try {
      final response = await client.delete(
        Uri.parse('${ApiConfig.deleteService}?id=$id'),
        headers: ApiConfig.jsonHeaders,
      );
      final data = _decode(response);
      return data['success'] == true;
    } catch (e, st) {
      debugPrint('Service DELETE Error: $e\n$st');
      rethrow;
    }
  }
}
