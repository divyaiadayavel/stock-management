import 'dart:math';

import 'package:flutter/material.dart';

import 'audit_constants.dart';

/// ===============================================================
/// Audit Utilities
/// ===============================================================

class AuditUtils {
  AuditUtils._();

  static String currentTime() {
    return DateTime.now().toIso8601String();
  }

  static String routeName(Route<dynamic>? route) {
    if (route == null) {
      return "Unknown";
    }

    return route.settings.name ??
        route.runtimeType.toString();
  }

  static String exception(dynamic error) {
    return error.toString();
  }

  static Map<String, dynamic> metadata({
    String? productId,
    String? customerId,
    String? supplierId,
    String? saleId,
    String? invoiceNo,
    String? barcode,
    String? remarks,
  }) {
    return {
      if (productId != null) "product_id": productId,
      if (customerId != null) "customer_id": customerId,
      if (supplierId != null) "supplier_id": supplierId,
      if (saleId != null) "sale_id": saleId,
      if (invoiceNo != null) "invoice_no": invoiceNo,
      if (barcode != null) "barcode": barcode,
      if (remarks != null) "remarks": remarks,
    };
  }

  /// Unique ID for a single HTTP request/response pair, so its
  /// request, response and (if any) error log lines can be matched
  /// back together, and matched to the same ID on the PHP side.
  static String generateRequestId() {
    final random = Random();
    final micros = DateTime.now().microsecondsSinceEpoch;
    final value = random.nextInt(999999);
    return 'REQ_${micros}_$value';
  }

  /// Resolves the audit module from a request path, e.g.
  ///   /catalystock/public_html/api/products/products.php  -> PRODUCTS
  ///   /catalystock/public_html/api/suppliers/suppliers.php -> SUPPLIERS
  ///
  /// This is what keeps the audit log clean when several CRUD actions
  /// (GET/POST/PUT/DELETE) all hit the *same* PHP file: the module is
  /// resolved once from the URL, while the HTTP method (carried
  /// separately as the event's `action`) tells create/update/delete/
  /// view apart.
  static String moduleFromPath(String path) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    final apiIndex = segments.indexOf('api');

    if (apiIndex == -1 || apiIndex + 1 >= segments.length) {
      return AuditConstants.api;
    }

    switch (segments[apiIndex + 1].toLowerCase()) {
      case 'auth':
        return AuditConstants.auth;
      case 'settings':
        return AuditConstants.settings;
      case 'staff':
        return AuditConstants.staff;
      case 'products':
        return AuditConstants.products;
      case 'suppliers':
        return AuditConstants.suppliers;
      case 'customers':
        return AuditConstants.customers;
      case 'sales':
        return AuditConstants.sales;
      case 'inventory':
        return AuditConstants.inventory;
      case 'purchases':
        return AuditConstants.purchases;
      case 'reports':
        return AuditConstants.reports;
      case 'dashboard':
        return AuditConstants.dashboard;
      case 'backup':
        return AuditConstants.backup;
      default:
        return AuditConstants.api;
    }
  }
}
