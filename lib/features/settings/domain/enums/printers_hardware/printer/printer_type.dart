/// Represents the type of printer.
///
/// Thermal printers use ESC/POS commands.
/// Document printers print PDF/A4 documents.
/// Label printers (e.g., Zebra) print labels.
/// Portable printers are small, battery-operated.
enum PrinterType {
  thermal,
  document,
  labelPrinter,
  portable,
  unknown;

  String get label {
    switch (this) {
      case PrinterType.thermal:
        return 'Thermal';
      case PrinterType.document:
        return 'Document';
      case PrinterType.labelPrinter:
        return 'Label';
      case PrinterType.portable:
        return 'Portable';
      case PrinterType.unknown:
        return 'Unknown';
    }
  }

  bool get isThermal => this == PrinterType.thermal;
  bool get isDocument => this == PrinterType.document;
  bool get isLabel => this == PrinterType.labelPrinter;
}