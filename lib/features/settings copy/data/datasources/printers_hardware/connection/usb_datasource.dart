import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_usb_printer/flutter_usb_printer.dart';

import '../../../../../../core/errors/printer_connection_exception.dart';
import '../../../../../../core/errors/printer_printing_exception.dart';

/// Typed replacement for the raw `Map<String, dynamic>` scan result
/// (Issue 6).
class UsbPrinterInfo {
  final int vendorId;
  final int productId;
  final String name;
  final String manufacturer;

  const UsbPrinterInfo({
    required this.vendorId,
    required this.productId,
    required this.name,
    required this.manufacturer,
  });

  /// Stable-enough identity for a scan slot. `index` disambiguates two
  /// identical printers (same vendor/product) connected at once — there's
  /// no serial number exposed by flutter_usb_printer (Issue 8).
  String idAt(int index) => '${vendorId}_${productId}_$index';

  bool get isValid => vendorId > 0 && productId > 0;

  factory UsbPrinterInfo.fromMap(Map<String, dynamic> map) {
    final rawName = (map['name'] as String?)?.trim();
    final rawManufacturer = (map['manufacturer'] as String?)?.trim();
    return UsbPrinterInfo(
      vendorId: int.tryParse('${map['vendorId']}') ?? 0,
      productId: int.tryParse('${map['productId']}') ?? 0,
      name: (rawName != null && rawName.isNotEmpty) ? rawName : 'USB Printer',
      // Issue 7: fallback for printers that return null manufacturer.
      manufacturer: (rawManufacturer != null && rawManufacturer.isNotEmpty)
          ? rawManufacturer
          : 'Unknown Manufacturer',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UsbPrinterInfo &&
      other.vendorId == vendorId &&
      other.productId == productId;

  @override
  int get hashCode => Object.hash(vendorId, productId);
}

enum UsbConnectionStatus {
  disconnected,
  connecting,
  connected,
  permissionDenied,
  deviceNotFound, // saved printer wasn't found on last scan
}

class UsbConnectionState {
  final UsbConnectionStatus status;
  final UsbPrinterInfo? device;
  final String? message;

  const UsbConnectionState({
    required this.status,
    this.device,
    this.message,
  });

  const UsbConnectionState.idle()
      : status = UsbConnectionStatus.disconnected,
        device = null,
        message = null;
}

abstract class UsbDataSource {
  /// Live connection state — repository/UI subscribes instead of polling.
  Stream<UsbConnectionState> get connectionState;

  Future<List<UsbPrinterInfo>> getUsbDevices();

  /// Connects using a device from the most recent [getUsbDevices] scan.
  /// [retryOnPermissionDenied] retries once — covers the common case where
  /// Android's USB permission dialog was dismissed/delayed on the first
  /// attempt (Issue 9).
  Future<bool> connect(
    int vendorId,
    int productId, {
    bool retryOnPermissionDenied = true,
  });

  /// Reconnects to a previously saved printer. Re-scans first and returns
  /// false (emitting [UsbConnectionStatus.deviceNotFound]) if it isn't
  /// present, instead of throwing (Issues 4 & 5).
  Future<bool> connectSaved(int vendorId, int productId);

  Future<bool> printBytes(List<int> bytes);
  Future<void> disconnect();
  Future<bool> isConnected();
  void dispose();
}

/// USB ESC/POS printing via [FlutterUsbPrinter] (Android only — USB host
/// mode isn't available on iOS).
class UsbDataSourceImpl implements UsbDataSource {
  final FlutterUsbPrinter _printer = FlutterUsbPrinter();

  final _stateController = StreamController<UsbConnectionState>.broadcast();

  // Issue 10: cache the last scan so connect() doesn't need to rescan.
  List<UsbPrinterInfo> _lastScan = [];
  bool _connected = false;

  @override
  Stream<UsbConnectionState> get connectionState => _stateController.stream;

  void _emit(UsbConnectionState state) {
    if (!_stateController.isClosed) _stateController.add(state);
  }

  @override
  Future<List<UsbPrinterInfo>> getUsbDevices() async {
    if (!Platform.isAndroid) return [];
    try {
      final devices = await FlutterUsbPrinter.getUSBDeviceList();
      final parsed = devices
          .map((d) => UsbPrinterInfo.fromMap(Map<String, dynamic>.from(d)))
          // Issue 3 / partial Issue 12: drop entries with no usable
          // vendor/product id. Full "printer vs. keyboard/mouse" filtering
          // needs the Android USB device class, which flutter_usb_printer
          // doesn't expose to Dart — this is the validation possible here.
          .where((d) => d.isValid)
          .toList();

      _lastScan = parsed;
      return parsed;
    } catch (e) {
      throw PrinterConnectionException('Failed to list USB devices.',
          cause: e);
    }
  }

  @override
  Future<bool> connect(
    int vendorId,
    int productId, {
    bool retryOnPermissionDenied = true,
  }) async {
    _emit(UsbConnectionState(
      status: UsbConnectionStatus.connecting,
      device: _deviceFromCache(vendorId, productId),
    ));

    if (await _attemptConnect(vendorId, productId)) return true;

    if (retryOnPermissionDenied &&
        await _attemptConnect(vendorId, productId)) {
      return true;
    }

    _emit(UsbConnectionState(
      status: UsbConnectionStatus.permissionDenied,
      device: _deviceFromCache(vendorId, productId),
      message: 'USB permission denied, or the printer is disconnected.',
    ));
    throw const PrinterConnectionException(
        'USB permission denied, or the printer is no longer connected.');
  }

  Future<bool> _attemptConnect(int vendorId, int productId) async {
    try {
      final granted = await _printer.connect(vendorId, productId);
      _connected = granted ?? false;
      if (_connected) {
        _emit(UsbConnectionState(
          status: UsbConnectionStatus.connected,
          device: _deviceFromCache(vendorId, productId),
        ));
      }
      return _connected;
    } catch (_) {
      _connected = false;
      return false;
    }
  }

  @override
  Future<bool> connectSaved(int vendorId, int productId) async {
    final devices = await getUsbDevices();
    final found = devices
        .any((d) => d.vendorId == vendorId && d.productId == productId);

    if (!found) {
      _emit(UsbConnectionState(
        status: UsbConnectionStatus.deviceNotFound,
        message: 'Saved printer not found on USB scan.',
      ));
      return false;
    }

    try {
      return await connect(vendorId, productId);
    } on PrinterConnectionException {
      return false;
    }
  }

  UsbPrinterInfo? _deviceFromCache(int vendorId, int productId) {
    for (final d in _lastScan) {
      if (d.vendorId == vendorId && d.productId == productId) return d;
    }
    return null;
  }

  @override
  Future<bool> printBytes(List<int> bytes) async {
    if (!_connected) {
      throw const PrinterConnectionException('USB printer is not connected.');
    }
    if (bytes.isEmpty) {
      throw const PrinterPrintingException('Cannot print empty data.');
    }
    try {
      final result = await _printer.write(Uint8List.fromList(bytes));
      return result ?? false;
    } catch (e) {
      throw PrinterPrintingException('Failed to print via USB.', cause: e);
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _printer.close();
    } catch (_) {}
    _connected = false;
    _emit(const UsbConnectionState.idle());
  }

  @override
  Future<bool> isConnected() async {
    try {
      return await _printer.isConnected();
    } catch (_) {
      return _connected;
    }
  }

  @override
  void dispose() {
    _stateController.close();
  }
}