import '../../../entities/printers_hardware/printer/printer_device.dart';
import '../../../repositories/printers_hardware/printers_hardware_repository.dart';

class ScanBluetoothPrintersUseCase {
  final PrintersHardwareRepository _repository;

  ScanBluetoothPrintersUseCase(this._repository);

  Future<List<PrinterDevice>> execute() async {
    return await _repository.scanBluetoothPrinters();
  }
}