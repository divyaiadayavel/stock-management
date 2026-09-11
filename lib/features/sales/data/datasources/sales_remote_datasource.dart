import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import '../models/sale_model.dart';

class SalesRemoteDataSource {
  final http.Client client;
  SalesRemoteDataSource({required this.client});

Future<int> createSaleOnServer(SaleModel sale) async {
  try {
    final response = await client.post(
      Uri.parse(ApiConfig.createSale),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode(sale.toMap()),
    );

    if (kDebugMode) {
      print('Create Sale Response: ${response.body}');
    }

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      if (body["success"] == true) {
        return int.tryParse(body["sale_id"].toString()) ?? 0;
      }

      throw Exception(body["message"] ?? "Sale creation failed");
    }

    throw Exception("Server error (${response.statusCode})");
  } catch (e) {
    debugPrint("Create Sale Exception: $e");
    rethrow;
  }
}

Future<SaleModel?> getInvoiceFromServer(int saleId) async {
  try {
    final response = await client.get(
      Uri.parse("${ApiConfig.getInvoice}?id=$saleId"),
      headers: ApiConfig.jsonHeaders,
    );

    if (kDebugMode) {
      print("Get Invoice Response: ${response.body}");
    }

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      if (body["success"] == true && body["data"] != null) {
        return SaleModel.fromMap(body["data"]);
      }

      throw Exception(body["message"] ?? "Invoice not found");
    }

    throw Exception("Server error (${response.statusCode})");
  } catch (e) {
    debugPrint("Invoice Exception: $e");
    rethrow;
  }
}
/// Record a (partial or full) payment against an existing invoice's
/// outstanding balance. Mirrors add_payment.php: returns the updated
/// payment summary (paid_amount, balance_amount, payment_status, ...)
/// on success, or throws with the server's message on failure
/// (e.g. "Payment amount cannot be greater than the current invoice
/// balance.").
Future<Map<String, dynamic>> addPaymentOnServer({
  required int saleId,
  required String paymentMethod,
  required double amount,
  String? referenceNumber,
  String? remarks,
}) async {
  try {
    final response = await client.post(
      Uri.parse(ApiConfig.addPayment),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode({
        'sale_id': saleId,
        'payment_method': paymentMethod,
        'amount': amount,
        if (referenceNumber != null && referenceNumber.isNotEmpty)
          'reference_number': referenceNumber,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      }),
    );

    if (kDebugMode) {
      print('Add Payment Response: ${response.body}');
    }

    final body = jsonDecode(response.body);

    if (body is Map && body["success"] == true) {
      return Map<String, dynamic>.from(body["data"] ?? {});
    }

    throw Exception(
      (body is Map ? body["message"]?.toString() : null) ??
          'Unable to record payment.',
    );
  } catch (e) {
    debugPrint("Add Payment Exception: $e");
    rethrow;
  }
}

Future<List<Map<String, dynamic>>> getCategoriesFromServer() async {
  try {
    final uri = Uri.parse(ApiConfig.productCategories).replace(
      queryParameters: {
        'action': 'dropdown',
      },
    );

    final response = await client.get(
      uri,
      headers: ApiConfig.jsonHeaders,
    );

    if (kDebugMode) {
      print('Get Sales Categories URL: $uri');
      print('Get Sales Categories Status: ${response.statusCode}');
      print('Get Sales Categories Response: ${response.body}');
    }

    if (response.body.trim().isEmpty) {
      throw Exception(
        'Server returned an empty category response.',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception(
        'Invalid category response received from server.',
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
            'Unable to load categories.',
      );
    }

    final rawData = body['data'];

    if (rawData is! List) {
      throw Exception(
        'Invalid category data received from server.',
      );
    }

    return rawData
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
        )
        .where(
          (category) {
            final id = int.tryParse(
              category['id']?.toString() ?? '',
            );

            final name =
                category['category_name']?.toString().trim() ?? '';

            return id != null &&
                id > 0 &&
                name.isNotEmpty;
          },
        )
        .map(
          (category) => {
            'id': int.parse(
              category['id'].toString(),
            ),
            'category_name':
                category['category_name'].toString().trim(),
          },
        )
        .toList();
  } on FormatException {
    throw Exception(
      'Invalid category response received from server.',
    );
  } catch (e, st) {
    debugPrint(
      'Sales Categories GET Error: $e\n$st',
    );
    rethrow;
  }
}
}