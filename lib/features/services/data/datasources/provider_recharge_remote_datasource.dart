// lib/features/services/data/datasources/provider_recharge_remote_datasource.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import '../../../settings/service_management/data/models/service_provider_model.dart';
import '../models/provider_recharge_model.dart';

/// Reads providers from the same `providers.php` the admin feature uses,
/// and writes to `provider_recharges.php`.
class ProviderRechargeRemoteDataSource {
  final http.Client client;

  ProviderRechargeRemoteDataSource({required this.client});

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

  Future<List<ServiceProviderModel>> getProviders({int? categoryId}) async {
    try {
      final uri = Uri.parse(ApiConfig.getServiceProviders).replace(
        queryParameters: {
          if (categoryId != null) 'category_id': categoryId.toString(),
          'status': 'ACTIVE',
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
      debugPrint('Providers(user) GET Error: $e\n$st');
      rethrow;
    }
  }

  Future<ServiceProviderModel> getProviderDetail(int providerId) async {
    try {
      final uri = Uri.parse(ApiConfig.getServiceProviderDetail)
          .replace(queryParameters: {'id': providerId.toString()});

      final response = await client.get(uri, headers: ApiConfig.jsonHeaders);
      final body = _decode(response);

      final data = body['data'];

      if (data is! Map) {
        throw Exception('Invalid provider data received from server.');
      }

      return ServiceProviderModel.fromMap(Map<String, dynamic>.from(data));
    } catch (e, st) {
      debugPrint('ProviderDetail(user) GET Error: $e\n$st');
      rethrow;
    }
  }

  Future<ProviderRechargeModel> submitRecharge(
    ProviderRechargeModel recharge,
  ) async {
    try {
      final payload = recharge.toMap();

      debugPrint('━━━━━━━━ PROVIDER RECHARGE POST ━━━━━━━━');
      debugPrint('URL: ${ApiConfig.submitProviderRecharge}');
      debugPrint('BODY: ${jsonEncode(payload)}');

      final response = await client.post(
        Uri.parse(ApiConfig.submitProviderRecharge),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode(payload),
      );

      debugPrint('HTTP: ${response.statusCode}');
      debugPrint('BODY: ${response.body}');

      final body = _decode(response);
      final data = body['data'];

      if (data is! Map) {
        throw Exception('Invalid recharge response received from server.');
      }

      return ProviderRechargeModel.fromMap(Map<String, dynamic>.from(data));
    } catch (e, st) {
      debugPrint('ProviderRecharge POST Error: $e\n$st');
      rethrow;
    }
  }

  Future<List<ProviderRechargeModel>> getRecharges({int? providerId}) async {
    try {
      final uri = Uri.parse(ApiConfig.getProviderRecharges).replace(
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
            (json) => ProviderRechargeModel.fromMap(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } catch (e, st) {
      debugPrint('ProviderRecharges GET Error: $e\n$st');
      rethrow;
    }
  }

  /// Records a payment against an existing recharge's outstanding
  /// balance. Hits a NEW, standalone endpoint
  /// (`provider_recharge_payments.php`) rather than touching
  /// `provider_recharges.php`, so the existing submit/list flow is left
  /// completely untouched.
  Future<ProviderRechargeModel> addPayment({
    required int rechargeId,
    required String paymentMethod,
    required double amount,
  }) async {
    try {
      final response = await client.post(
        Uri.parse(ApiConfig.addProviderRechargePayment),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({
          'recharge_id': rechargeId,
          'payment_method': paymentMethod,
          'amount': amount,
        }),
      );

      debugPrint('Add Provider Recharge Payment Response: ${response.body}');

      final body = _decode(response);
      final data = body['data'];

      if (data is! Map) {
        throw Exception('Invalid payment response received from server.');
      }

      return ProviderRechargeModel.fromMap(Map<String, dynamic>.from(data));
    } catch (e, st) {
      debugPrint('Add Provider Recharge Payment Error: $e\n$st');
      rethrow;
    }
  }
}
