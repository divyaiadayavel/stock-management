import '../entities/business_profile.dart';
import '../entities/settings_bundle.dart';
import '../entities/staff_user.dart';

abstract class SettingsRepository {
  Future<SettingsBundle> getSettingsBundle();

  Future<BusinessProfile> getBusinessProfile();

  Future<BusinessProfile> saveProfile(BusinessProfile profile);

  Future<BusinessProfile> updateProfileField(String field, String value);

  Future<Map<String, String>> getSettings();

  Future<void> saveSetting(String key, String value);

  Future<void> saveSettings(Map<String, String> settings);

  Future<List<StaffUser>> getStaffUsers();

  Future<bool> addStaffUser(StaffUser user);

  Future<bool> updateStaffUser(StaffUser user);

  Future<bool> deleteStaffUser(int staffUserId);

  Future<bool> setStaffUserStatus(int staffUserId, bool isActive);
}
