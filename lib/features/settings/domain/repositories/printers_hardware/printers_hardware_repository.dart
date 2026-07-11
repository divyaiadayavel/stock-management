import '../../entities/printers_hardware/document/document_print_job.dart';
import '../../entities/printers_hardware/printer/printer_device.dart';
import '../../entities/printers_hardware/printer/printer_settings.dart';
import '../../entities/printers_hardware/receipt/receipt.dart';
import '../../entities/printers_hardware/history/print_history_entry.dart';
abstract class PrintersHardwareRepository {
  // Discovery
  Future<List<PrinterDevice>> scanBluetoothPrinters();
  Future<List<PrinterDevice>> scanUsbPrinters();
  Future<List<PrinterDevice>> scanWifiPrinters();

  // Connection
  Future<bool> connectPrinter(PrinterDevice printer);
  Future<bool> disconnectPrinter();

  // Storage
  Future<List<PrinterDevice>> getSavedPrinters();
  Future<void> saveDefaultPrinter(PrinterDevice printer);
  Future<void> deletePrinter(String printerId);

  // Printing
  Future<bool> testPrint(PrinterDevice printer);
  Future<bool> printReceipt(
    Receipt receipt,
    PrinterDevice printer,
  );
  Future<bool> printDocument(
    DocumentPrintJob job,
  );

  // Receipt Settings
  Future<PrinterSettings> getReceiptSettings();
  Future<void> saveReceiptSettings(
    PrinterSettings settings,
  );

  // Hardware
  Future<bool> openCashDrawer(PrinterDevice printer);

  // History
  Future<List<PrintHistoryEntry>> getPrintHistory({
    int limit = 50,
  });
  Future<bool> clearPrintHistory();
  Future<void> createPrintHistory({
    required Receipt receipt,
    required PrinterDevice printer,
    required bool success,
    String? errorMessage,
  });

  // Diagnostics
  Future<Map<String, dynamic>> runPrinterDiagnostics(
    PrinterDevice printer,
  );
}
