/// Supported printer vendors.
///
/// Includes both thermal receipt printers and A4 document printers.
enum PrinterVendor {
  generic,
  // Document printers
  canon,
  hp,
  brother,
  epson,
  ricoh,
  kyocera,
  xerox,
  pantum,
  toshiba,
  // Thermal receipt printers
  star,
  citizen,
  bixolon,
  posiflex,
  xprinter,
  sunmi,
  zebra,
  hprt,
  gainscha,
  tsc,
  godex,
  sato,
  // Other
  unknown,
}

extension PrinterVendorExtension on PrinterVendor {
  String get displayName {
    switch (this) {
      case PrinterVendor.generic:
        return 'Generic';
      case PrinterVendor.canon:
        return 'Canon';
      case PrinterVendor.hp:
        return 'HP';
      case PrinterVendor.brother:
        return 'Brother';
      case PrinterVendor.epson:
        return 'Epson';
      case PrinterVendor.ricoh:
        return 'Ricoh';
      case PrinterVendor.kyocera:
        return 'Kyocera';
      case PrinterVendor.xerox:
        return 'Xerox';
      case PrinterVendor.pantum:
        return 'Pantum';
      case PrinterVendor.toshiba:
        return 'Toshiba';
      case PrinterVendor.star:
        return 'Star Micronics';
      case PrinterVendor.citizen:
        return 'Citizen';
      case PrinterVendor.bixolon:
        return 'Bixolon';
      case PrinterVendor.posiflex:
        return 'Posiflex';
      case PrinterVendor.xprinter:
        return 'XPrinter';
      case PrinterVendor.sunmi:
        return 'Sunmi';
      case PrinterVendor.zebra:
        return 'Zebra';
      case PrinterVendor.hprt:
        return 'HPRT';
      case PrinterVendor.gainscha:
        return 'Gainscha';
      case PrinterVendor.tsc:
        return 'TSC';
      case PrinterVendor.godex:
        return 'Godex';
      case PrinterVendor.sato:
        return 'Sato';
      case PrinterVendor.unknown:
        return 'Unknown';
    }
  }

  bool get isThermal => switch (this) {
        PrinterVendor.star ||
        PrinterVendor.citizen ||
        PrinterVendor.bixolon ||
        PrinterVendor.posiflex ||
        PrinterVendor.xprinter ||
        PrinterVendor.sunmi ||
        PrinterVendor.zebra ||
        PrinterVendor.hprt ||
        PrinterVendor.gainscha ||
        PrinterVendor.tsc ||
        PrinterVendor.godex ||
        PrinterVendor.sato =>
          true,
        _ => false,
      };

  bool get isDocument => switch (this) {
        PrinterVendor.canon ||
        PrinterVendor.hp ||
        PrinterVendor.brother ||
        PrinterVendor.epson ||
        PrinterVendor.ricoh ||
        PrinterVendor.kyocera ||
        PrinterVendor.xerox ||
        PrinterVendor.pantum ||
        PrinterVendor.toshiba =>
          true,
        _ => false,
      };

  /// Attempts to determine the vendor from a printer name.
  static PrinterVendor fromName(String? name) {
    if (name == null || name.trim().isEmpty) return PrinterVendor.unknown;
    final value = name.toLowerCase();

    if (value.contains('canon')) return PrinterVendor.canon;
    if (value.contains('hp') || value.contains('hewlett')) return PrinterVendor.hp;
    if (value.contains('brother')) return PrinterVendor.brother;
    if (value.contains('epson')) return PrinterVendor.epson;
    if (value.contains('ricoh')) return PrinterVendor.ricoh;
    if (value.contains('kyocera')) return PrinterVendor.kyocera;
    if (value.contains('xerox')) return PrinterVendor.xerox;
    if (value.contains('pantum')) return PrinterVendor.pantum;
    if (value.contains('toshiba')) return PrinterVendor.toshiba;
    if (value.contains('star')) return PrinterVendor.star;
    if (value.contains('citizen')) return PrinterVendor.citizen;
    if (value.contains('bixolon')) return PrinterVendor.bixolon;
    if (value.contains('posiflex')) return PrinterVendor.posiflex;
    if (value.contains('xprinter')) return PrinterVendor.xprinter;
    if (value.contains('sunmi')) return PrinterVendor.sunmi;
    if (value.contains('zebra')) return PrinterVendor.zebra;
    if (value.contains('hprt')) return PrinterVendor.hprt;
    if (value.contains('gainscha')) return PrinterVendor.gainscha;
    if (value.contains('tsc')) return PrinterVendor.tsc;
    if (value.contains('godex')) return PrinterVendor.godex;
    if (value.contains('sato')) return PrinterVendor.sato;

    return PrinterVendor.generic;
  }
}