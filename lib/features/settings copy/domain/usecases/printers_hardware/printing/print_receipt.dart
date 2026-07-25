import '../../../entities/printers_hardware/printer/printer_device.dart';
import '../../../entities/printers_hardware/receipt/receipt.dart';
import '../../../repositories/printers_hardware/printers_hardware_repository.dart';

class PrintReceiptUseCase {
  final PrintersHardwareRepository _repository;

  PrintReceiptUseCase(this._repository);

  Future<bool> execute({
    required PrinterDevice printer,
    required Receipt receipt,
  }) async {
return await _repository.printReceipt(
  receipt,
  printer,
);
  }
}