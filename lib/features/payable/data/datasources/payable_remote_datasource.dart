import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_config.dart';
import '../models/payable_supplier_model.dart';
import '../models/supplier_detail_model.dart';

abstract class PayableRemoteDataSource {
  Future<List<PayableSupplierModel>> getPayableSuppliers();

  Future<SupplierDetailModel> getSupplierDetail(
    String supplierId, {
    String period = 'all',
  });
}

/// Hits the exact same `reports.php` actions the Reports feature already
/// uses (`action=purchases&view=suppliers` and `action=supplier_detail`),
/// so this feature reads the real, live data from the same backend —
/// nothing here is hard-coded.
class PayableRemoteDataSourceImpl implements PayableRemoteDataSource {
  final Dio client;

  PayableRemoteDataSourceImpl({required this.client});

  Future<dynamic> _get(String action, [Map<String, dynamic>? extra]) async {
    try {
      final queryParams = {'action': action, ...?extra};

      debugPrint(
        '🌐 [Payable] REQUESTING URL: ${ApiConfig.reports} with params: $queryParams',
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
          debugPrint('❌ [Payable] API Error Message: ${responseData['message']}');
        }
      }
    } catch (e) {
      debugPrint('❌ [Payable] Remote DataSource exception [$action]: $e');
    }
    return null;
  }

  @override
  Future<List<PayableSupplierModel>> getPayableSuppliers() async {
    final data = await _get('purchases', {
      'period': 'all',
      'view': 'suppliers',
      'limit': 100,
    });
    if (data is Map<String, dynamic> && data['suppliers'] is List) {
      return (data['suppliers'] as List)
          .map((e) => PayableSupplierModel.fromJson(e))
          .toList();
    }
    return [];
  }

  @override
  Future<SupplierDetailModel> getSupplierDetail(
    String supplierId, {
    String period = 'all',
  }) async {
    final data = await _get('supplier_detail', {
      'id': supplierId,
      'period': 'all',
    });

    return SupplierDetailModel.fromJson(
      data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{},
    );
  }
}
