import 'dart:convert';
import 'package:flutter/foundation.dart'; // Required for debugPrint
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import '../models/customer_model.dart';

class CustomerRemoteDataSource {
  final http.Client client;

  CustomerRemoteDataSource({required this.client});

  // Fetch verified customer array matrix records
Future<List<CustomerModel>> getCustomersFromServer({
  String search = "",
}) async {
  try {
    final endpointUri = search.isNotEmpty
        ? '${ApiConfig.getCustomers}?search=${Uri.encodeComponent(search)}'
        : ApiConfig.getCustomers;

    final response = await client.get(
      Uri.parse(endpointUri),
      headers: ApiConfig.jsonHeaders,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);

      if (body['success'] == true && body['data'] != null) {
        final List rawDataList = body['data'];

        return rawDataList
            .map((jsonRow) => CustomerModel.fromMap(jsonRow))
            .toList();
      }
    }

    throw Exception(
      "Failed to load customers. Server returned ${response.statusCode}",
    );
  } catch (errorTrace) {
    debugPrint("Customer Remote DataSource GET Exception: $errorTrace");
    rethrow;
  }
}

  // Push fresh database insertion targets
  Future<int> addCustomerToServer(CustomerModel customer) async {
    try {
      final response = await client.post(
        Uri.parse(ApiConfig.addCustomer),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode(customer.toMap()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return int.tryParse(responseData['id']?.toString() ?? '0') ?? 0;
      }
    } catch (errorTrace) {
      debugPrint("Customer Remote DataSource POST Exception: $errorTrace");
    }
    return 0;
  }

  // Update specified parameters upstream
  Future<bool> updateCustomerOnServer(CustomerModel customer) async {
    try {
      final response = await client.put(
        Uri.parse(ApiConfig.updateCustomer),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode(customer.toMap()),
      );
      return response.statusCode == 200;
    } catch (errorTrace) {
      debugPrint("Customer Remote DataSource PUT Exception: $errorTrace");
    }
    return false;
  }

  // Soft-delete indices matching targets
  Future<bool> deleteCustomerFromServer(int targetId) async {
    try {
      final response = await client.delete(
        Uri.parse("${ApiConfig.deleteCustomer}?id=$targetId"),
        headers: ApiConfig.jsonHeaders,
      );
      return response.statusCode == 200;
    } catch (errorTrace) {
      debugPrint("Customer Remote DataSource DELETE Exception: $errorTrace");
    }
    return false;
  }
}