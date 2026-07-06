import '../../../repositories/printers_hardware/printers_hardware_repository.dart';

class DeletePrinterUseCase {
  final PrintersHardwareRepository _repository;

  DeletePrinterUseCase(this._repository);

  Future<void> execute(String printerId) async {
    if (printerId.isEmpty) {
      throw ArgumentError('Printer ID cannot be empty');
    }
    return await _repository.deletePrinter(printerId);
  }
}