import '../repositories/settings_repository.dart';

class SaveSetting {
  const SaveSetting(this.repository);

  final SettingsRepository repository;

  Future<void> call(String key, String value) {
    return repository.saveSetting(key, value);
  }
}
