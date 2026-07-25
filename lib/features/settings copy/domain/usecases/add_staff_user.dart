import '../entities/staff_user.dart';
import '../repositories/settings_repository.dart';

class AddStaffUser {
  const AddStaffUser(this.repository);

  final SettingsRepository repository;

  Future<bool> call(StaffUser user) {
    return repository.addStaffUser(user);
  }
}
