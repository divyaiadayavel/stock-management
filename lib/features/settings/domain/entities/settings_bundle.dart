import 'business_profile.dart';
import 'staff_user.dart';

class SettingsBundle {
  const SettingsBundle({
    required this.profile,
    required this.settings,
    required this.staff,
  });

  factory SettingsBundle.empty() {
    return const SettingsBundle(
      profile: BusinessProfile(),
      settings: {},
      staff: [],
    );
  }

  final BusinessProfile profile;
  final Map<String, String> settings;
  final List<StaffUser> staff;

  SettingsBundle copyWith({
    BusinessProfile? profile,
    Map<String, String>? settings,
    List<StaffUser>? staff,
  }) {
    return SettingsBundle(
      profile: profile ?? this.profile,
      settings: settings ?? this.settings,
      staff: staff ?? this.staff,
    );
  }
}
