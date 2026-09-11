import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';

class NotificationRemoteDatasource {
  Future<List<dynamic>> fetchUserNotifications(int userId) async {
    final response = await http.post(
      Uri.parse(ApiConfig.getUserNotifications),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode({'user_id': userId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['notifications'] ?? [];
      }
    }
    throw Exception('Failed to fetch notifications');
  }

  Future<bool> markRead({String? notificationId, int? userId}) async {
    final Map<String, dynamic> body = {};
    if (notificationId != null) {
      body['notification_id'] = notificationId;
    } else if (userId != null) {
      body['user_id'] = userId;
    }

    final response = await http.post(
      Uri.parse(ApiConfig.markNotificationRead),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  Future<bool> triggerCheckLowStock(int userId) async {
    final response = await http.post(
      Uri.parse(ApiConfig.checkLowStock),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode({'user_id': userId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  Future<Map<String, dynamic>> sendTestPushNotification(int userId) async {
    final response = await http.post(
      Uri.parse(ApiConfig.sendTestNotification),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode({'user_id': userId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to send test push notification');
  }
}