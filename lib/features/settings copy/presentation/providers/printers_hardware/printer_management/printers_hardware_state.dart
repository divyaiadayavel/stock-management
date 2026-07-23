import '../../../../domain/entities/printers_hardware/printer/printer_device.dart';

class PrintersHardwareState {
  final PrinterDevice? connectedPrinter;

  /// All printers saved on the server for this user (from
  /// GET get_saved_printers.php). Used to render a "saved printers" list
  /// in the UI, independent of which one is currently connected.
  final List<PrinterDevice> savedPrinters;

  final bool isConnecting;
  final bool isPrinting;
  final String? errorMessage;

  const PrintersHardwareState({
    this.connectedPrinter,
    this.savedPrinters = const [],
    this.isConnecting = false,
    this.isPrinting = false,
    this.errorMessage,
  });

  PrintersHardwareState copyWith({
    PrinterDevice? connectedPrinter,
    List<PrinterDevice>? savedPrinters,
    bool? isConnecting,
    bool? isPrinting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PrintersHardwareState(
      connectedPrinter: connectedPrinter ?? this.connectedPrinter,
      savedPrinters: savedPrinters ?? this.savedPrinters,
      isConnecting: isConnecting ?? this.isConnecting,
      isPrinting: isPrinting ?? this.isPrinting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
