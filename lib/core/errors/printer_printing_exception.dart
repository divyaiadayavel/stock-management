import 'printer_exception.dart';

/// Exception thrown when a printer fails while printing.
class PrinterPrintingException extends PrinterException {
  const PrinterPrintingException(
    super.message, {
    super.cause,
  });
}