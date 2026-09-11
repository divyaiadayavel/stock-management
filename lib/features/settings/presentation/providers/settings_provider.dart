import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
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
import '../../domain/entities/user_profile.dart';

// ── Simple state providers ────────────────────────────────────────────────────

final storeNameProvider = StateProvider<String>((ref) => '');
final taglineProvider   = StateProvider<String>((ref) => '');
final logoPathProvider  = StateProvider<String?>((ref) => null);
final profileNameProvider =
    StateProvider<String>((ref) => '');

final profileRoleProvider =
    StateProvider<String>((ref) => '');

final profilePictureProvider =
    StateProvider<String?>((ref) => null);

// ── Infrastructure providers ──────────────────────────────────────────────────

final settingsRemoteDatasourceProvider = Provider<SettingsRemoteDatasource>(
  (ref) => SettingsRemoteDatasource(),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.read(settingsRemoteDatasourceProvider)),
);

// ── Use-case providers ────────────────────────────────────────────────────────

final getSettingsBundleProvider = Provider<GetSettingsBundle>(
  (ref) => GetSettingsBundle(ref.read(settingsRepositoryProvider)),
);

final saveProfileProvider = Provider<SaveProfile>(
  (ref) => SaveProfile(ref.read(settingsRepositoryProvider)),
);

final saveSettingProvider = Provider<SaveSetting>(
  (ref) => SaveSetting(ref.read(settingsRepositoryProvider)),
);

final addStaffUserProvider = Provider<AddStaffUser>(
  (ref) => AddStaffUser(ref.read(settingsRepositoryProvider)),
);

// ── Settings controller (profile + app settings only) ────────────────────────

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, SettingsBundle>(
      SettingsController.new,
    );

class SettingsController extends AsyncNotifier<SettingsBundle> {
  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  @override
  Future<SettingsBundle> build() {
    return _repo.getSettingsBundle();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.getSettingsBundle);
  }

  Future<BusinessProfile> saveProfile(BusinessProfile profile) async {
    final saved = await _repo.saveProfile(profile);
    _syncProfileProviders(saved);
    _updateState((b) => b.copyWith(profile: saved));
    return saved;
  }

  Future<BusinessProfile> uploadBusinessLogo(File image) async {
  final current = state.valueOrNull;

  if (current == null) {
    throw Exception("Business profile not loaded.");
  }

  final logoPath = await _repo.uploadBusinessLogo(image);

  final updatedProfile = current.profile.copyWith(
    logoPath: logoPath,
  );

  return saveProfile(updatedProfile);
}

  Future<BusinessProfile> updateProfileField(String field, String value) async {
    final saved = await _repo.updateProfileField(field, value);
    _syncProfileProviders(saved);
    _updateState((b) => b.copyWith(profile: saved));
    return saved;
  }

  Future<void> saveSetting(String key, String value) async {
    await _repo.saveSetting(key, value);
    _updateState((b) {
      final updated = Map<String, String>.from(b.settings)..[key] = value;
      return b.copyWith(settings: updated);
    });
  }

  void syncProfileProviders(BusinessProfile profile) =>
      _syncProfileProviders(profile);

  void _syncProfileProviders(BusinessProfile profile) {
    ref.read(storeNameProvider.notifier).state = profile.storeName;
    ref.read(taglineProvider.notifier).state   = profile.tagline;
    ref.read(logoPathProvider.notifier).state  = profile.logoPath;
  }

  void _updateState(SettingsBundle Function(SettingsBundle) update) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(update(current));
  }

// Future<UserProfile> saveUserProfile(
//     UserProfile profile) async {

//   final saved =
//       await _repo.saveUserProfile(profile);

//   syncUserProfile(saved);

//   return saved;
// }

// Future<UserProfile> uploadProfilePicture(
//     File image) async {

//   final currentName =
//       ref.read(profileNameProvider);

//   final currentRole =
//       ref.read(profileRoleProvider);

//   final path =
//       await _repo.uploadProfilePicture(image);

//   final saved =
//       await saveUserProfile(
//         UserProfile(
//           id: 1,
//           name: currentName,
//           role: currentRole,
//           profilePicture: path,
//         ),
//       );

//   return saved;
// }

// void syncUserProfile(UserProfile profile) {
//   ref.read(profileNameProvider.notifier).state =
//       profile.name;

//   ref.read(profileRoleProvider.notifier).state =
//       profile.role;

//   ref.read(profilePictureProvider.notifier).state =
//       profile.profilePicture;
// }
Future<UserProfile> saveUserProfile(
  UserProfile profile,
) async {
  final saved = await _repo.saveUserProfile(profile);

  syncUserProfile(saved);

  return saved;
}

Future<String> uploadProfilePicture(
  File image,
) async {
  final path = await _repo.uploadProfilePicture(image);

  ref.read(profilePictureProvider.notifier).state = path;

  return path;
}

void syncUserProfile(UserProfile profile) {
  ref.read(profileNameProvider.notifier).state =
      profile.name;

  ref.read(profileRoleProvider.notifier).state =
      profile.role;

  ref.read(profilePictureProvider.notifier).state =
      profile.profilePicture;
}
}

// ── Staff controller (separate — hits api/staff/ endpoints) ──────────────────

final staffControllerProvider =
    AsyncNotifierProvider<StaffController, List<StaffUser>>(
      StaffController.new,
    );

class StaffController extends AsyncNotifier<List<StaffUser>> {
  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  @override
  Future<List<StaffUser>> build() {
    return _repo.getStaffUsers();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.getStaffUsers);
  }

  Future<bool> addStaffUser(StaffUser user) async {
    final success = await _repo.addStaffUser(user);
    if (success) await reload();
    return success;
  }

  Future<bool> updateStaffUser(StaffUser user) async {
    final success = await _repo.updateStaffUser(user);
    if (success) await reload();
    return success;
  }

  Future<bool> deleteStaffUser(int staffUserId) async {
    final success = await _repo.deleteStaffUser(staffUserId);
    if (success) await reload();
    return success;
  }

  Future<bool> setStaffUserStatus(int staffUserId, bool isActive) async {
    final success = await _repo.setStaffUserStatus(staffUserId, isActive);
    if (success) await reload();
    return success;
  }
}