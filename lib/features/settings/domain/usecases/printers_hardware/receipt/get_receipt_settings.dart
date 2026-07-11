import '../../../entities/printers_hardware/printer/printer_settings.dart';
import '../../../repositories/printers_hardware/printers_hardware_repository.dart';

class GetReceiptSettingsUseCase {
  final PrintersHardwareRepository _repository;

  GetReceiptSettingsUseCase(this._repository);

  Future<PrinterSettings> execute() async {
    return await _repository.getReceiptSettings();
  }
}