/// Type of scanner (input source).
enum ScannerType {
  keyboard,   // hardware keyboard wedge
  usb,        // dedicated USB scanner
  bluetooth,  // Bluetooth barcode scanner
  camera,     // camera-based scanning (e.g., ML Kit)
  network,    // network scanner (e.g., ScanSnap)
  unknown;

  String get label {
    switch (this) {
      case ScannerType.keyboard:
        return 'Keyboard Wedge';
      case ScannerType.usb:
        return 'USB Scanner';
      case ScannerType.bluetooth:
        return 'Bluetooth Scanner';
      case ScannerType.camera:
        return 'Camera';
      case ScannerType.network:
        return 'Network Scanner';
      case ScannerType.unknown:
        return 'Unknown';
    }
  }
}