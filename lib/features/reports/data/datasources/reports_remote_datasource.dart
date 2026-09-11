import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_config.dart';
import '../models/payable_supplier_model.dart';
import '../models/receivable_customer_model.dart';
import '../models/report_bill_model.dart';
import '../models/report_extras_model.dart';

abstract class ReportsRemoteDataSource {
  Future<Map<String, double>> getDashboardMetrics();
  Future<List<Map<String, dynamic>>> getChartPoints(
    String filter, {
    String? from,
    String? to,
  });
  Future<List<PayableSupplierModel>> getPayableSuppliers();
  Future<List<ReceivableCustomerModel>> getReceivableCustomers();
  Future<List<ReportBillModel>> getReportBills(
    DateTime startDate,
    DateTime endDate,
  );
  Future<void> reprintBill(String billId);

  Future<ReportOverviewSummaryModel> getReportsOverview({
    String range = 'this_month',
  });
  Future<List<ReportBillModel>> getSalesReports({
    String filter = 'ALL',
    String query = '',
    String period = 'this_month',
    int page = 1,
    int limit = 100,
  });
  Future<InvoiceDetailModel> getInvoiceDetail(String invoiceId);
  Future<List<ProductPerformanceModel>> getProductPerformance({
    String segment = 'fast_selling',
    String period = 'this_month',
    int page = 1,
    int limit = 100,
  });
  Future<List<SupplierSummaryModel>> getSupplierSummaries({
    String period = 'this_month',
    int page = 1,
    int limit = 100,
  });
  Future<SupplierDetailModel> getSupplierDetail(
    String supplierId, {
    String period = 'this_month',
  });
  Future<CustomerDetailModel> getCustomerDetail(
    String customerId, {
    String period = 'this_month',
  });
  Future<PurchaseOrderDetailModel> getPurchaseOrderDetail(String purchaseId);
  Future<List<PurchaseOrderSummaryModel>> getPurchaseOrdersReport({
    String period = 'this_month',
    String search = '',
    int page = 1,
    int limit = 100,
  });
  Future<List<ServiceJobSummaryModel>> getServiceJobs({
    String category = 'all',
    String period = 'this_month',
    int page = 1,
    int limit = 100,
  });
  Future<ServiceJobDetailModel> getServiceJobDetail(String jobId);
  Future<ProfitabilityReportModel> getProfitabilityReport({
    String range = 'this_month',
    String view = 'overview',
  });
  Future<InventoryStockSummaryModel> getInventoryStockSummary({
    String range = 'this_month',
  });
  Future<List<StockMovementModel>> getStockMovements({
    String range = 'this_month',
    int page = 1,
    int limit = 100,
  });
  Future<List<ReceivedOrderRowModel>> getReceivedOrders({
    String range = 'this_month',
    int page = 1,
    int limit = 100,
  });
  Future<List<PendingOrderRowModel>> getPendingOrders({
    String range = 'this_month',
    int page = 1,
    int limit = 100,
  });
  Future<List<LowStockAlertRowModel>> getLowStockAlerts({
    int page = 1,
    int limit = 100,
  });
}

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  final Dio client;

  ReportsRemoteDataSourceImpl({required this.client});

  String _mapPeriod(String period) {
    final clean = period.trim().toLowerCase();
    switch (clean) {
      case 'days':
      case 'day':
      case 'today':
        return 'today';
      case 'weeks':
      case 'week':
      case 'this_week':
        return 'this_week';
      case 'months':
      case 'month':
      case 'this_month':
        return 'this_month';
      case 'years':
      case 'year':
      case 'this_year':
        return 'this_year';
      case 'all':
        return 'all';
      default:
        return 'this_month';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Range selectors across the Reports feature (Overview, Inventory & Stock
  /// Report, etc.) support Today | This Week | This Month | This Year |
  /// Custom Date Range. Custom ranges are encoded by the screen as
  /// 'custom:YYYY-MM-DD:YYYY-MM-DD' so the existing `String range` family
  /// providers don't need their signature changed. This decodes that into
  /// the `period` / `from` / `to` query params the backend already expects.
  Map<String, dynamic> _periodParams(String range) {
    if (range.startsWith('custom:')) {
      final parts = range.split(':');
      if (parts.length == 3 && parts[1].isNotEmpty && parts[2].isNotEmpty) {
        return {'period': 'custom', 'from': parts[1], 'to': parts[2]};
      }
    }
    return {'period': _mapPeriod(range)};
  }

  Future<dynamic> _get(String action, [Map<String, dynamic>? extra]) async {
    try {
      final queryParams = {'action': action, ...?extra};

      // DEBUG: Print full URL and parameters being requested
      debugPrint(
        '🌐 REQUESTING URL: ${ApiConfig.reports} with params: $queryParams',
      );

      final response = await client.get(
        ApiConfig.reports,
        queryParameters: queryParams,
      );

      // DEBUG: Print raw response data from server
      debugPrint('📥 RAW RESPONSE [$action]: ${response.data}');

      dynamic responseData = response.data;
      if (responseData is String) {
        responseData = jsonDecode(responseData);
      }

      if (response.statusCode == 200 && responseData is Map<String, dynamic>) {
        if (responseData['success'] == true) {
          return responseData['data'];
        } else {
          debugPrint('❌ API Error Message: ${responseData['message']}');
        }
      }
    } catch (e) {
      debugPrint('❌ Reports Remote DataSource exception [$action]: $e');
    }
    return null;
  }

  @override
  Future<Map<String, double>> getDashboardMetrics() async {
    final data = await _get('overview');
    if (data is Map<String, dynamic>) {
      final summary = data['summary'] as Map<String, dynamic>? ?? {};
      return {
        'total_sales': (summary['sales_revenue'] as num?)?.toDouble() ?? 0.0,
        'total_purchases':
            (summary['total_purchase_value'] as num?)?.toDouble() ?? 0.0,
        'total_receivable':
            (summary['total_revenue'] as num?)?.toDouble() ?? 0.0,
        'total_payable':
            (summary['operating_expenses'] as num?)?.toDouble() ?? 0.0,
      };
    }
    return {
      'total_sales': 0.0,
      'total_purchases': 0.0,
      'total_receivable': 0.0,
      'total_payable': 0.0,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getChartPoints(
    String filter, {
    String? from,
    String? to,
  }) async {
    final params = <String, dynamic>{'period': filter};
    if (from != null && to != null) {
      params['from'] = from;
      params['to'] = to;
    }

    final data = await _get('profitability', params);
    if (data is Map<String, dynamic> && data['trend'] is List) {
      return List<Map<String, dynamic>>.from(data['trend']);
    }
    return [];
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
  Future<List<ReportBillModel>> getReportBills(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final data = await _get('sales', {
      'period': 'custom',
      'from': _formatDate(startDate),
      'to': _formatDate(endDate),
      'limit': 100,
    });
    if (data is Map<String, dynamic> && data['sales'] is List) {
      return (data['sales'] as List)
          .map((e) => ReportBillModel.fromJson(e))
          .toList();
    }
    return [];
  }

  @override
  Future<void> reprintBill(String billId) async {}

  @override
  Future<ReportOverviewSummaryModel> getReportsOverview({
    String range = 'this_month',
  }) async {
    final data = await _get('overview', _periodParams(range));
    final summary = <String, dynamic>{};
    if (data is Map<String, dynamic> && data['summary'] is Map) {
      summary.addAll(data['summary'] as Map<String, dynamic>);
    }
    return ReportOverviewSummaryModel.fromJson(summary);
  }

  @override
  Future<List<ReportBillModel>> getSalesReports({
    String filter = 'ALL',
    String query = '',
    String period = 'this_month',
    int page = 1,
    int limit = 100,
  }) async {
    // IMPORTANT: Use _periodParams instead of _mapPeriod directly.
    // A custom range such as custom:2026-09-01:2026-09-03 must reach the
    // backend as period=custom&from=2026-09-01&to=2026-09-03. Using
    // _mapPeriod previously converted every custom range back to this_month.
    final params = <String, dynamic>{
      ..._periodParams(period),
      'page': page,
      'limit': limit,
    };
    if (filter != 'all' && filter != 'ALL') {
      params['payment_status'] = filter.toUpperCase();
    }
    if (query.isNotEmpty) {
      params['search'] = query;
    }

    final data = await _get('sales', params);
    if (data is Map<String, dynamic> && data['sales'] is List) {
      return (data['sales'] as List)
          .map((e) => ReportBillModel.fromJson(e))
          .toList();
    }
    return [];
  }

  @override
  Future<InvoiceDetailModel> getInvoiceDetail(String invoiceId) async {
    final data = await _get('sale_detail', {'id': invoiceId});
    return InvoiceDetailModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  @override
  Future<List<ProductPerformanceModel>> getProductPerformance({
    String segment = 'fast_selling',
    String period = 'this_month',
    int page = 1,
    int limit = 100,
  }) async {
    final data = await _get('products', {
      'view': segment,
      ..._periodParams(period),
      'page': page,
      'limit': limit,
    });
    if (data is Map<String, dynamic> && data['products'] is List) {
      return (data['products'] as List)
          .map((e) => ProductPerformanceModel.fromJson(e))
          .toList();
    }
    return [];
  }

  @override
  Future<List<SupplierSummaryModel>> getSupplierSummaries({
    String period = 'this_month',
    int page = 1,
    int limit = 100,
  }) async {
    final data = await _get('purchases', {
      'view': 'suppliers',
      ..._periodParams(period),
      'page': page,
      'limit': limit,
    });
    if (data is Map<String, dynamic> && data['suppliers'] is List) {
      return (data['suppliers'] as List)
          .map((e) => SupplierSummaryModel.fromJson(e))
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

    debugPrint('════════ SUPPLIER DETAIL API ════════');

    debugPrint('Supplier ID: $supplierId');

    debugPrint('Response: $data');

    debugPrint('════════════════════════════════════');

    return SupplierDetailModel.fromJson(
      data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{},
    );
  }

  @override
  Future<CustomerDetailModel> getCustomerDetail(
    String customerId, {
    String period = 'all',
  }) async {
    // Same single-endpoint pattern as getSupplierDetail: a new
    // `customer_detail` case on reports.php reading the customer's row
    // plus every sale linked to their customer_id — see the summary vs
    // customer vs invoices/bills shape documented in
    // CustomerDetailModel.fromJson.
    final data = await _get('customer_detail', {
      'id': customerId,
      'period': 'all',
    });

    return CustomerDetailModel.fromJson(
      data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{},
    );
  }

  @override
  Future<PurchaseOrderDetailModel> getPurchaseOrderDetail(
    String purchaseId,
  ) async {
    final data = await _get('purchase_detail', {'id': purchaseId});
    return PurchaseOrderDetailModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  @override
  Future<List<PurchaseOrderSummaryModel>> getPurchaseOrdersReport({
    String period = 'this_month',
    String search = '',
    int page = 1,
    int limit = 100,
  }) async {
    final params = <String, dynamic>{
      'view': 'orders',
      ..._periodParams(period),
      'page': page,
      'limit': limit,
    };
    if (search.isNotEmpty) {
      params['search'] = search;
    }

    final data = await _get('purchases', params);
    if (data is Map<String, dynamic> && data['orders'] is List) {
      return (data['orders'] as List)
          .map((e) => PurchaseOrderSummaryModel.fromJson(e))
          .toList();
    }
    return [];
  }

  @override
  Future<List<ServiceJobSummaryModel>> getServiceJobs({
    String category = 'all',
    String period = 'this_month',
    int page = 1,
    int limit = 100,
  }) async {
    final params = <String, dynamic>{
      'period': _mapPeriod(period),
      'page': page,
      'limit': limit,
    };
    if (category != 'all') {
      final categoryId = int.tryParse(category);
      if (categoryId != null) {
        params['category_id'] = categoryId;
      }
    }
    final data = await _get('services', params);
    if (data is Map<String, dynamic> && data['services'] is List) {
      return (data['services'] as List)
          .map((e) => ServiceJobSummaryModel.fromJson(e))
          .toList();
    }
    return [];
  }

  @override
  Future<ServiceJobDetailModel> getServiceJobDetail(String jobId) async {
    final data = await _get('service_detail', {'id': jobId});
    return ServiceJobDetailModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  @override
  Future<ProfitabilityReportModel> getProfitabilityReport({
    String range = 'this_month',
    String view = 'overview',
  }) async {
    final data = await _get('profitability', {
      'period': _mapPeriod(range),
      'view': view,
    });
    return ProfitabilityReportModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  @override
  Future<InventoryStockSummaryModel> getInventoryStockSummary({
    String range = 'this_month',
  }) async {
    final data = await _get('inventory', {
      'view': 'movements',
      ..._periodParams(range),
    });
    return InventoryStockSummaryModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  @override
  Future<List<StockMovementModel>> getStockMovements({
    String range = 'this_month',
    int page = 1,
    int limit = 100,
  }) async {
    final data = await _get('inventory', {
      'view': 'movements',
      ..._periodParams(range),
      'page': page,
      'limit': limit,
    });
    if (data is Map<String, dynamic> && data['movements'] is List) {
      return (data['movements'] as List)
          .map((e) => StockMovementModel.fromJson(e))
          .toList();
    }
    return [];
  }

  @override
  Future<List<ReceivedOrderRowModel>> getReceivedOrders({
    String range = 'this_month',
    int page = 1,
    int limit = 100,
  }) async {
    final data = await _get('inventory', {
      'view': 'received',
      ..._periodParams(range),
      'page': page,
      'limit': limit,
    });
    if (data is Map<String, dynamic> && data['orders'] is List) {
      return (data['orders'] as List)
          .map((e) => ReceivedOrderRowModel.fromJson(e))
          .toList();
    }
    return [];
  }

  @override
  Future<List<PendingOrderRowModel>> getPendingOrders({
    String range = 'this_month',
    int page = 1,
    int limit = 100,
  }) async {
    final data = await _get('inventory', {
      'view': 'pending',
      ..._periodParams(range),
      'page': page,
      'limit': limit,
    });
    if (data is Map<String, dynamic> && data['orders'] is List) {
      return (data['orders'] as List)
          .map((e) => PendingOrderRowModel.fromJson(e))
          .toList();
    }
    return [];
  }

  @override
  Future<List<LowStockAlertRowModel>> getLowStockAlerts({
    int page = 1,
    int limit = 100,
  }) async {
    final data = await _get('inventory', {
      'view': 'low_stock',
      'page': page,
      'limit': limit,
    });
    if (data is Map<String, dynamic> && data['products'] is List) {
      return (data['products'] as List)
          .map((e) => LowStockAlertRowModel.fromJson(e))
          .toList();
    }
    return [];
  }
}
