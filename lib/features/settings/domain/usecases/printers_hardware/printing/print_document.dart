import '../../../entities/printers_hardware/document/document_print_job.dart';
import '../../../repositories/printers_hardware/printers_hardware_repository.dart';

class PrintDocumentUseCase {
  final PrintersHardwareRepository _repository;

  PrintDocumentUseCase(this._repository);

  Future<bool> execute(DocumentPrintJob job) async {
    return await _repository.printDocument(job);
  }
}