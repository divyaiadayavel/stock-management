import 'printer_exception.dart';

/// Exception thrown while discovering printers.
class PrinterDiscoveryException extends PrinterException {
  const PrinterDiscoveryException(
    super.message, {
    super.cause,
  });
}