import '../../../entities/printers_hardware/printer/printer_settings.dart';
import '../../../repositories/printers_hardware/printers_hardware_repository.dart';

class SaveReceiptSettingsUseCase {
  final PrintersHardwareRepository _repository;

  SaveReceiptSettingsUseCase(this._repository);

  Future<void> execute(PrinterSettings settings) async {
    await _repository.saveReceiptSettings(settings);
  }
}