/// Base class for all printer-related exceptions in this app.
class PrinterException implements Exception {
  const PrinterException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => cause != null
      ? 'PrinterException: $message (caused by: $cause)'
      : 'PrinterException: $message';
}
