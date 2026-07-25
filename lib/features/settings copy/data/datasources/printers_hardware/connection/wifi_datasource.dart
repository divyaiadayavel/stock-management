import 'dart:io';
import 'package:esc_pos_printer_plus/esc_pos_printer_plus.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../../../models/printers_hardware/printer/printer_device_model.dart';
import '../../../services/printers_hardware/discovery/mdns_discovery_service.dart';
import '../../../../../../core/errors/printer_connection_exception.dart';
import '../../../../../../core/errors/printer_printing_exception.dart';

abstract class WifiDataSource {
  Future<List<PrinterDeviceModel>> scanNetwork();
  Future<bool> isReachable(String ip, int port);
  Future<void> connect(String ipAddress, int port);
  Future<void> disconnect();
  Future<bool> printBytes(List<int> bytes);
  Future<bool> testConnection(String ip, int port);
  Future<bool> isConnected();
}

class WifiDataSourceImpl implements WifiDataSource {
  final MdnsDiscoveryService _discoveryService = MdnsDiscoveryService();
  NetworkPrinter? _printer;
  bool _connected = false;
  CapabilityProfile? _cachedProfile;

  @override
  Future<List<PrinterDeviceModel>> scanNetwork() async {
    final List<PrinterDeviceModel> merged = [];
    final mdnsDevices = await _discoveryService.scanPrinters();
    merged.addAll(mdnsDevices);
    final tcpDevices = await _scanTcpPorts();
    merged.addAll(tcpDevices);

    final seen = <String>{};
    return merged.where((device) {
      final ip = device.configuration.ipAddress;
      if (ip == null) return false;
      if (seen.contains(ip)) return false;
      seen.add(ip);
      return true;
    }).toList();
  }

  // Placeholder – subnet scan will be implemented in Sprint 3.
  Future<List<PrinterDeviceModel>> _scanTcpPorts() async {
    return [];
  }

  @override
  Future<bool> isReachable(String ip, int port) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 2));
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> connect(String ipAddress, int port) async {
    try {
      if (_printer != null) {
        _printer?.disconnect();
        _printer = null;
        _connected = false;
      }

      _cachedProfile ??= await CapabilityProfile.load(name: 'default');

      _printer = NetworkPrinter(PaperSize.mm80, _cachedProfile!);
      final result = await _printer!.connect(ipAddress, port: port);
      if (result != PosPrintResult.success) {
        _printer?.disconnect();
        _printer = null;
        throw PrinterConnectionException('Failed to connect: ${result.msg}');
      }
      _connected = true;
    } catch (e) {
      throw PrinterConnectionException('Wi-Fi connection failed.', cause: e);
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      if (_printer != null) {
        _printer!.disconnect();
        _printer = null;
      }
      _connected = false;
    } catch (e) {
      throw PrinterConnectionException('Wi-Fi disconnect failed.', cause: e);
    }
  }

  @override
  Future<bool> printBytes(List<int> bytes) async {
    if (!_connected || _printer == null) {
      throw const PrinterConnectionException('Wi-Fi printer is not connected.');
    }
    if (bytes.isEmpty) {
      throw const PrinterPrintingException('Cannot print empty data.');
    }
    try {
      // Check result if rawBytes returns bool; if not, just call it.
_printer!.rawBytes(bytes);
return true;
    } catch (e) {
      throw PrinterPrintingException('Wi-Fi printing failed.', cause: e);
    }
  }

  @override
  Future<bool> testConnection(String ip, int port) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 2));
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isConnected() async => _connected && _printer != null;
}