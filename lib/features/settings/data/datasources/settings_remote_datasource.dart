import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/business_profile_model.dart';
import '../models/settings_bundle_model.dart';
import '../models/staff_user_model.dart';

class SettingsRemoteDatasource {
  SettingsRemoteDatasource({http.Client? client})
    : _client = client ?? http.Client();

static const String baseUrl =
'https://nonredemptive-gyrational-pauletta.ngrok-free.dev/public_html';

  static const int defaultUserId = 1;

  final http.Client _client;

  Uri _endpoint(String fileName, [Map<String, String>? query]) {
    return Uri.parse(
      '$baseUrl/settings/$fileName',
    ).replace(queryParameters: query);
  }

  Future<SettingsBundleModel> getSettingsBundle({
    int userId = defaultUserId,
  }) async {
    final response = await _client.get(
      _endpoint('get_settings.php', {'user_id': userId.toString()}),
      headers: _headers,
    );

    final json = _decodeResponse(response);
    return SettingsBundleModel.fromJson(json);
  }

  Future<BusinessProfileModel> saveProfile(
    BusinessProfileModel profile, {
    int userId = defaultUserId,
  }) async {
    final json = await _postSave({
      'user_id': userId,
      'profile': profile.toJson(),
    });

    final data = _readData(json);
    return BusinessProfileModel.fromJson(
      data['profile'] is Map
          ? Map<String, dynamic>.from(data['profile'])
          : profile.toJson(),
    );
  }

  Future<void> saveSettings(
    Map<String, String> settings, {
    int userId = defaultUserId,
  }) async {
    await _postSave({'user_id': userId, 'settings': settings});
  }

  Future<bool> addStaffUser(
    StaffUserModel user, {
    int userId = defaultUserId,
  }) async {
    final json = await _postSave({'user_id': userId, 'staff': user.toJson()});

    return _readSuccess(json);
  }

  Future<Map<String, dynamic>> _postSave(Map<String, dynamic> body) async {
    final response = await _client.post(
      _endpoint('save_settings.php'),
      headers: _headers,
      body: jsonEncode(body),
    );

    return _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw Exception('Invalid settings API response');
    }

    final json = Map<String, dynamic>.from(decoded);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(json['message'] ?? 'Settings API failed');
    }

    if (!_readSuccess(json)) {
      throw Exception(json['message'] ?? 'Settings API failed');
    }

    return json;
  }

  Map<String, dynamic> _readData(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  bool _readSuccess(Map<String, dynamic> json) {
    final value = json['success'] ?? json['status'];
    if (value is bool) return value;
    if (value is num) return value == 1;
    return value?.toString().toLowerCase() == 'true';
  }

  Map<String, String> get _headers {
    return const {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
  }
}
