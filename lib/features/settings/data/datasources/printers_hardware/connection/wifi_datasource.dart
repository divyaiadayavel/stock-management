import 'dart:io';

import 'package:esc_pos_printer_plus/esc_pos_printer_plus.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../../../../../../core/errors/printer_connection_exception.dart';
import '../../../../../../core/errors/printer_printing_exception.dart';
import '../../../../domain/enums/printers_hardware/printer/printer_connection_type.dart';
import '../../../../domain/enums/printers_hardware/printer/printer_type.dart';
import '../../../models/printers_hardware/printer/printer_capability_model.dart';
import '../../../models/printers_hardware/printer/printer_configuration_model.dart';
import '../../../models/printers_hardware/printer/printer_device_model.dart';

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
  static const int _rawPrinterPort = 9100;
  static const int _scanConcurrency = 32;
  static const Duration _tcpScanTimeout = Duration(milliseconds: 450);

  final NetworkInfo _networkInfo;
  NetworkPrinter? _printer;
  bool _connected = false;
  CapabilityProfile? _cachedProfile;

  WifiDataSourceImpl({NetworkInfo? networkInfo})
      : _networkInfo = networkInfo ?? NetworkInfo();

  @override
  Future<List<PrinterDeviceModel>> scanNetwork() async {
    final tcpDevices = await _scanTcpPorts();
    final seen = <String>{};
    return tcpDevices.where((device) {
      final ip = device.configuration.ipAddress;
      if (ip == null) return false;
      if (seen.contains(ip)) return false;
      seen.add(ip);
      return true;
    }).toList();
  }

  Future<List<PrinterDeviceModel>> _scanTcpPorts() async {
    final localIp = await _localWifiIp();
    final subnet = _subnetFromIp(localIp);
    if (localIp == null || subnet == null) return [];

    final hosts = List<String>.generate(254, (index) => '$subnet.${index + 1}')
        .where((ip) => ip != localIp)
        .toList(growable: false);

    final discovered = <PrinterDeviceModel>[];
    for (var start = 0; start < hosts.length; start += _scanConcurrency) {
      final end = start + _scanConcurrency < hosts.length
          ? start + _scanConcurrency
          : hosts.length;
      final batch = hosts.sublist(start, end);
      final results = await Future.wait(batch.map(_probeRawPrinter));
      discovered.addAll(results.whereType<PrinterDeviceModel>());
    }
    return discovered;
  }

  Future<String?> _localWifiIp() async {
    try {
      return await _networkInfo.getWifiIP();
    } catch (_) {
      return null;
    }
  }

  String? _subnetFromIp(String? ip) {
    if (ip == null) return null;
    final parts = ip.split('.');
    if (parts.length != 4) return null;
    for (final part in parts) {
      final value = int.tryParse(part);
      if (value == null || value < 0 || value > 255) return null;
    }
    return '${parts[0]}.${parts[1]}.${parts[2]}';
  }

  Future<PrinterDeviceModel?> _probeRawPrinter(String ip) async {
    Socket? socket;
    try {
      socket = await Socket.connect(
        ip,
        _rawPrinterPort,
        timeout: _tcpScanTimeout,
      );
      socket.destroy();
      return PrinterDeviceModel(
        id: 'network_${ip}_$_rawPrinterPort',
        name: 'Network Printer $ip',
        configuration: PrinterConfigurationModel(
          connectionType: PrinterConnectionType.wifi,
          type: PrinterType.thermal,
          ipAddress: ip,
          port: _rawPrinterPort,
          discoveryMethod: 'network',
        ),
        capabilities: const PrinterCapabilityModel(
          paperWidthMm: 80,
          supports58mm: true,
          supports80mm: true,
          supportsA4: false,
          supportsLetter: false,
          supportsBarcode: true,
          supportsQrCode: true,
          supportsCashDrawerKick: true,
          supportsLogo: true,
          supportsImage: true,
          supportsPdf: false,
          supportsAutoCut: true,
        ),
      );
    } catch (_) {
      socket?.destroy();
      return null;
    }
  }

  @override
  Future<bool> isReachable(String ip, int port) async {
    Socket? socket;
    try {
      socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 2),
      );
      socket.destroy();
      return true;
    } catch (_) {
      socket?.destroy();
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
      _printer!.rawBytes(bytes);
      return true;
    } catch (e) {
      throw PrinterPrintingException('Wi-Fi printing failed.', cause: e);
    }
  }

  @override
  Future<bool> testConnection(String ip, int port) => isReachable(ip, port);

  @override
  Future<bool> isConnected() async => _connected && _printer != null;
}
