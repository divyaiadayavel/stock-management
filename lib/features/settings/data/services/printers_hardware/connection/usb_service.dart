import '../../../../../../core/errors/printer_exception.dart';

/// UNUSED — superseded by [UsbDataSource]/[UsbDataSourceImpl]. The
/// repository depends on `UsbDataSource`, not this class. Kept only
/// because deleting files is out of scope for this change — do not wire
/// this into DI anywhere.
@Deprecated('Use UsbDataSource / UsbDataSourceImpl instead. Not wired in.')
class UsbService {
  bool _connected = false;

  Future<List<Map<String, dynamic>>> getDevices() async {
    return [];
  }

  Future<bool> connect(int vendorId, int productId) async {
    _connected = false;
    throw PrinterException('USB printing not implemented');
  }

  Future<bool> disconnect() async {
    _connected = false;
    return true;
  }

  Future<bool> isConnected() async {
    return _connected;
  }

  Future<bool> printBytes(List<int> bytes) async {
    if (!_connected) throw PrinterException('USB not connected');
    throw PrinterException('USB printing not implemented');
  }
}