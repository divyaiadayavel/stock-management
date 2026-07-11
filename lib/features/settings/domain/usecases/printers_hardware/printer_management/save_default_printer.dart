import '../../../entities/printers_hardware/printer/printer_device.dart';
import '../../../repositories/printers_hardware/printers_hardware_repository.dart';

class SaveDefaultPrinterUseCase {
  final PrintersHardwareRepository _repository;

  SaveDefaultPrinterUseCase(this._repository);

  Future<void> execute(PrinterDevice printer) async {
    return await _repository.saveDefaultPrinter(printer);
  }
}