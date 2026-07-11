
import '../../../repositories/printers_hardware/printers_hardware_repository.dart';
import '../../../entities/printers_hardware/history/print_history_entry.dart';
class GetPrintHistoryUseCase {
  final PrintersHardwareRepository _repository;

  GetPrintHistoryUseCase(this._repository);

  Future<List<PrintHistoryEntry>> execute({int limit = 50}) async {
    return await _repository.getPrintHistory(limit: limit);
  }
}
