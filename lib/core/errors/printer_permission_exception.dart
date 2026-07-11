import 'printer_exception.dart';

/// Exception thrown when required permissions are denied.
class PrinterPermissionException extends PrinterException {
  const PrinterPermissionException(
    super.message, {
    super.cause,
  });
}