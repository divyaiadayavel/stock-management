import '../entities/business_profile.dart';
import '../entities/settings_bundle.dart';
import '../entities/staff_user.dart';
import '../entities/user_profile.dart';
import 'dart:io';

abstract class SettingsRepository {
  Future<SettingsBundle> getSettingsBundle();

  Future<BusinessProfile> getBusinessProfile();

  Future<BusinessProfile> saveProfile(BusinessProfile profile);

  Future<BusinessProfile> updateProfileField(String field, String value);

  Future<String> uploadBusinessLogo(File image);

  Future<Map<String, String>> getSettings();

  Future<void> saveSetting(String key, String value);

  Future<void> saveSettings(Map<String, String> settings);

  Future<List<StaffUser>> getStaffUsers();

  Future<bool> addStaffUser(StaffUser user);

  Future<bool> updateStaffUser(StaffUser user);

  Future<bool> deleteStaffUser(int staffUserId);

  Future<bool> setStaffUserStatus(int staffUserId, bool isActive);

  Future<UserProfile> getUserProfile();

  Future<UserProfile> saveUserProfile(UserProfile profile);

  Future<String> uploadProfilePicture(File image);

    // ── Product Categories ─────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCategories();

  Future<List<Map<String, dynamic>>> getAllCategories();

  Future<void> addCategory({
    required String categoryName,
    required String description,
    required int displayOrder,
  });

  Future<void> updateCategory({
    required int id,
    required String categoryName,
    required String description,
    required int displayOrder,
  });

  Future<void> deleteCategory(int id);

  Future<void> toggleCategoryStatus({
    required int id,
    required String status,
  });

  // ── Product Units ──────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getUnits();

  Future<List<Map<String, dynamic>>> getAllUnits();

  Future<void> addUnit({
    required String unitName,
    required String shortName,
    required String description,
  });

  Future<void> updateUnit({
    required int id,
    required String unitName,
    required String shortName,
    required String description,
  });

  Future<void> deleteUnit(int id);

  Future<void> toggleUnitStatus({
    required int id,
    required String status,
  });
  
  
}
