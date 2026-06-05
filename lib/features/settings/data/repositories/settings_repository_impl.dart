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

  @override
  Future<SettingsBundle> getSettingsBundle() {
    return remoteDatasource.getSettingsBundle();
  }

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
    final currentProfile = await getBusinessProfile();
    final updatedProfile = _copyProfileField(currentProfile, field, value);
    return saveProfile(updatedProfile);
  }

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

  @override
  Future<List<StaffUser>> getStaffUsers() async {
    final bundle = await getSettingsBundle();
    return bundle.staff;
  }

  @override
  Future<bool> addStaffUser(StaffUser user) {
    return remoteDatasource.addStaffUser(StaffUserModel.fromEntity(user));
  }

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
