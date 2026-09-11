// lib/features/services/data/datasources/services_remote_datasource.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import '../../../settings/service_management/data/models/service_category_model.dart';
import '../../../settings/service_management/data/models/service_model.dart';
import '../models/service_request_model.dart';

/// Reads from the same `categories.php` / `services.php` endpoints the
/// admin config feature uses, and writes to `service_requests.php`.
///
/// GET  services.php?category_id=&status=ACTIVE -> {success, data:[...]}
/// GET  services.php?id=                         -> {success, data:{...}}
/// POST service_requests.php {service_id, answers:[...]} ->
///      {success, data:{id, invoice_number, status, submitted_at, ...}}
/// GET  service_requests.php                     -> {success, data:[...]}
class ServicesRemoteDataSource {
  final http.Client client;

  ServicesRemoteDataSource({required this.client});

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
      'Server returned an invalid response '
      '(HTTP ${response.statusCode}).',
    );
  }

  if (decoded is! Map) {
    throw Exception(
      'Invalid response received from server '
      '(HTTP ${response.statusCode}).',
    );
  }

  final body = Map<String, dynamic>.from(decoded);

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(
      body['message']?.toString() ??
          'Server error (${response.statusCode}).',
    );
  }

  if (body['success'] != true) {
    throw Exception(
      body['message']?.toString() ??
          'Request failed (${response.statusCode}).',
    );
  }

  return body;
}

  Future<List<ServiceCategoryModel>> getCategories() async {
    try {
      final response = await client.get(
        Uri.parse(ApiConfig.getServiceCategories),
        headers: ApiConfig.jsonHeaders,
      );
      final body = _decode(response);
      if (body['success'] != true)
        throw Exception(
          body['message']?.toString() ?? 'Unable to load categories.',
        );
      final rawData = body['data'];
      if (rawData is! List) return [];
      return rawData
          .map(
            (json) => ServiceCategoryModel.fromMap(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } catch (e, st) {
      debugPrint('Services(user) categories GET Error: $e\n$st');
      rethrow;
    }
  }

  Future<List<ServiceModel>> getServicesByCategory(int categoryId) async {
    try {
      final uri = Uri.parse(ApiConfig.getServices).replace(
        queryParameters: {
          'category_id': categoryId.toString(),
          'status': 'ACTIVE',
        },
      );
      final response = await client.get(uri, headers: ApiConfig.jsonHeaders);
      final body = _decode(response);
      if (body['success'] != true)
        throw Exception(
          body['message']?.toString() ?? 'Unable to load services.',
        );
      final rawData = body['data'];
      if (rawData is! List) return [];
      return rawData
          .map(
            (json) =>
                ServiceModel.fromMap(Map<String, dynamic>.from(json as Map)),
          )
          .toList();
    } catch (e, st) {
      debugPrint('Services(user) list GET Error: $e\n$st');
      rethrow;
    }
  }

  Future<ServiceModel> getServiceDetail(int serviceId) async {
    try {
      final uri = Uri.parse(
        ApiConfig.getServiceDetail,
      ).replace(queryParameters: {'id': serviceId.toString()});
      final response = await client.get(uri, headers: ApiConfig.jsonHeaders);
      final body = _decode(response);
      if (body['success'] != true)
        throw Exception(
          body['message']?.toString() ?? 'Unable to load service.',
        );
      final data = body['data'];
      if (data is! Map)
        throw Exception('Invalid service data received from server.');
      return ServiceModel.fromMap(Map<String, dynamic>.from(data));
    } catch (e, st) {
      debugPrint('Services(user) detail GET Error: $e\n$st');
      rethrow;
    }
  }

Future<ServiceRequestModel> submitServiceRequest(
  ServiceRequestModel request,
) async {
  try {
    final requestBody = request.toMap();

    debugPrint('━━━━━━━━ SERVICE REQUEST POST ━━━━━━━━');
    debugPrint('URL: ${ApiConfig.submitServiceRequest}');
    debugPrint('BODY: ${jsonEncode(requestBody)}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final response = await client.post(
      Uri.parse(ApiConfig.submitServiceRequest),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode(requestBody),
    );

    debugPrint('SERVICE REQUEST RESPONSE');
    debugPrint('HTTP: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');

    final body = _decode(response);

    final data = body['data'];

    if (data is! Map) {
      throw Exception(
        'Invalid service request response received from server.',
      );
    }

    return ServiceRequestModel.fromMap(
      Map<String, dynamic>.from(data),
    );
  } catch (e, st) {
    debugPrint(
      'ServiceRequest POST Error: $e\n$st',
    );
    rethrow;
  }
}

  Future<List<ServiceRequestModel>> getMyServiceRequests() async {
    try {
      final response = await client.get(
        Uri.parse(ApiConfig.getServiceRequests),
        headers: ApiConfig.jsonHeaders,
      );
      final body = _decode(response);
      if (body['success'] != true)
        throw Exception(
          body['message']?.toString() ?? 'Unable to load requests.',
        );
      final rawData = body['data'];
      if (rawData is! List) return [];
      return rawData
          .map(
            (json) => ServiceRequestModel.fromMap(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } catch (e, st) {
      debugPrint('ServiceRequests GET Error: $e\n$st');
      rethrow;
    }
  }
}
