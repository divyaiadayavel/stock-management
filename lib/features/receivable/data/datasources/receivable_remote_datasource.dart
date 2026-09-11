import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_config.dart';
import '../models/customer_detail_model.dart';
import '../models/receivable_customer_model.dart';

abstract class ReceivableRemoteDataSource {
  Future<List<ReceivableCustomerModel>> getReceivableCustomers();

  Future<CustomerDetailModel> getCustomerDetail(
    String customerId, {
    String period = 'all',
  });
}

/// Hits the exact same `reports.php` actions the Reports feature already
/// uses (`action=receivables` and `action=customer_detail`), so this
/// feature reads the real, live data from the same backend — nothing
/// here is hard-coded.
class ReceivableRemoteDataSourceImpl implements ReceivableRemoteDataSource {
  final Dio client;

  ReceivableRemoteDataSourceImpl({required this.client});

  Future<dynamic> _get(String action, [Map<String, dynamic>? extra]) async {
    try {
      final queryParams = {'action': action, ...?extra};

      debugPrint(
        '🌐 [Receivable] REQUESTING URL: ${ApiConfig.reports} with params: $queryParams',
      );

      final response = await client.get(
        ApiConfig.reports,
        queryParameters: queryParams,
      );

      dynamic responseData = response.data;
      if (responseData is String) {
        responseData = jsonDecode(responseData);
      }

      if (response.statusCode == 200 && responseData is Map<String, dynamic>) {
        if (responseData['success'] == true) {
          return responseData['data'];
        } else {
          debugPrint('❌ [Receivable] API Error Message: ${responseData['message']}');
        }
      }
    } catch (e) {
      debugPrint('❌ [Receivable] Remote DataSource exception [$action]: $e');
    }
    return null;
  }

  @override
  Future<List<ReceivableCustomerModel>> getReceivableCustomers() async {
    final data = await _get('receivables');
    if (data is Map<String, dynamic> && data['receivables'] is List) {
      return (data['receivables'] as List)
          .map((e) => ReceivableCustomerModel.fromJson(e))
          .toList();
    }
    return [];
  }

  @override
  Future<CustomerDetailModel> getCustomerDetail(
    String customerId, {
    String period = 'all',
  }) async {
    final data = await _get('customer_detail', {
      'id': customerId,
      'period': 'all',
    });

    return CustomerDetailModel.fromJson(
      data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{},
    );
  }
}
