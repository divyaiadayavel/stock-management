import '../../../entities/printers_hardware/printer/printer_device.dart';
import '../../../repositories/printers_hardware/printers_hardware_repository.dart';

class ScanWifiPrintersUseCase {
  final PrintersHardwareRepository _repository;

  ScanWifiPrintersUseCase(this._repository);

  Future<List<PrinterDevice>> execute() async {
    return await _repository.scanWifiPrinters();
  }
}