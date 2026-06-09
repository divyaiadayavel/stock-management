import 'business_profile.dart';

class SettingsBundle {
  const SettingsBundle({
    required this.profile,
    required this.settings,
  });

  final BusinessProfile profile;
  final Map<String, String> settings;

  // Staff is no longer bundled — fetched separately via getStaffUsers()

  SettingsBundle copyWith({
    BusinessProfile? profile,
    Map<String, String>? settings,
  }) {
    return SettingsBundle(
      profile: profile ?? this.profile,
      settings: settings ?? this.settings,
    );
  }
}