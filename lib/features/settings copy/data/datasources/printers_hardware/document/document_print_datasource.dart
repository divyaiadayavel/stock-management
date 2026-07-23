import '../../../models/printers_hardware/document/document_print_job_model.dart';
import '../../../models/printers_hardware/printer/printer_device_model.dart';

abstract class DocumentPrintDatasource {
  /// Prints any supported document (e.g., auto-detects type).
  Future<bool> printDocument(DocumentPrintJobModel job);

  /// Prints a PDF document.
  Future<bool> printPdf(DocumentPrintJobModel job);

  /// Prints an image.
  Future<bool> printImage(DocumentPrintJobModel job);

  /// Prints an invoice (can be PDF or specialized format).
  Future<bool> printInvoice(DocumentPrintJobModel job);

  /// Prints a receipt (uses receipt-specific formatting).
  Future<bool> printReceipt(DocumentPrintJobModel job);

  /// Sends a small test page to verify printer configuration.
  Future<bool> testPrint(PrinterDeviceModel printer);

  /// Returns saved document printers.
  Future<List<PrinterDeviceModel>> getAvailableDocumentPrinters();
}