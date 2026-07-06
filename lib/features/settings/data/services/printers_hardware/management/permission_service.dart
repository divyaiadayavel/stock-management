import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class PermissionService {
  /// Requests all necessary permissions for Bluetooth scanning and connection.
  Future<bool> requestBluetoothPermissions() async {
    if (Platform.isAndroid) {
      // Android 12+ requires specific BLUETOOTH_SCAN and BLUETOOTH_CONNECT permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location, // Location is often required for BLE scanning on older Androids
      ].request();

      final scanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? false;
      final connectGranted = statuses[Permission.bluetoothConnect]?.isGranted ?? false;
      
      // Fallback for older Android versions where location is the primary gatekeeper
      final locationGranted = statuses[Permission.location]?.isGranted ?? false;

      if ((scanGranted && connectGranted) || locationGranted) {
        return await _isBluetoothEnabled();
      }
      return false;
    } else if (Platform.isIOS) {
      final status = await Permission.bluetooth.request();
      if (status.isGranted) {
         return await _isBluetoothEnabled();
      }
      return false;
    }
    return true; // Other platforms
  }

  Future<bool> _isBluetoothEnabled() async {
    // Check if the hardware adapter is actually turned on
    final state = await FlutterBluePlus.adapterState.first;
    return state == BluetoothAdapterState.on;
  }
}