import '../../domain/entities/settings_bundle.dart';
import 'business_profile_model.dart';

class SettingsBundleModel extends SettingsBundle {
  const SettingsBundleModel({
    required super.profile,
    required super.settings,
  });

  factory SettingsBundleModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return SettingsBundleModel(
      profile: BusinessProfileModel.fromJson(
        _readMap(data['profile'] ?? data['businessProfile']),
      ),
      settings: _readSettings(data['settings']),
    );
  }

  static Map<String, dynamic>? _readMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static Map<String, String> _readSettings(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), item?.toString() ?? ''),
      );
    }

    if (value is List) {
      final settings = <String, String>{};
      for (final item in value) {
        if (item is! Map) continue;
        final key = item['key'] ?? item['setting_key'];
        final settingValue = item['value'] ?? item['setting_value'];
        if (key != null) settings[key.toString()] = settingValue.toString();
      }
      return settings;
    }

    return <String, String>{};
  }
}