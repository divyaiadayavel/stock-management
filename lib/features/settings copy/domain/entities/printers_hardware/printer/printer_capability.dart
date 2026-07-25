class PrinterCapability {
  final int paperWidthMm; // kept for legacy / direct use
  final bool supports58mm;
  final bool supports80mm;
  final bool supportsA4;
  final bool supportsLetter;
  final bool supportsBarcode;
  final bool supportsQrCode;
  final bool supportsCashDrawerKick;
  final bool supportsLogo;
  final bool supportsImage;
  final bool supportsPdf;
  final bool supportsAutoCut;
  final bool supportsBeep;
  final bool supportsColor;
  final int maxCopies;

  const PrinterCapability({
    this.paperWidthMm = 80,
    this.supports58mm = true,
    this.supports80mm = true,
    this.supportsA4 = false,
    this.supportsLetter = false,
    this.supportsBarcode = true,
    this.supportsQrCode = true,
    this.supportsCashDrawerKick = true,
    this.supportsLogo = false,
    this.supportsImage = false,
    this.supportsPdf = false,
    this.supportsAutoCut = false,
    this.supportsBeep = false,
    this.supportsColor = false,
    this.maxCopies = 1,
  });

  PrinterCapability copyWith({
    int? paperWidthMm,
    bool? supports58mm,
    bool? supports80mm,
    bool? supportsA4,
    bool? supportsLetter,
    bool? supportsBarcode,
    bool? supportsQrCode,
    bool? supportsCashDrawerKick,
    bool? supportsLogo,
    bool? supportsImage,
    bool? supportsPdf,
    bool? supportsAutoCut,
    bool? supportsBeep,
    bool? supportsColor,
    int? maxCopies,
  }) {
    return PrinterCapability(
      paperWidthMm: paperWidthMm ?? this.paperWidthMm,
      supports58mm: supports58mm ?? this.supports58mm,
      supports80mm: supports80mm ?? this.supports80mm,
      supportsA4: supportsA4 ?? this.supportsA4,
      supportsLetter: supportsLetter ?? this.supportsLetter,
      supportsBarcode: supportsBarcode ?? this.supportsBarcode,
      supportsQrCode: supportsQrCode ?? this.supportsQrCode,
      supportsCashDrawerKick: supportsCashDrawerKick ?? this.supportsCashDrawerKick,
      supportsLogo: supportsLogo ?? this.supportsLogo,
      supportsImage: supportsImage ?? this.supportsImage,
      supportsPdf: supportsPdf ?? this.supportsPdf,
      supportsAutoCut: supportsAutoCut ?? this.supportsAutoCut,
      supportsBeep: supportsBeep ?? this.supportsBeep,
      supportsColor: supportsColor ?? this.supportsColor,
      maxCopies: maxCopies ?? this.maxCopies,
    );
  }
}