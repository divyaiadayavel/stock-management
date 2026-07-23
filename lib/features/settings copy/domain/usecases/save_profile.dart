import '../entities/business_profile.dart';
import '../repositories/settings_repository.dart';

class SaveProfile {
  const SaveProfile(this.repository);

  final SettingsRepository repository;

  Future<BusinessProfile> call(BusinessProfile profile) {
    return repository.saveProfile(profile);
  }
}
