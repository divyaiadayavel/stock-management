import 'printer_exception.dart';

/// Exception thrown when a printer operation times out.
class PrinterTimeoutException extends PrinterException {
  const PrinterTimeoutException(
    super.message, {
    super.cause,
  });
}