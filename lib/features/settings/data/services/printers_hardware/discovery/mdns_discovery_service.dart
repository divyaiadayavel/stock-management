import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:multicast_dns/multicast_dns.dart';

import '../../../../domain/enums/printers_hardware/printer/printer_vendor.dart';
import '../../../../domain/enums/printers_hardware/printer/printer_type.dart';
import '../../../../domain/enums/printers_hardware/printer/printer_connection_type.dart';
import '../../../models/printers_hardware/printer/printer_device_model.dart';
import '../../../models/printers_hardware/printer/printer_configuration_model.dart';
import '../../../models/printers_hardware/printer/printer_capability_model.dart';

class MdnsDiscoveryService {
  MDnsClient? _client;
  bool _isScanning = false;
  Completer<void>? _stopCompleter;

  static const Duration _defaultTimeout = Duration(seconds: 5);

  Future<List<PrinterDeviceModel>> scanPrinters({
    Duration timeout = _defaultTimeout,
    CancellationToken? cancelToken,
  }) async {
    if (_isScanning) return [];

    _isScanning = true;
    _stopCompleter = Completer<void>();

    _client = MDnsClient();
    final List<PrinterDeviceModel> discovered = [];

    try {
      await _client!.start();

      const serviceTypes = [
        '_ipp._tcp.local.',
        '_ipps._tcp.local.',
        '_printer._tcp.local.',
        '_pdl-datastream._tcp.local.',
      ];

      for (final serviceType in serviceTypes) {
        if (cancelToken?.isCancelled == true) break;
        final results = await _scanService(
          _client!,
          serviceType,
          timeout: timeout,
          cancelToken: cancelToken,
        );
        discovered.addAll(results);
      }

      final reachable = <PrinterDeviceModel>[];
      for (final printer in discovered) {
        if (cancelToken?.isCancelled == true) break;
        final ip = printer.configuration.ipAddress;
        final port = printer.configuration.port;
        if (ip != null && port != null) {
          final isReachable = await _isReachable(ip, port, timeout: timeout);
          if (isReachable) reachable.add(printer);
        }
      }

      return _deduplicate(reachable);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('MdnsDiscoveryService: scan error - $e\n$stackTrace');
      }
      return [];
    } finally {
      try {
        _client?.stop();
      } catch (_) {}
      _client = null;
      _isScanning = false;
      _stopCompleter?.complete();
      _stopCompleter = null;
    }
  }

  Future<void> stopScan() async {
    if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
      _stopCompleter!.complete();
    }
    try {
      _client?.stop();
    } catch (_) {}
    _client = null;
    _isScanning = false;
  }

  Future<bool> _isReachable(String ip, int port, {required Duration timeout}) async {
    Socket? socket;
    try {
      socket = await Socket.connect(ip, port, timeout: timeout);
      await socket.close();
      socket.destroy();
      return true;
    } catch (_) {
      socket?.destroy();
      return false;
    }
  }

  Future<List<PrinterDeviceModel>> _scanService(
    MDnsClient client,
    String serviceType, {
    required Duration timeout,
    CancellationToken? cancelToken,
  }) async {
    final results = <PrinterDeviceModel>[];

    try {
      final ptrRecords = await client
          .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(serviceType))
          .toList()
          .timeout(timeout, onTimeout: () => []);

      if (cancelToken?.isCancelled == true) return [];

      for (final ptr in ptrRecords) {
        if (cancelToken?.isCancelled == true) break;
        final instanceName = ptr.domainName;
        try {
          final printer = await _resolvePrinter(
            client,
            instanceName,
            timeout: timeout,
            cancelToken: cancelToken,
          );
          if (printer != null) results.add(printer);
        } catch (e, stackTrace) {
          if (kDebugMode) {
            debugPrint('MdnsDiscoveryService: error resolving $instanceName - $e\n$stackTrace');
          }
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('MdnsDiscoveryService: error scanning $serviceType - $e\n$stackTrace');
      }
    }

    return results;
  }

  Future<PrinterDeviceModel?> _resolvePrinter(
    MDnsClient client,
    String instanceName, {
    required Duration timeout,
    CancellationToken? cancelToken,
  }) async {
    try {
      final srvRecords = await client
          .lookup<SrvResourceRecord>(ResourceRecordQuery.service(instanceName))
          .toList()
          .timeout(timeout, onTimeout: () => []);
      if (srvRecords.isEmpty) return null;

      final srv = srvRecords.first;
      final port = srv.port;
      final hostname = srv.target;

      final ipAddress = await _resolveHostname(
        client,
        hostname,
        timeout: timeout,
        cancelToken: cancelToken,
      );
      if (ipAddress == null) return null;

      String txtData = '';
      try {
        final txtRecords = await client
            .lookup<TxtResourceRecord>(ResourceRecordQuery.text(instanceName))
            .toList()
            .timeout(timeout, onTimeout: () => []);
        if (txtRecords.isNotEmpty) {
          txtData = txtRecords.first.text;
        }
      } catch (_) {}

      final name = instanceName.split('.').first;
      final vendor = _detectVendor(name, txtData);
      final type = _detectPrinterType(vendor, name, txtData, port);

      final configuration = PrinterConfigurationModel(
        connectionType: PrinterConnectionType.wifi,
        type: type,
        ipAddress: ipAddress,
        port: port,
        macAddress: null,
        vendorId: null,
        productId: null,
        discoveryMethod: 'mdns',
      );

      final capabilities = _createCapabilities(vendor, type, txtData);

      final id = '${vendor.name}_${ipAddress}_$port';

      return PrinterDeviceModel(
        id: id,
        name: name,
        configuration: configuration,
        capabilities: capabilities,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('MdnsDiscoveryService: error resolving $instanceName - $e\n$stackTrace');
      }
      return null;
    }
  }

  Future<String?> _resolveHostname(
    MDnsClient client,
    String hostname, {
    required Duration timeout,
    CancellationToken? cancelToken,
  }) async {
    try {
      final aRecords = await client
          .lookup<IPAddressResourceRecord>(ResourceRecordQuery.addressIPv4(hostname))
          .toList()
          .timeout(timeout, onTimeout: () => []);
      if (aRecords.isNotEmpty) {
        return aRecords.first.address.address;
      }
    } catch (_) {}

    try {
      final aaaaRecords = await client
          .lookup<IPAddressResourceRecord>(ResourceRecordQuery.addressIPv6(hostname))
          .toList()
          .timeout(timeout, onTimeout: () => []);
      if (aaaaRecords.isNotEmpty) {
        return aaaaRecords.first.address.address;
      }
    } catch (_) {}

    try {
      final addresses = await InternetAddress.lookup(hostname).timeout(timeout);
      if (addresses.isNotEmpty) {
        return addresses.first.address;
      }
    } catch (_) {}

    return null;
  }

  PrinterVendor _detectVendor(String name, String txtData) {
    final searchString = '${name.toLowerCase()} ${txtData.toLowerCase()}';
    if (searchString.contains('epson')) return PrinterVendor.epson;
    if (searchString.contains('star')) return PrinterVendor.star;
    if (searchString.contains('xprinter')) return PrinterVendor.xprinter;
    if (searchString.contains('hp') || searchString.contains('hewlett')) return PrinterVendor.hp;
    if (searchString.contains('canon')) return PrinterVendor.canon;
    if (searchString.contains('brother')) return PrinterVendor.brother;
    return PrinterVendor.generic;
  }

  PrinterType _detectPrinterType(PrinterVendor vendor, String name, String txtData, int port) {
    final searchString = '${name.toLowerCase()} ${txtData.toLowerCase()}';
    
    if (port == 9100 ||
        searchString.contains('pos') ||
        searchString.contains('thermal') ||
        searchString.contains('receipt') ||
        searchString.contains('escpos') ||
        searchString.contains('esc/pos') ||
        searchString.contains('tm-')) {
      return PrinterType.thermal;
    }
    if (searchString.contains('laserjet') || searchString.contains('officejet') || searchString.contains('pixma')) {
      return PrinterType.document;
    }
    
    if (vendor == PrinterVendor.star || vendor == PrinterVendor.xprinter) {
      return PrinterType.thermal;
    }
    if (vendor == PrinterVendor.hp ||
        vendor == PrinterVendor.canon ||
        vendor == PrinterVendor.brother ||
        vendor == PrinterVendor.epson) {
      return PrinterType.document;
    }
    
    return PrinterType.unknown;
  }

  PrinterCapabilityModel _createCapabilities(PrinterVendor vendor, PrinterType type, String txtData) {
    if (type == PrinterType.thermal) {
      return const PrinterCapabilityModel(
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
      );
    } else if (type == PrinterType.document) {
      return const PrinterCapabilityModel(
        paperWidthMm: 210,
        supports58mm: false,
        supports80mm: false,
        supportsA4: true,
        supportsLetter: true,
        supportsBarcode: false,
        supportsQrCode: false,
        supportsCashDrawerKick: false,
        supportsLogo: false,
        supportsImage: true,
        supportsPdf: true,
        supportsAutoCut: false,
      );
    }
    return const PrinterCapabilityModel();
  }

  List<PrinterDeviceModel> _deduplicate(List<PrinterDeviceModel> printers) {
    final Map<String, PrinterDeviceModel> uniqueMap = {};
    for (final printer in printers) {
      final ip = printer.configuration.ipAddress;
      if (ip != null) {
        uniqueMap[ip] = printer;
      } else {
        uniqueMap[printer.id] = printer;
      }
    }
    return uniqueMap.values.toList();
  }
}

class CancellationToken {
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;
  void cancel() => _isCancelled = true;
}
