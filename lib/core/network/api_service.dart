import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class APIService {
  // ==========================================
  // 📦 PRODUCTS API ENDPOINTS
  // ==========================================

  static Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getProducts),
        headers: ApiConfig.jsonHeaders,
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(decoded['data'] ?? decoded);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> addProduct(Map<String, dynamic> productData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.addProduct),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode(productData),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateProduct(Map<String, dynamic> productData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.updateProduct),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode(productData),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteProduct(int id) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.deleteProduct),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({'id': id}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateStockQuantity(int id, int changeAmount) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.updateStock),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({'id': id, 'changeAmount': changeAmount}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // 🚚 SUPPLIERS API ENDPOINTS
  // ==========================================

  static Future<List<Map<String, dynamic>>> getSuppliers() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getSuppliers),
        headers: ApiConfig.jsonHeaders,
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(decoded['data'] ?? decoded);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> addSupplier(Map<String, dynamic> supplierData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.addSupplier),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode(supplierData),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteSupplier(int id) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.deleteSupplier),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({'id': id}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // 🧾 INVOICES & SALES ENDPOINTS
  // ==========================================

  static Future<int?> createInvoice({
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double tax,
    required double total,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.createInvoice),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({
          'items': items,
          'subtotal': subtotal,
          'discount': discount,
          'tax': tax,
          'total': total,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        return decoded['invoiceId'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
