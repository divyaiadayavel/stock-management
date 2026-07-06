import '../../../entities/printers_hardware/printer/printer_device.dart';
import '../../../repositories/printers_hardware/printers_hardware_repository.dart';

class TestPrintUseCase {
  final PrintersHardwareRepository _repository;

  TestPrintUseCase(this._repository);

  Future<bool> execute(PrinterDevice printer) async {
    return await _repository.testPrint(printer);
  }
}