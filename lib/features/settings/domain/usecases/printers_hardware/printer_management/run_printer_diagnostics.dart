import '../../../entities/printers_hardware/printer/printer_device.dart';
import '../../../repositories/printers_hardware/printers_hardware_repository.dart';

class RunPrinterDiagnosticsUseCase {
  final PrintersHardwareRepository _repository;

  RunPrinterDiagnosticsUseCase(this._repository);

  Future<Map<String, dynamic>> execute(PrinterDevice printer) async {
    // You can add domain-level validation or formatting for diagnostics here
    final result = await _repository.runPrinterDiagnostics(printer);
    
    if (result.isEmpty) {
      throw Exception('Diagnostics failed to return data.');
    }
    
    return result;
  }
}