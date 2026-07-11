/// Output format for receipts.
enum ReceiptFormat {
  thermal58,  // 58 mm thermal roll
  thermal80,  // 80 mm thermal roll
  pdf,        // PDF document
  a4,         // A4 document
  labelFormat;      // Label format (e.g., for shipping)

  String get label {
    switch (this) {
      case ReceiptFormat.thermal58:
        return '58 mm Thermal';
      case ReceiptFormat.thermal80:
        return '80 mm Thermal';
      case ReceiptFormat.pdf:
        return 'PDF';
      case ReceiptFormat.a4:
        return 'A4';
      case ReceiptFormat.labelFormat:
        return 'Label';
    }
  }

  bool get isThermal => this == ReceiptFormat.thermal58 || this == ReceiptFormat.thermal80;
  bool get isDocument => this == ReceiptFormat.pdf || this == ReceiptFormat.a4;
  bool get isLabel =>
    this == ReceiptFormat.labelFormat;
}