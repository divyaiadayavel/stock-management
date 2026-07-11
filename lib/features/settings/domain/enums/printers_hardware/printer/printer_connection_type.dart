/// Physical printer connection type.
enum PrinterConnectionType {
  bluetooth,
  wifi,
  usb,
  ethernet,
  system;

  String get label {
    switch (this) {
      case PrinterConnectionType.bluetooth:
        return 'Bluetooth';

      case PrinterConnectionType.wifi:
        return 'Wi-Fi';

      case PrinterConnectionType.usb:
        return 'USB';

      case PrinterConnectionType.ethernet:
        return 'Ethernet';

      case PrinterConnectionType.system:
        return 'System Print';
    }
  }

  bool get isWireless =>
      this == PrinterConnectionType.bluetooth ||
      this == PrinterConnectionType.wifi;

  bool get isNetwork =>
      this == PrinterConnectionType.wifi ||
      this == PrinterConnectionType.ethernet;

  bool get isUsb =>
      this == PrinterConnectionType.usb;

  bool get usesSystemPrint =>
      this == PrinterConnectionType.system;
}