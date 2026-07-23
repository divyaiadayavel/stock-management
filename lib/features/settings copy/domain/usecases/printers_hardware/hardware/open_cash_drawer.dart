import '../../../entities/printers_hardware/printer/printer_device.dart';
import '../../../repositories/printers_hardware/printers_hardware_repository.dart';

class OpenCashDrawerUseCase {
  final PrintersHardwareRepository _repository;

  OpenCashDrawerUseCase(this._repository);

  Future<bool> execute(PrinterDevice printer) async {
    if (!printer.capabilities.supportsCashDrawerKick) {
      throw Exception('This printer does not support kicking a cash drawer.');
    }
    return await _repository.openCashDrawer(printer);
  }
}