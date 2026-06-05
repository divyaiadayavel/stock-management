import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/settings_remote_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/business_profile.dart';
import '../../domain/entities/settings_bundle.dart';
import '../../domain/entities/staff_user.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/add_staff_user.dart';
import '../../domain/usecases/get_settings_bundle.dart';
import '../../domain/usecases/save_profile.dart';
import '../../domain/usecases/save_setting.dart';

final storeNameProvider = StateProvider<String>((ref) => "");

final taglineProvider = StateProvider<String>((ref) => "");

final logoPathProvider = StateProvider<String?>((ref) => null);

final settingsRemoteDatasourceProvider = Provider<SettingsRemoteDatasource>((
  ref,
) {
  return SettingsRemoteDatasource();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(ref.read(settingsRemoteDatasourceProvider));
});

final getSettingsBundleProvider = Provider<GetSettingsBundle>((ref) {
  return GetSettingsBundle(ref.read(settingsRepositoryProvider));
});

final saveProfileProvider = Provider<SaveProfile>((ref) {
  return SaveProfile(ref.read(settingsRepositoryProvider));
});

final saveSettingProvider = Provider<SaveSetting>((ref) {
  return SaveSetting(ref.read(settingsRepositoryProvider));
});

final addStaffUserProvider = Provider<AddStaffUser>((ref) {
  return AddStaffUser(ref.read(settingsRepositoryProvider));
});

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, SettingsBundle>(
      SettingsController.new,
    );

class SettingsController extends AsyncNotifier<SettingsBundle> {
  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);

  @override
  Future<SettingsBundle> build() {
    return _repository.getSettingsBundle();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.getSettingsBundle);
  }

  Future<BusinessProfile> saveProfile(BusinessProfile profile) async {
    final savedProfile = await _repository.saveProfile(profile);
    _syncProfileProviders(savedProfile);
    _updateState((bundle) => bundle.copyWith(profile: savedProfile));
    return savedProfile;
  }

  Future<BusinessProfile> updateProfileField(String field, String value) async {
    final savedProfile = await _repository.updateProfileField(field, value);
    _syncProfileProviders(savedProfile);
    _updateState((bundle) => bundle.copyWith(profile: savedProfile));
    return savedProfile;
  }

  Future<void> saveSetting(String key, String value) async {
    await _repository.saveSetting(key, value);
    _updateState((bundle) {
      final updatedSettings = Map<String, String>.from(bundle.settings);
      updatedSettings[key] = value;
      return bundle.copyWith(settings: updatedSettings);
    });
  }

  Future<bool> addStaffUser(StaffUser user) async {
    final added = await _repository.addStaffUser(user);
    if (added) {
      await reload();
    }
    return added;
  }

  void syncProfileProviders(BusinessProfile profile) {
    _syncProfileProviders(profile);
  }

  void _syncProfileProviders(BusinessProfile profile) {
    ref.read(storeNameProvider.notifier).state = profile.storeName;
    ref.read(taglineProvider.notifier).state = profile.tagline;
    ref.read(logoPathProvider.notifier).state = profile.logoPath;
  }

  void _updateState(SettingsBundle Function(SettingsBundle bundle) update) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(update(current));
  }
}
