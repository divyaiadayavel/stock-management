import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../models/supplier_model.dart';

class SupplierRemoteDatasource {
  final String baseUrl;
  final http.Client client;

  SupplierRemoteDatasource({
    required this.baseUrl,
    required this.client,
  });

  // ============================================================
  // RESPONSE HELPERS
  // ============================================================

  Map<String, dynamic> _decodeResponse(
    http.Response response,
  ) {
    try {
      final decoded = json.decode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception(
        'Invalid server response.',
      );
    } catch (_) {
      throw Exception(
        'Unable to process server response. Please try again.',
      );
    }
  }

  String _getServerMessage(
    Map<String, dynamic> decoded, {
    String fallback =
        'Something went wrong. Please try again.',
  }) {
    final message = decoded['message'];

    if (message == null) {
      return fallback;
    }

    final value = message.toString().trim();

    return value.isEmpty ? fallback : value;
  }

  Never _throwServerError(
    http.Response response, {
    String fallback =
        'Unable to complete the request.',
  }) {
    try {
      final decoded = json.decode(response.body);

      if (decoded is Map<String, dynamic>) {
        throw Exception(
          _getServerMessage(
            decoded,
            fallback: fallback,
          ),
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
    }

    throw Exception(fallback);
  }

  // ============================================================
  // FETCH CATEGORIES
  // ============================================================

Future<List<Map<String, dynamic>>> fetchDatabaseCategories() async {
  try {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/suppliers/suppliers.php',
    ).replace(queryParameters: {
      'action': 'categories',
    });

    final response = await client.get(
      uri,
      headers: ApiConfig.jsonHeaders,
    );

    if (response.statusCode != 200) {
      return [];
    }

    final decoded = json.decode(response.body);

    if (decoded['success'] != true) {
      return [];
    }

    final List data = decoded['data'] ?? [];

    return data
        .map<Map<String, dynamic>>(
          (item) => {
            'id':
                int.tryParse(
                      item['id']?.toString() ?? '',
                    ) ??
                    0,
            'name':
                item['category_name']?.toString() ?? '',
          },
        )
        .where(
          (item) =>
              item['id'] as int > 0 &&
              (item['name'] as String).isNotEmpty,
        )
        .toList();
  } catch (_) {
    return [];
  }
}

  // ============================================================
  // FETCH SUPPLIERS
  // ============================================================

  Future<Map<String, dynamic>> fetchSuppliers({
    required int page,
    required int limit,
    String? search,
    String? status,
    String? sort,
    String? order,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.trim().isNotEmpty)
        'search': search.trim(),
      if (status != null && status.trim().isNotEmpty)
        'status': status.trim(),
      if (sort != null && sort.trim().isNotEmpty)
        'sort': sort.trim(),
      if (order != null && order.trim().isNotEmpty)
        'order': order.trim(),
    };

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/suppliers/suppliers.php',
    ).replace(
      queryParameters: queryParams,
    );

    final response = await client.get(
      uri,
      headers: ApiConfig.jsonHeaders,
    );

    if (response.statusCode != 200) {
      _throwServerError(
        response,
        fallback:
            'Unable to load suppliers. Please try again.',
      );
    }

    final decoded = _decodeResponse(response);

    if (decoded['success'] != true) {
      throw Exception(
        _getServerMessage(
          decoded,
          fallback:
              'Unable to load suppliers. Please try again.',
        ),
      );
    }

    final rawData = decoded['data'];

    final suppliers = rawData is List
        ? rawData
            .whereType<Map<String, dynamic>>()
            .map(
              SupplierModel.fromJson,
            )
            .toList()
        : <SupplierModel>[];

    final total =
        int.tryParse(
              decoded['totalRecords']?.toString() ?? '',
            ) ??
            suppliers.length;

    return {
      'data': suppliers,
      'total': total,
    };
  }

  // ============================================================
  // FETCH SINGLE SUPPLIER
  // ============================================================

  Future<SupplierModel> fetchSupplierById(
    int id,
  ) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/suppliers/suppliers.php',
    ).replace(
      queryParameters: {
        'id': id.toString(),
      },
    );

    final response = await client.get(
      uri,
      headers: ApiConfig.jsonHeaders,
    );

    if (response.statusCode != 200) {
      _throwServerError(
        response,
        fallback:
            'Unable to load supplier profile.',
      );
    }

    final decoded = _decodeResponse(response);

    if (
      decoded['success'] == true &&
      decoded['data'] != null
    ) {
      return SupplierModel.fromJson(
        Map<String, dynamic>.from(
          decoded['data'],
        ),
      );
    }

    throw Exception(
      _getServerMessage(
        decoded,
        fallback:
            'Supplier profile not found.',
      ),
    );
  }

  // ============================================================
  // ADD SUPPLIER
  // ============================================================

  Future<int> addSupplier(
    SupplierModel model,
  ) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/suppliers/suppliers.php',
    );

    final response = await client.post(
      uri,
      headers: ApiConfig.jsonHeaders,
      body: json.encode(
        model.toJson(),
      ),
    );

    if (
      response.statusCode != 200 &&
      response.statusCode != 201
    ) {
      _throwServerError(
        response,
        fallback:
            'Unable to create supplier. Please try again.',
      );
    }

    final decoded = _decodeResponse(response);

    if (decoded['success'] != true) {
      throw Exception(
        _getServerMessage(
          decoded,
          fallback:
              'Unable to create supplier.',
        ),
      );
    }

    // ==========================================================
    // IMPORTANT:
    //
    // suppliers.php currently returns:
    //
    // {
    //   "success": true,
    //   "message": "...",
    //   "id": 25
    // }
    //
    // Therefore read decoded['id'] first.
    // ==========================================================

    dynamic idValue = decoded['id'];

    // Backward compatibility if API ever returns data.id.
    if (idValue == null && decoded['data'] is Map) {
      idValue = decoded['data']['id'];
    }

    final supplierId = int.tryParse(
      idValue?.toString() ?? '',
    );

    if (
      supplierId == null ||
      supplierId <= 0
    ) {
      throw Exception(
        'Supplier was created but the server did not return a valid supplier ID.',
      );
    }

    return supplierId;
  }

  // ============================================================
  // EDIT SUPPLIER
  // ============================================================

  Future<void> editSupplier(
    SupplierModel model,
  ) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/suppliers/suppliers.php',
    );

    final response = await client.put(
      uri,
      headers: ApiConfig.jsonHeaders,
      body: json.encode(
        model.toJson(),
      ),
    );

    if (response.statusCode != 200) {
      _throwServerError(
        response,
        fallback:
            'Unable to update supplier. Please try again.',
      );
    }

    final decoded = _decodeResponse(response);

    if (decoded['success'] != true) {
      throw Exception(
        _getServerMessage(
          decoded,
          fallback:
              'Unable to update supplier.',
        ),
      );
    }
  }

  // ============================================================
  // DELETE SUPPLIER
  // ============================================================

  Future<void> removeSupplier(
    int id,
  ) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/suppliers/suppliers.php',
    ).replace(
      queryParameters: {
        'id': id.toString(),
      },
    );

    final response = await client.delete(
      uri,
      headers: ApiConfig.jsonHeaders,
    );

    if (response.statusCode != 200) {
      _throwServerError(
        response,
        fallback:
            'Unable to remove supplier. Please try again.',
      );
    }

    final decoded = _decodeResponse(response);

    if (decoded['success'] != true) {
      throw Exception(
        _getServerMessage(
          decoded,
          fallback:
              'Unable to remove supplier.',
        ),
      );
    }
  }

  // ============================================================
  // UPLOAD SUPPLIER IMAGE
  // ============================================================

  Future<String> uploadImage(
    int supplierId,
    File file,
  ) async {
    if (!await file.exists()) {
      throw Exception(
        'Selected supplier image could not be found.',
      );
    }

    final fileSize = await file.length();

    if (fileSize <= 0) {
      throw Exception(
        'Selected supplier image is empty.',
      );
    }

    final uri = Uri.parse(
      '${ApiConfig.uploadSupplierImage}'
      '?supplier_id=$supplierId',
    );

    final request = http.MultipartRequest(
      'POST',
      uri,
    );

request.headers.addAll({
  'Accept': 'application/json',
});

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        file.path,
      ),
    );

    final streamedResponse =
        await request.send();

    final response =
        await http.Response.fromStream(
      streamedResponse,
    );

    if (response.statusCode != 200) {
      _throwServerError(
        response,
        fallback:
            'Supplier image upload failed.',
      );
    }

    final decoded =
        _decodeResponse(response);

    if (decoded['success'] != true) {
      throw Exception(
        _getServerMessage(
          decoded,
          fallback:
              'Supplier image upload failed.',
        ),
      );
    }

    return decoded['image_path']
            ?.toString() ??
        '';
  }
}
