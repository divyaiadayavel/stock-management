import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../models/business_profile_model.dart';
import '../models/settings_bundle_model.dart';
import '../models/staff_user_model.dart';

class SettingsRemoteDatasource {
  SettingsRemoteDatasource({http.Client? client})
      : _client = client ?? http.Client();

  static const int defaultUserId = 1;

  final http.Client _client;

  // ── Settings ────────────────────────────────────────────────────────────────

  Future<SettingsBundleModel> getSettingsBundle({
    int userId = defaultUserId,
  }) async {
    final uri = Uri.parse(ApiConfig.getSettings)
        .replace(queryParameters: {'user_id': userId.toString()});

    final response = await _client.get(uri, headers: ApiConfig.jsonHeaders);
    final json = _decodeResponse(response);
    return SettingsBundleModel.fromJson(json);
  }

  Future<BusinessProfileModel> saveProfile(
    BusinessProfileModel profile, {
    int userId = defaultUserId,
  }) async {
    final json = await _post(ApiConfig.saveSettings, {
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
    await _post(ApiConfig.saveSettings, {
      'user_id': userId,
      'settings': settings,
    });
  }

  // ── Staff ────────────────────────────────────────────────────────────────────

  Future<List<StaffUserModel>> getStaffUsers({
    int userId = defaultUserId,
  }) async {
    final uri = Uri.parse(ApiConfig.getStaff)
        .replace(queryParameters: {'user_id': userId.toString()});

    final response = await _client.get(uri, headers: ApiConfig.jsonHeaders);
    final json = _decodeResponse(response);
    final data = _readData(json);

    final list = data['staff'];
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((e) => StaffUserModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<bool> addStaffUser(
    StaffUserModel user, {
    int userId = defaultUserId,
  }) async {
    final json = await _post(ApiConfig.saveStaff, {
      'user_id': userId,
      ...user.toJson(),
    });
    return _readSuccess(json);
  }

  Future<bool> updateStaffUser(
    StaffUserModel user, {
    int userId = defaultUserId,
  }) async {
    final json = await _post(ApiConfig.saveStaff, {
      'user_id': userId,
      ...user.toJson(),
    });
    return _readSuccess(json);
  }

  Future<bool> deleteStaffUser(
    int staffUserId, {
    int userId = defaultUserId,
  }) async {
    final json = await _post(ApiConfig.deleteStaff, {
      'user_id': userId,
      'staff_id': staffUserId,
    });
    return _readSuccess(json);
  }

  Future<bool> setStaffUserStatus(
    int staffUserId,
    bool isActive, {
    int userId = defaultUserId,
  }) async {
    final json = await _post(ApiConfig.updateStatus, {
      'user_id': userId,
      'id': staffUserId,
      'isActive': isActive,
    });
    return _readSuccess(json);
  }

  // ── Internals ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _post(
    String url,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      Uri.parse(url),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw Exception('Invalid API response');

    final json = Map<String, dynamic>.from(decoded);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(json['message'] ?? 'API request failed');
    }
    if (!_readSuccess(json)) {
      throw Exception(json['message'] ?? 'API request failed');
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
}