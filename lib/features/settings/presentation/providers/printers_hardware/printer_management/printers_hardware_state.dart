import '../../../../domain/entities/printers_hardware/printer/printer_device.dart';

class PrintersHardwareState {
  final PrinterDevice? connectedPrinter;
  final PrinterDevice? unavailablePrinter;

  /// All printers saved on the server for this user (from
  /// GET get_saved_printers.php). Used to render a "saved printers" list
  /// in the UI, independent of which one is currently connected.
  final List<PrinterDevice> savedPrinters;

  final bool isConnecting;
  final bool isReconnecting;
  final bool isPrinting;
  final String? errorMessage;

  const PrintersHardwareState({
    this.connectedPrinter,
    this.unavailablePrinter,
    this.savedPrinters = const [],
    this.isConnecting = false,
    this.isReconnecting = false,
    this.isPrinting = false,
    this.errorMessage,
  });

  PrintersHardwareState copyWith({
    PrinterDevice? connectedPrinter,
    PrinterDevice? unavailablePrinter,
    List<PrinterDevice>? savedPrinters,
    bool? isConnecting,
    bool? isReconnecting,
    bool? isPrinting,
    String? errorMessage,
    bool clearConnectedPrinter = false,
    bool clearUnavailablePrinter = false,
    bool clearError = false,
  }) {
    return PrintersHardwareState(
      connectedPrinter:
          clearConnectedPrinter ? null : (connectedPrinter ?? this.connectedPrinter),
      unavailablePrinter: clearUnavailablePrinter
          ? null
          : (unavailablePrinter ?? this.unavailablePrinter),
      savedPrinters: savedPrinters ?? this.savedPrinters,
      isConnecting: isConnecting ?? this.isConnecting,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      isPrinting: isPrinting ?? this.isPrinting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
