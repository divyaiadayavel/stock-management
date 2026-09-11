import '../../domain/entities/business_profile.dart';
import '../../domain/entities/settings_bundle.dart';
import '../../domain/entities/staff_user.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_datasource.dart';
import '../models/business_profile_model.dart';
import '../models/staff_user_model.dart';
import '../models/user_profile_model.dart';
import '../../domain/entities/user_profile.dart';
import 'dart:io';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this.remoteDatasource);

  final SettingsRemoteDatasource remoteDatasource;

  // ── Settings bundle (profile + app settings only, no staff) ──────────────

  @override
  Future<SettingsBundle> getSettingsBundle() {
    return remoteDatasource.getSettingsBundle();
  }

  // ── Business profile ──────────────────────────────────────────────────────

  @override
  Future<BusinessProfile> getBusinessProfile() async {
    final bundle = await getSettingsBundle();
    return bundle.profile;
  }

  @override
  Future<BusinessProfile> saveProfile(BusinessProfile profile) {
    return remoteDatasource.saveProfile(
      BusinessProfileModel.fromEntity(profile),
    );
  }

  @override
  Future<BusinessProfile> updateProfileField(String field, String value) async {
    final current = await getBusinessProfile();
    return saveProfile(_copyProfileField(current, field, value));
  }

  @override
Future<String> uploadBusinessLogo(File image) {
  return remoteDatasource.uploadBusinessLogo(image);
}



  // ── App settings ──────────────────────────────────────────────────────────

  @override
  Future<Map<String, String>> getSettings() async {
    final bundle = await getSettingsBundle();
    return bundle.settings;
  }

  @override
  Future<void> saveSetting(String key, String value) {
    return saveSettings({key: value});
  }

  @override
  Future<void> saveSettings(Map<String, String> settings) {
    return remoteDatasource.saveSettings(settings);
  }

  // ── Staff ─────────────────────────────────────────────────────────────────

  @override
  Future<List<StaffUser>> getStaffUsers() {
    // Now hits api/staff/get_staff.php — no longer bundled with settings
    return remoteDatasource.getStaffUsers();
  }

  @override
  Future<bool> addStaffUser(StaffUser user) {
    return remoteDatasource.addStaffUser(StaffUserModel.fromEntity(user));
  }

  @override
  Future<bool> updateStaffUser(StaffUser user) {
    return remoteDatasource.updateStaffUser(StaffUserModel.fromEntity(user));
  }

  @override
  Future<bool> deleteStaffUser(int staffUserId) {
    return remoteDatasource.deleteStaffUser(staffUserId);
  }

  @override
  Future<bool> setStaffUserStatus(int staffUserId, bool isActive) {
    return remoteDatasource.setStaffUserStatus(staffUserId, isActive);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  BusinessProfile _copyProfileField(
    BusinessProfile profile,
    String field,
    String value,
  ) {
    switch (field) {
      case 'storeName':
        return profile.copyWith(storeName: value);
      case 'tagline':
        return profile.copyWith(tagline: value);
      case 'logoPath':
        return profile.copyWith(logoPath: value);
      case 'businessAddress':
        return profile.copyWith(businessAddress: value);
      case 'phoneNumber':
        return profile.copyWith(phoneNumber: value);
      case 'emailAddress':
        return profile.copyWith(emailAddress: value);
      case 'gstNumber':
        return profile.copyWith(gstNumber: value);
      case 'taxRegistrationType':
        return profile.copyWith(taxRegistrationType: value);
      default:
        return profile;
    }
  }

@override
Future<UserProfile> getUserProfile() {
  return remoteDatasource.getUserProfile();
}

@override
Future<UserProfile> saveUserProfile(UserProfile profile) {
  return remoteDatasource.saveUserProfile(
    UserProfileModel.fromEntity(profile),
  );
}

@override
Future<String> uploadProfilePicture(File image) {
  return remoteDatasource.uploadProfilePicture(image);
}
// ── Product Categories ─────────────────────────────────────

@override
Future<List<Map<String, dynamic>>> getCategories() {
  return remoteDatasource.getCategories();
}

@override
Future<List<Map<String, dynamic>>> getAllCategories() {
  return remoteDatasource.getAllCategories();
}

@override
Future<void> addCategory({
  required String categoryName,
  required String description,
  required int displayOrder,
}) {
  return remoteDatasource.addCategory(
    categoryName: categoryName,
    description: description,
    displayOrder: displayOrder,
  );
}

@override
Future<void> updateCategory({
  required int id,
  required String categoryName,
  required String description,
  required int displayOrder,
}) {
  return remoteDatasource.updateCategory(
    id: id,
    categoryName: categoryName,
    description: description,
    displayOrder: displayOrder,
  );
}

@override
Future<void> deleteCategory(int id) {
  return remoteDatasource.deleteCategory(id);
}

@override
Future<void> toggleCategoryStatus({
  required int id,
  required String status,
}) {
  return remoteDatasource.toggleCategoryStatus(
    id: id,
    status: status,
  );
}

// ── Product Units ──────────────────────────────────────────

@override
Future<List<Map<String, dynamic>>> getUnits() {
  return remoteDatasource.getUnits();
}

@override
Future<List<Map<String, dynamic>>> getAllUnits() {
  return remoteDatasource.getAllUnits();
}

@override
Future<void> addUnit({
  required String unitName,
  required String shortName,
  required String description,
}) {
  return remoteDatasource.addUnit(
    unitName: unitName,
    shortName: shortName,
    description: description,
  );
}

@override
Future<void> updateUnit({
  required int id,
  required String unitName,
  required String shortName,
  required String description,
}) {
  return remoteDatasource.updateUnit(
    id: id,
    unitName: unitName,
    shortName: shortName,
    description: description,
  );
}

@override
Future<void> deleteUnit(int id) {
  return remoteDatasource.deleteUnit(id);
}

@override
Future<void> toggleUnitStatus({
  required int id,
  required String status,
}) {
  return remoteDatasource.toggleUnitStatus(
    id: id,
    status: status,
  );
}
}
