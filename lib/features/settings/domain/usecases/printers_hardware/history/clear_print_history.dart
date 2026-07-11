import '../../../repositories/printers_hardware/printers_hardware_repository.dart';

class ClearPrintHistoryUseCase {
  final PrintersHardwareRepository _repository;

  ClearPrintHistoryUseCase(this._repository);

  Future<void> execute() async {
    await _repository.clearPrintHistory();
  }
}