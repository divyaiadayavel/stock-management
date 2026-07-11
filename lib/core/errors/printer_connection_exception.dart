import 'printer_exception.dart';

/// Exception thrown when a printer connection fails.
class PrinterConnectionException extends PrinterException {
  const PrinterConnectionException(
    super.message, {
    super.cause,
  });
}