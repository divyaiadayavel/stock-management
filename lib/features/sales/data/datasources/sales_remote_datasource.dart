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
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body["success"] == true) {
          return int.tryParse(body["sale_id"].toString()) ?? 0;
        } else {
          if (kDebugMode) print('Server error: ${body["message"]}');
        }
      }
    } catch (e) {
      debugPrint("Create Sale Exception : $e");
    }
    return 0;
  }

  Future<SaleModel?> getInvoiceFromServer(int saleId) async {
    try {
      final response = await client.get(
        Uri.parse("${ApiConfig.getInvoice}?id=$saleId"),
        headers: ApiConfig.jsonHeaders,
      );

      if (kDebugMode) {
        print('Get Invoice Response: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body["success"] == true && body["data"] != null) {
          return SaleModel.fromMap(body["data"]);
        }
      }
    } catch (e) {
      debugPrint("Invoice Exception : $e");
    }
    return null;
  }
}