import '../../../entities/printers_hardware/printer/printer_device.dart';
import '../../../repositories/printers_hardware/printers_hardware_repository.dart';

class ConnectPrinterUseCase {
  final PrintersHardwareRepository _repository;

  ConnectPrinterUseCase(this._repository);

  Future<bool> execute(PrinterDevice printer) async {
    return await _repository.connectPrinter(printer);
  }
}