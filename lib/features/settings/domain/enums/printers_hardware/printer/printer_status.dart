/// Runtime connection/availability status of a printer.
enum PrinterStatus {
  disconnected,
  connecting,
  connected,
  printing,
  busy,
  offline,
  error;

  bool get isConnected => this == PrinterStatus.connected || this == PrinterStatus.printing;

  String get label {
    switch (this) {
      case PrinterStatus.disconnected:
        return 'Disconnected';
      case PrinterStatus.connecting:
        return 'Connecting…';
      case PrinterStatus.connected:
        return 'Connected';
      case PrinterStatus.printing:
        return 'Printing…';
      case PrinterStatus.busy:
        return 'Busy';
      case PrinterStatus.offline:
        return 'Offline';
      case PrinterStatus.error:
        return 'Error';
    }
  }
}