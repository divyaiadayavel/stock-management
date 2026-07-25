class PrinterSettings {
  final String printerId;
  final bool isDefault;
  final bool autoPrintReceipt;
  final int printCopies;
  final bool showLogo;
  final bool showGst;
  final String footerText;
  final String paperSize;

  const PrinterSettings({
    required this.printerId,
    this.isDefault = false,
    this.autoPrintReceipt = true,
    this.printCopies = 1,
    this.showLogo = true,
    this.showGst = true,
    this.footerText = '',
    this.paperSize = 'mm80',
  });

  PrinterSettings copyWith({
    String? printerId,
    bool? isDefault,
    bool? autoPrintReceipt,
    int? printCopies,
    bool? showLogo,
    bool? showGst,
    String? footerText,
    String? paperSize,
  }) {
    return PrinterSettings(
      printerId: printerId ?? this.printerId,
      isDefault: isDefault ?? this.isDefault,
      autoPrintReceipt: autoPrintReceipt ?? this.autoPrintReceipt,
      printCopies: printCopies ?? this.printCopies,
      showLogo: showLogo ?? this.showLogo,
      showGst: showGst ?? this.showGst,
      footerText: footerText ?? this.footerText,
      paperSize: paperSize ?? this.paperSize,
    );
  }
}