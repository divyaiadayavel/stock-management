import '../../../repositories/printers_hardware/printers_hardware_repository.dart';

class DisconnectPrinterUseCase {
  final PrintersHardwareRepository _repository;

  DisconnectPrinterUseCase(this._repository);

  Future<bool> execute() async {
    return await _repository.disconnectPrinter();
  }
}