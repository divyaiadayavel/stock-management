import '../entities/settings_bundle.dart';
import '../repositories/settings_repository.dart';

class GetSettingsBundle {
  const GetSettingsBundle(this.repository);

  final SettingsRepository repository;

  Future<SettingsBundle> call() => repository.getSettingsBundle();
}
