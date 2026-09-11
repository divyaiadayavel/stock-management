import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import '../models/business_profile_model.dart';
import '../models/user_profile_model.dart';
import '../models/settings_bundle_model.dart';
import '../models/staff_user_model.dart';
import '../models/backup_sync/backup_status_model.dart';
import '../models/backup_sync/backup_history_entry_model.dart';


class SettingsRemoteDatasource {
  SettingsRemoteDatasource({http.Client? client})
    : _client = client ?? http.Client();

  static const int defaultUserId = 1;
  final http.Client _client;

  // ── Settings ──────────────────────────────────────────────
  Future<SettingsBundleModel> getSettingsBundle({
    int userId = defaultUserId,
  }) async {
    final uri = Uri.parse(
      ApiConfig.getSettings,
    ).replace(queryParameters: {'user_id': userId.toString()});
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

  Future<String> uploadBusinessLogo(
  File image, {
  int userId = defaultUserId,
}) async {
  final request = http.MultipartRequest(
    'POST',
    Uri.parse(ApiConfig.uploadBusinessLogo),
  );

  request.fields['user_id'] = userId.toString();

  request.files.add(
    await http.MultipartFile.fromPath(
      'logo',
      image.path,
    ),
  );

  final response = await request.send();

  final responseBody = await response.stream.bytesToString();

  final json = jsonDecode(responseBody);

  if (response.statusCode != 200 || json["success"] != true) {
    throw Exception(json["message"] ?? "Logo upload failed");
  }

  return json["data"]["logoPath"].toString();
}

Future<UserProfileModel> getUserProfile({
  int userId = defaultUserId,
}) async {
  final uri = Uri.parse(
    ApiConfig.getUserProfile,
  ).replace(queryParameters: {
    'user_id': userId.toString(),
  });

  final response = await _client.get(
    uri,
    headers: ApiConfig.jsonHeaders,
  );

  final json = _decodeResponse(response);
  final data = _readData(json);

  return UserProfileModel.fromJson(data);
}

Future<UserProfileModel> saveUserProfile(
  UserProfileModel profile, {
  int userId = defaultUserId,
}) async {
  final json = await _post(
    ApiConfig.saveUserProfile,
    {
      'user_id': userId,
      ...profile.toJson(),
    },
  );

  final data = _readData(json);

  return UserProfileModel.fromJson(data);
}

Future<String> uploadProfilePicture(
  File image, {
  int userId = defaultUserId,
}) async {
  final request = http.MultipartRequest(
    'POST',
    Uri.parse(ApiConfig.uploadProfilePicture),
  );

  request.fields['user_id'] = userId.toString();

  request.files.add(
    await http.MultipartFile.fromPath(
      'profile_picture',
      image.path,
    ),
  );

  final response = await request.send();

  final body = await response.stream.bytesToString();

  final json = jsonDecode(body);

  if (response.statusCode != 200 || json['success'] != true) {
    throw Exception(json['message'] ?? 'Profile picture upload failed.');
  }

  return json['data']['profilePicture'];
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
  // ─────────────────────────────────────────────────────────────
// Categories
// ─────────────────────────────────────────────────────────────

Future<List<Map<String, dynamic>>> getCategories() async {
  final json = await _post(
    ApiConfig.productCategories,
    {
      "action": "dropdown",
    },
  );

  print("CATEGORY RESPONSE:");
  print(json);

  final data = json["data"] as List? ?? [];

  return data
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

Future<List<Map<String, dynamic>>> getAllCategories() async {
  final json = await _post(
    ApiConfig.productCategories,
    {
      "action": "list",
    },
  );

  final data = json["data"] as List? ?? [];

  return data
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

Future<void> addCategory({
  required String categoryName,
  required String description,
  required int displayOrder,
}) async {
  await _post(
    ApiConfig.productCategories,
    {
      "action": "add",
      "category_name": categoryName,
      "description": description,
      "display_order": displayOrder,
    },
  );
}

Future<void> updateCategory({
  required int id,
  required String categoryName,
  required String description,
  required int displayOrder,
}) async {
  await _post(
    ApiConfig.productCategories,
    {
      "action": "update",
      "id": id,
      "category_name": categoryName,
      "description": description,
      "display_order": displayOrder,
    },
  );
}

Future<void> deleteCategory(int id) async {
  await _post(
    ApiConfig.productCategories,
    {
      "action": "delete",
      "id": id,
    },
  );
}

Future<void> toggleCategoryStatus({
  required int id,
  required String status,
}) async {
  await _post(
    ApiConfig.productCategories,
    {
      "action": "toggle_status",
      "id": id,
      "status": status,
    },
  );
}

// ─────────────────────────────────────────────────────────────
// Units
// ─────────────────────────────────────────────────────────────

Future<List<Map<String, dynamic>>> getUnits() async {
  final json = await _post(
    ApiConfig.productUnits,
    {
      "action": "dropdown",
    },
  );

  final data = json["data"] as List? ?? [];

  return data
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

Future<List<Map<String, dynamic>>> getAllUnits() async {
  final json = await _post(
    ApiConfig.productUnits,
    {
      "action": "list",
    },
  );

  final data = json["data"] as List? ?? [];

  return data
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

Future<void> addUnit({
  required String unitName,
  required String shortName,
  required String description,
}) async {
  await _post(
    ApiConfig.productUnits,
    {
      "action": "add",
      "unit_name": unitName,
      "short_name": shortName,
      "description": description,
    },
  );
}

Future<void> updateUnit({
  required int id,
  required String unitName,
  required String shortName,
  required String description,
}) async {
  await _post(
    ApiConfig.productUnits,
    {
      "action": "update",
      "id": id,
      "unit_name": unitName,
      "short_name": shortName,
      "description": description,
    },
  );
}

Future<void> deleteUnit(int id) async {
  await _post(
    ApiConfig.productUnits,
    {
      "action": "delete",
      "id": id,
    },
  );
}

Future<void> toggleUnitStatus({
  required int id,
  required String status,
}) async {
  await _post(
    ApiConfig.productUnits,
    {
      "action": "toggle_status",
      "id": id,
      "status": status,
    },
  );
}

  // ── Staff ──────────────────────────────────────────────────
  Future<List<StaffUserModel>> getStaffUsers({
    int userId = defaultUserId,
  }) async {
    final uri = Uri.parse(
      ApiConfig.getStaff,
    ).replace(queryParameters: {'user_id': userId.toString()});
    final response = await _client.get(uri, headers: ApiConfig.jsonHeaders);
    final json = _decodeResponse(response);
    final data = _readData(json);
    final list = data['staff'] as List? ?? [];
    return list
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

  // ── Backup ──────────────────────────────────────────────────
  Future<BackupStatusModel> getBackupStatus({
    int userId = defaultUserId,
  }) async {
    final uri = Uri.parse(ApiConfig.backup).replace(
      queryParameters: {'action': 'status', 'user_id': userId.toString()},
    );
    final response = await _client.get(uri, headers: ApiConfig.jsonHeaders);
    final json = _decodeResponse(response);
    return BackupStatusModel.fromJson(_readData(json));
  }

  Future<Uint8List> createBackup({int userId = defaultUserId}) async {
    final uri = Uri.parse(ApiConfig.backup).replace(
      queryParameters: {'action': 'create', 'user_id': userId.toString()},
    );
    final response = await _client.post(uri, headers: ApiConfig.jsonHeaders);
    if (response.statusCode != 200) {
      throw Exception('Backup creation failed: ${response.statusCode}');
    }
    return response.bodyBytes;
  }

  Future<void> completeBackup({
    int userId = defaultUserId,
    required String driveFileId,
    required String fileName,
    int fileSize = 0,
    String status = 'success',
  }) async {
    final body = {
      'drive_file_id': driveFileId,
      'file_name': fileName,
      'file_size': fileSize,
      'status': status,
    };
    final uri = Uri.parse(ApiConfig.backup).replace(
      queryParameters: {'action': 'complete', 'user_id': userId.toString()},
    );
    final response = await _client.post(
      uri,
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode(body),
    );
    _decodeResponse(response);
  }

  Future<List<BackupHistoryEntryModel>> getBackupHistory({
    int userId = defaultUserId,
  }) async {
    final uri = Uri.parse(ApiConfig.backup).replace(
      queryParameters: {'action': 'history', 'user_id': userId.toString()},
    );
    final response = await _client.get(uri, headers: ApiConfig.jsonHeaders);
    final json = _decodeResponse(response);
    final data = _readData(json);
    final list = data['history'] as List? ?? [];
    return list
        .map(
          (e) => BackupHistoryEntryModel.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<void> restoreBackup({
    int userId = defaultUserId,
    required File backupFile,
  }) async {
    final uri = Uri.parse(ApiConfig.backup).replace(
      queryParameters: {'action': 'restore', 'user_id': userId.toString()},
    );
    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath('backup_file', backupFile.path),
    );
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    if (response.statusCode != 200 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Restore failed');
    }
  }

  Future<void> saveBackupSettings({
    int userId = defaultUserId,
    required Map<String, String> settings,
  }) async {
    final uri = Uri.parse(ApiConfig.backup);

    final response = await _client.post(
      uri,
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode({
        'action': 'saveSettings',
        'user_id': userId,
        'settings': settings,
      }),
    );

    _decodeResponse(response);
  }

  // ── Internals ──────────────────────────────────────────────
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
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw Exception('Invalid API response');
      }

      final json = Map<String, dynamic>.from(decoded);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(json['message'] ?? 'API request failed');
      }

      if (!_readSuccess(json)) {
        throw Exception(json['message'] ?? 'API request failed');
      }

      return json;
    } catch (e) {
      throw Exception('Server returned invalid response:\n${response.body}');
    }
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
