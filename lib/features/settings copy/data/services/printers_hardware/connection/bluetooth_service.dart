import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../../../../../../core/errors/printer_connection_exception.dart';
class BluetoothService {
  String? _connectedMac;

  Future<List<BluetoothInfo>> getPairedDevices() async {
    return await PrintBluetoothThermal.pairedBluetooths;
  }

  Future<bool> connect(String macAddress) async {
    final success = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
    if (success) _connectedMac = macAddress;
    return success;
  }

  Future<bool> disconnect() async {
    final success = await PrintBluetoothThermal.disconnect;
    if (success) _connectedMac = null;
    return success;
  }

  Future<bool> get isConnected async {
    return await PrintBluetoothThermal.connectionStatus;
  }

  Future<String?> getConnectedPrinterMac() async {
    return _connectedMac;
  }

  Future<bool> ensureConnected(String macAddress) async {
    final connected = await isConnected;
    if (connected && _connectedMac == macAddress) return true;
    if (connected) await disconnect();
    return await connect(macAddress);
  }

  Future<bool> printBytes(List<int> bytes) async {
    final connected = await isConnected;
    if (!connected) {
      throw const PrinterConnectionException('Bluetooth printer is not connected.');
    }
    return await PrintBluetoothThermal.writeBytes(bytes);
  }

  Future<void> dispose() async {
    await disconnect();
    _connectedMac = null;
  }
}