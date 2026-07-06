/// Supported paper sizes.
///
/// Thermal printers use 58mm / 80mm rolls.
/// Document printers use A4.
enum AppPaperSize {
  mm58,
  mm80,
  a4;

  /// Width in millimetres.
  int get widthMm {
    switch (this) {
      case AppPaperSize.mm58:
        return 58;

      case AppPaperSize.mm80:
        return 80;

      case AppPaperSize.a4:
        return 210; // A4 width
    }
  }

  String get label {
    switch (this) {
      case AppPaperSize.mm58:
        return '58 mm';

      case AppPaperSize.mm80:
        return '80 mm';

      case AppPaperSize.a4:
        return 'A4';
    }
  }

  bool get isThermal =>
      this == AppPaperSize.mm58 || this == AppPaperSize.mm80;

  bool get isDocument =>
      this == AppPaperSize.a4;

  static AppPaperSize fromMm(int mm) {
    switch (mm) {
      case 58:
        return AppPaperSize.mm58;

      case 80:
        return AppPaperSize.mm80;

      case 210:
        return AppPaperSize.a4;

      default:
        return AppPaperSize.mm80;
    }
  }
}