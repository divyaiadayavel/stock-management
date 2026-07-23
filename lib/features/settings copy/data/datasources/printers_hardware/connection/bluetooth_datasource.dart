import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../../../../../../core/errors/printer_connection_exception.dart';
import '../../../../../../core/errors/printer_printing_exception.dart';

abstract class BluetoothDataSource {
  Future<List<BluetoothInfo>> getPairedDevices();
  Future<bool> connect(String macAddress);
  Future<bool> disconnect();
  Future<bool> printBytes(List<int> bytes);
  Future<bool> isConnected();
  Future<bool> reconnect(String macAddress);
}

class BluetoothDataSourceImpl implements BluetoothDataSource {
  @override
  Future<List<BluetoothInfo>> getPairedDevices() async {
    try {
      return await PrintBluetoothThermal.pairedBluetooths;
    } catch (e) {
      throw PrinterConnectionException('Failed to fetch Bluetooth devices.', cause: e);
    }
  }

  @override
  Future<bool> connect(String macAddress) async {
    try {
      final enabled = await PrintBluetoothThermal.bluetoothEnabled;
      if (!enabled) {
        throw const PrinterConnectionException('Bluetooth is disabled.');
      }
      final connected =
    await PrintBluetoothThermal.connectionStatus;

if (connected) {
  return true;
}

return await PrintBluetoothThermal.connect(
  macPrinterAddress: macAddress,
);
    } catch (e) {
      throw PrinterConnectionException('Failed to connect to Bluetooth printer.', cause: e);
    }
  }

  @override
  Future<bool> disconnect() async {
    try {
      return await PrintBluetoothThermal.disconnect;
    } catch (e) {
      throw PrinterConnectionException('Failed to disconnect.', cause: e);
    }
  }

  @override
  Future<bool> printBytes(List<int> bytes) async {
    try {
      if (bytes.isEmpty) {
        throw const PrinterPrintingException('Cannot print empty data.');
      }
if (!await isConnected()) {
  throw const PrinterConnectionException(
      'Bluetooth printer is not connected.');
}
      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (e) {
      throw PrinterPrintingException('Failed to print via Bluetooth.', cause: e);
    }
  }

  @override
  Future<bool> isConnected() async {
    try {
      return await PrintBluetoothThermal.connectionStatus;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> reconnect(String macAddress) async {
    // Attempt to disconnect, then connect fresh.
    try {
      await disconnect();
      return await connect(macAddress);
    } catch (e) {
      throw PrinterConnectionException('Reconnection failed.', cause: e);
    }
  }
}