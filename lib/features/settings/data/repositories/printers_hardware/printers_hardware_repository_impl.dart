import 'dart:developer' as developer;
import 'dart:io';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../domain/entities/printers_hardware/document/document_print_job.dart';
import '../../../domain/entities/printers_hardware/history/print_history_entry.dart';
import '../../../domain/entities/printers_hardware/printer/printer_device.dart';
import '../../../domain/entities/printers_hardware/printer/printer_settings.dart';
import '../../../domain/entities/printers_hardware/receipt/receipt.dart';
import '../../../domain/enums/printers_hardware/printer/printer_connection_type.dart';
import '../../../domain/enums/printers_hardware/printer/printer_type.dart';
import '../../../domain/repositories/printers_hardware/printers_hardware_repository.dart';
import '../../datasources/printers_hardware/connection/bluetooth_datasource.dart';
import '../../datasources/printers_hardware/connection/usb_datasource.dart';
import '../../datasources/printers_hardware/connection/wifi_datasource.dart';
import '../../datasources/printers_hardware/hardware/cash_drawer_datasource.dart';
import '../../datasources/printers_hardware/storage/printer_local_datasource.dart';
import '../../models/printers_hardware/printer/printer_capability_model.dart';
import '../../models/printers_hardware/printer/printer_configuration_model.dart';
import '../../models/printers_hardware/printer/printer_device_model.dart';
import '../../models/printers_hardware/receipt/receipt_model.dart';
import '../../services/printers_hardware/discovery/mdns_discovery_service.dart';
import '../../services/printers_hardware/printing/document_print_service.dart';
import '../../services/printers_hardware/printing/esc_pos_service.dart';
import '../../services/printers_hardware/printing/receipt_builder.dart';
import '../../services/printers_hardware/printing/receipt_pdf_service.dart';

class PrintersHardwareRepositoryImpl implements PrintersHardwareRepository {
  final BluetoothDataSource _bluetoothDataSource;
  final UsbDataSource _usbDataSource;
  final WifiDataSource _wifiDataSource;
  final PrinterLocalDataSource _localDataSource;
  final MdnsDiscoveryService _discoveryService;

  final CashDrawerDataSource _cashDrawerDataSource = CashDrawerDataSourceImpl();
  final DocumentPrintService _documentPrintService = DocumentPrintServiceImpl();
  final EscPosService _escPosService = EscPosService();
  late final ReceiptBuilder _receiptBuilder = ReceiptBuilder(escPos: _escPosService);
  final ReceiptPdfService _receiptPdfService = ReceiptPdfService();

  final List<PrintHistoryEntry> _history = [];
  PrinterSettings _receiptSettings = const PrinterSettings(printerId: '');

  PrintersHardwareRepositoryImpl({
    required BluetoothDataSource bluetoothDataSource,
    required UsbDataSource usbDataSource,
    required WifiDataSource wifiDataSource,
    required PrinterLocalDataSource localDataSource,
    required MdnsDiscoveryService discoveryService,
  })  : _bluetoothDataSource = bluetoothDataSource,
        _usbDataSource = usbDataSource,
        _wifiDataSource = wifiDataSource,
        _localDataSource = localDataSource,
        _discoveryService = discoveryService;

  /// Issue 4/etc: expose live USB connection state so the UI can show
  /// "Connecting…" / "Permission denied" / "Reconnect" without polling.
  Stream<UsbConnectionState> get usbConnectionState =>
      _usbDataSource.connectionState;

  // --- Discovery ---

  @override
  Future<List<PrinterDevice>> scanBluetoothPrinters() async {
    final devices = await _bluetoothDataSource.getPairedDevices();
    return devices.map((info) {
      final config = PrinterConfigurationModel(
        connectionType: PrinterConnectionType.bluetooth,
        macAddress: info.macAdress,
      );
      const caps = PrinterCapabilityModel(
        paperWidthMm: 80,
        supportsBarcode: true,
        supportsQrCode: true,
        supportsCashDrawerKick: true,
      );
      return PrinterDeviceModel(
        id: info.macAdress,
        name: info.name.isNotEmpty ? info.name : 'Bluetooth Printer',
        configuration: config,
        capabilities: caps,
      );
    }).toList();
  }

  @override
  Future<List<PrinterDevice>> scanUsbPrinters() async {
    return const [];
  }

  @override
  Future<List<PrinterDevice>> scanWifiPrinters() async {
    final results = await Future.wait<List<PrinterDevice>>([
      _discoveryService.scanPrinters(),
      _wifiDataSource.scanNetwork(),
    ]);

    final seen = <String>{};
    final merged = <PrinterDevice>[];
    for (final printer in [...results[0], ...results[1]]) {
      if (!_isThermalWifiCandidate(printer)) continue;
      final key = printer.configuration.ipAddress ?? printer.id;
      if (seen.add(key)) merged.add(printer);
    }
    return merged;
  }

  bool _isThermalWifiCandidate(PrinterDevice printer) {
    final config = printer.configuration;
    if (config.connectionType != PrinterConnectionType.wifi) return false;
    return config.type == PrinterType.thermal || config.type == PrinterType.unknown;
  }

  // --- Connection ---

  @override
  Future<bool> connectPrinter(PrinterDevice printer) async {
    final config = printer.configuration;
    switch (config.connectionType) {
      case PrinterConnectionType.bluetooth:
        final mac = config.macAddress;
        if (mac == null) return false;
        try {
          return await _bluetoothDataSource.connect(mac);
        } catch (e, st) {
          // Issue 2: log instead of silently swallowing.
          developer.log('Bluetooth connect failed',
              error: e, stackTrace: st, name: 'PrintersHardwareRepository');
          return false;
        }

      case PrinterConnectionType.wifi:
        final ip = config.ipAddress;
        final port = config.port ?? 9100;
        if (ip == null) return false;
        try {
          await _wifiDataSource.connect(ip, port);
          return true;
        } catch (e, st) {
          developer.log('WiFi connect failed to $ip:$port',
              error: e, stackTrace: st, name: 'PrintersHardwareRepository');
          return false;
        }

      case PrinterConnectionType.usb:
        developer.log('USB printer support is temporarily unavailable',
            name: 'PrintersHardwareRepository');
        return false;

      case PrinterConnectionType.ethernet:
        return false;

      case PrinterConnectionType.system:
        // OS-managed printers (inkjet/laser via AirPrint/IPP/USB print
        // service) aren't "connected" ahead of time — Android/iOS resolve
        // and pick the target printer in their own dialog at print time.
        return true;
    }
  }

  /// Issue 4 & 5: reconnect to a printer the user previously saved,
  /// tolerating the device being unplugged instead of throwing. For USB
  /// this re-scans first via [UsbDataSource.connectSaved] so an absent
  /// printer resolves to `false` (caller can show "Reconnect") rather than
  /// a raw connection exception.
  ///
  /// Call this at app/session startup with the printer looked up from
  /// [getSavedPrinters].
  Future<bool> connectSavedPrinter(PrinterDevice printer) async {
    if (printer.configuration.connectionType == PrinterConnectionType.usb) {
      return false;
    }
    return connectPrinter(printer);
  }

  @override
  Future<bool> disconnectPrinter() async {
    try {
      await _bluetoothDataSource.disconnect();
    } catch (e, st) {
      developer.log('Bluetooth disconnect error',
          error: e, stackTrace: st, name: 'PrintersHardwareRepository');
    }
    try {
      await _wifiDataSource.disconnect();
    } catch (e, st) {
      developer.log('WiFi disconnect error',
          error: e, stackTrace: st, name: 'PrintersHardwareRepository');
    }
    try {
      await _usbDataSource.disconnect();
    } catch (e, st) {
      developer.log('USB disconnect error',
          error: e, stackTrace: st, name: 'PrintersHardwareRepository');
    }
    return true;
  }

  Future<bool> _isPrinterConnected(PrinterDevice printer) async {
    switch (printer.configuration.connectionType) {
      case PrinterConnectionType.bluetooth:
        return await _bluetoothDataSource.isConnected();
      case PrinterConnectionType.wifi:
        return await _wifiDataSource.isConnected();
      case PrinterConnectionType.usb:
        return false;
      case PrinterConnectionType.ethernet:
        return false;
      case PrinterConnectionType.system:
        return true;
    }
  }

  Future<bool> _printBytes(PrinterDevice printer, List<int> bytes) async {
    if (bytes.isEmpty) return false;
    try {
      switch (printer.configuration.connectionType) {
        case PrinterConnectionType.bluetooth:
          if (!await _bluetoothDataSource.isConnected()) {
            final mac = printer.configuration.macAddress;
            if (mac == null) {
              return false;
            }
            final connected = await _bluetoothDataSource.reconnect(mac);
            if (!connected) {
              return false;
            }
          }
          return await _bluetoothDataSource.printBytes(bytes);
        case PrinterConnectionType.wifi:
          return await _wifiDataSource.printBytes(bytes);
        case PrinterConnectionType.usb:
          return false;
        case PrinterConnectionType.ethernet:
        case PrinterConnectionType.system:
          return false;
      }
    } catch (e, st) {
      developer.log('Print failed on ${printer.configuration.connectionType.name}',
          error: e, stackTrace: st, name: 'PrintersHardwareRepository');
      return false;
    }
  }

  // --- Storage ---

  @override
  Future<List<PrinterDevice>> getSavedPrinters() async {
    return await _localDataSource.getSavedPrinters();
  }

  @override
  Future<PrinterDevice?> getDefaultPrinter() async {
    return await _localDataSource.getDefaultPrinter();
  }

  @override
  Future<void> saveDefaultPrinter(PrinterDevice printer) async {
    final model = printer is PrinterDeviceModel
        ? printer
        : PrinterDeviceModel.fromEntity(printer);
    await _localDataSource.savePrinter(model);
    await _localDataSource.setDefaultPrinter(model.id);
  }

  @override
  Future<void> deletePrinter(String printerId) async {
    await _localDataSource.deletePrinter(printerId);
  }

  // --- Printing ---

  @override
  Future<bool> testPrint(PrinterDevice printer) async {
    if (printer.configuration.connectionType == PrinterConnectionType.system) {
      return _printSystemTestPage(printer);
    }
    try {
      final paperSize =
          printer.capabilities.paperWidthMm == 58 ? PaperSize.mm58 : PaperSize.mm80;
      final bytes = <int>[];
      bytes.addAll(await _escPosService.text(
        'Test Print',
        paperSize: paperSize,
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ));
      bytes.addAll(await _escPosService.text(
        DateTime.now().toString(),
        paperSize: paperSize,
        styles: const PosStyles(align: PosAlign.center),
      ));
      bytes.addAll(await _escPosService.feed(paperSize: paperSize, lines: 2));
      bytes.addAll(await _escPosService.cut(paperSize: paperSize));
      return await _printBytes(printer, bytes);
    } catch (e, st) {
      developer.log('Test print failed',
          error: e, stackTrace: st, name: 'PrintersHardwareRepository');
      return false;
    }
  }

  @override
  Future<bool> printReceipt(Receipt receipt, PrinterDevice printer) async {
    if (printer.configuration.connectionType == PrinterConnectionType.system) {
      return _printSystemReceipt(receipt, printer);
    }
    try {
      final receiptModel =
          receipt is ReceiptModel ? receipt : ReceiptModel.fromEntity(receipt);
      final capabilities = printer.capabilities is PrinterCapabilityModel
          ? printer.capabilities as PrinterCapabilityModel
          : PrinterCapabilityModel.fromEntity(printer.capabilities);
      final bytes = await _receiptBuilder.buildReceiptBytes(
        receiptModel,
        capabilities,
      );

      

      if (!await _isPrinterConnected(printer)) {
        final connected = await connectPrinter(printer);
        if (!connected) {
          return false;
        }
      }
      return await _printBytes(printer, bytes);
    } catch (e, st) {
      developer.log('Print receipt failed',
          error: e, stackTrace: st, name: 'PrintersHardwareRepository');
      return false;
    }
  }

  /// Inkjet/laser printers are addressed through the OS print system rather
  /// than a raw socket — Android in particular has no API to silently pick
  /// a specific printer, so [Printing.layoutPdf] opens the native print
  /// dialog for the user to pick their printer (Canon, HP, etc.) and confirm.
  Future<bool> _printSystemReceipt(Receipt receipt, PrinterDevice printer) async {
    try {
      final pdfBytes = await _receiptPdfService.buildReceiptPdf(
        receipt,
        pageFormat: PdfPageFormat.a5,
      );
      return await Printing.layoutPdf(
        name: 'Receipt ${receipt.receiptId}',
        format: PdfPageFormat.a5,
        onLayout: (_) async => pdfBytes,
      );
    } catch (e, st) {
      developer.log('System receipt print failed',
          error: e, stackTrace: st, name: 'PrintersHardwareRepository');
      return false;
    }
  }

  Future<bool> _printSystemTestPage(PrinterDevice printer) async {
    try {
      final pdfBytes = await _receiptPdfService.buildReceiptPdf(
        Receipt(
          receiptId: 'TEST-${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now(),
          cashierName: 'Test',
          items: const [],
          subTotal: 0,
          taxAmount: 0,
          grandTotal: 0,
          footerNote: 'This is a test page from ${printer.name}.',
        ),
        pageFormat: PdfPageFormat.a5,
      );
      return await Printing.layoutPdf(
        name: 'Test Print',
        format: PdfPageFormat.a5,
        onLayout: (_) async => pdfBytes,
      );
    } catch (e, st) {
      developer.log('System test print failed',
          error: e, stackTrace: st, name: 'PrintersHardwareRepository');
      return false;
    }
  }

  @override
  Future<bool> printDocument(DocumentPrintJob job) async {
    try {
      final bytes = await File(job.documentPath).readAsBytes();
      return await _documentPrintService.printPdf(pdfBytes: bytes, jobName: job.title);
    } catch (e, st) {
      developer.log('Print document failed: ${job.documentPath}',
          error: e, stackTrace: st, name: 'PrintersHardwareRepository');
      return false;
    }
  }

  // --- Receipt Settings ---

  @override
  Future<PrinterSettings> getReceiptSettings() async => _receiptSettings;

  @override
  Future<void> saveReceiptSettings(PrinterSettings settings) async {
    _receiptSettings = settings;
  }

  // --- Hardware ---

  @override
  Future<bool> openCashDrawer(PrinterDevice printer) async {
    final bytes = _cashDrawerDataSource.getOpenDrawerBytes();
    return await _printBytes(printer, bytes);
  }

  // --- History ---

  @override
  Future<List<PrintHistoryEntry>> getPrintHistory({int limit = 50}) async {
    final sorted = [..._history]
      ..sort((a, b) =>
          (b.printedAt ?? b.createdAt).compareTo(a.printedAt ?? a.createdAt));
    return sorted.take(limit).toList();
  }

  @override
  Future<bool> clearPrintHistory() async {
    _history.clear();
    return true;
  }

  @override
  Future<void> createPrintHistory({
    required Receipt receipt,
    required PrinterDevice printer,
    required bool success,
    String? errorMessage,
  }) async {
    final now = DateTime.now();
    _history.insert(
      0,
      PrintHistoryEntry(
        id: '${now.microsecondsSinceEpoch}',
        billReference: receipt.receiptId,
        printerId: printer.id,
        printerName: printer.name,
        printedAt: now,
        createdAt: now,
        itemCount: receipt.items.length,
        grandTotal: receipt.grandTotal,
        isSuccess: success,
        errorMessage: errorMessage,
      ),
    );
  }

  // --- Diagnostics ---

  @override
  Future<Map<String, dynamic>> runPrinterDiagnostics(PrinterDevice printer) async {
    final connected = await _isPrinterConnected(printer);
    return {
      'printerId': printer.id,
      'printerName': printer.name,
      'connectionType': printer.configuration.connectionType.name,
      'connected': connected,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
}
