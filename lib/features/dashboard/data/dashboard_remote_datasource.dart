import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/api_config.dart';

class DashboardRemoteDataSource {
  Future<Map<String, dynamic>> getDashboard() async {
    final url = ApiConfig.dashboard;

    print("==================================");
    print("Dashboard URL : $url");

    final response = await http.get(
      Uri.parse(url),
      headers: ApiConfig.jsonHeaders,
    );

    print("Status Code : ${response.statusCode}");
    print("Body : ${response.body}");
    print("==================================");

    if (response.statusCode != 200) {
      throw Exception(
        "Server Error (${response.statusCode})\n$url",
      );
    }

    final json = jsonDecode(response.body);

    if (json['success'] != true) {
      throw Exception(json['message']);
    }

    return Map<String, dynamic>.from(json['data']);
  }
}