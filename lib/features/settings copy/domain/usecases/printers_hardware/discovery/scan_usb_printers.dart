import '../../../entities/printers_hardware/printer/printer_device.dart';
import '../../../repositories/printers_hardware/printers_hardware_repository.dart';

class ScanUsbPrintersUseCase {
  final PrintersHardwareRepository _repository;

  ScanUsbPrintersUseCase(this._repository);

  Future<List<PrinterDevice>> execute() async {
    return await _repository.scanUsbPrinters();
  }
}