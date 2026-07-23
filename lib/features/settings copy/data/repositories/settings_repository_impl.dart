import '../../domain/entities/business_profile.dart';
import '../../domain/entities/settings_bundle.dart';
import '../../domain/entities/staff_user.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_datasource.dart';
import '../models/business_profile_model.dart';
import '../models/staff_user_model.dart';

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
}