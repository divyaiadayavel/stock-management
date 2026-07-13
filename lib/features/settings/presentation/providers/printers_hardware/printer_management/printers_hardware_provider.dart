import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/printers_hardware/printer/printer_device.dart';
import '../../../../domain/entities/printers_hardware/receipt/receipt.dart';
import '../../../../domain/entities/printers_hardware/receipt/receipt_item.dart';
import '../../../../data/datasources/printers_hardware/connection/bluetooth_datasource.dart';
import '../../../../data/datasources/printers_hardware/connection/wifi_datasource.dart';
import '../../../../data/datasources/printers_hardware/connection/usb_datasource.dart';
import '../../../../data/datasources/printers_hardware/hardware/cash_drawer_datasource.dart';
import '../../../../data/datasources/printers_hardware/storage/printer_local_datasource.dart';
import '../../../../data/models/printers_hardware/printer/printer_device_model.dart';
import '../../../../data/repositories/printers_hardware/printers_hardware_repository_impl.dart';
import '../../../../data/services/printers_hardware/printing/document_print_service.dart';
import '../../../../data/services/printers_hardware/discovery/mdns_discovery_service.dart';
import '../../../../../../core/errors/printer_exception.dart';
import '../../../../../../core/errors/printer_connection_exception.dart';
import '../../../../../../core/errors/printer_timeout_exception.dart';
import '../../../../../../core/errors/printer_permission_exception.dart';
import '../../settings_provider.dart';
import 'printers_hardware_state.dart';

// ── Data-source and Service providers ─────────────────────────────────────

final bluetoothDataSourceProvider = Provider<BluetoothDataSource>(
  (_) => BluetoothDataSourceImpl(),
);

final wifiDataSourceProvider = Provider<WifiDataSource>(
  (_) => WifiDataSourceImpl(),
);

final usbDataSourceProvider = Provider<UsbDataSource>(
  (_) => UsbDataSourceImpl(),
);

final cashDrawerDataSourceProvider = Provider<CashDrawerDataSource>(
  (_) => CashDrawerDataSourceImpl(),
);

final documentPrintServiceProvider = Provider<DocumentPrintService>(
  (_) => DocumentPrintServiceImpl(),
);

final mdnsDiscoveryServiceProvider = Provider<MdnsDiscoveryService>(
  (_) => MdnsDiscoveryService(),
);

// ── Repository provider ──────────────────────────────────────────────────

final printersHardwareRepositoryProvider =
    Provider<PrintersHardwareRepositoryImpl>((ref) {
  return PrintersHardwareRepositoryImpl(
    bluetoothDataSource: ref.read(bluetoothDataSourceProvider),
    wifiDataSource: ref.read(wifiDataSourceProvider),
    usbDataSource: ref.read(usbDataSourceProvider),
    localDataSource: _NoOpLocalDataSource(),
    discoveryService: ref.read(mdnsDiscoveryServiceProvider),
  );
});

// ── Notifier ────────────────────────────────────────────────────────────

class PrintersHardwareNotifier
    extends AutoDisposeNotifier<PrintersHardwareState> {
  @override
  PrintersHardwareState build() {
    _loadDefaultPrinter();
    return const PrintersHardwareState();
  }

  PrintersHardwareRepositoryImpl get _repo =>
      ref.read(printersHardwareRepositoryProvider);

  /// Loads the saved printer list from the server and sets the default one.
  Future<void> _loadDefaultPrinter() async {
    try {
      final printers = await _repo.getSavedPrinters();
      if (printers.isEmpty) return;

      state = state.copyWith(
        savedPrinters: printers,
        connectedPrinter: printers.first,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: _messageFromError(e));
    }
  }

  /// Public entry point for other features (e.g. Sales) that just need "the
  /// printer to print on" without knowing anything about Bluetooth/WiFi/USB
  /// or how/when the default printer gets loaded.
  ///
  /// Because this provider is `autoDispose`, [connectedPrinter] may not be
  /// populated yet if no Settings screen has been opened this session (the
  /// async load in [_loadDefaultPrinter] hasn't resolved, or was torn down).
  /// This re-checks the saved-printers list on demand and returns null only
  /// if the user genuinely has no printer configured.
  Future<PrinterDevice?> ensureDefaultPrinterLoaded() async {
    if (state.connectedPrinter != null) return state.connectedPrinter;
    try {
      final printers = await _repo.getSavedPrinters();
      if (printers.isEmpty) return null;
      final defaultPrinter = printers.first;
      state = state.copyWith(
        savedPrinters: printers,
        connectedPrinter: defaultPrinter,
      );
      return defaultPrinter;
    } catch (e) {
      state = state.copyWith(errorMessage: _messageFromError(e));
      return null;
    }
  }

  Future<void> refreshSavedPrinters() async {
    try {
      final printers = await _repo.getSavedPrinters();
      state = state.copyWith(
        savedPrinters: printers,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to load saved printers: ${_messageFromError(e)}',
      );
    }
  }

  /// Connects to the given printer and saves it as default on the server.
  Future<bool> connectToPrinter(PrinterDevice printer) async {
    state = state.copyWith(isConnecting: true, clearError: true);
    try {
      final ok = await _repo.connectPrinter(printer);
      if (!ok) {
        state = state.copyWith(
            errorMessage: 'Failed to connect.', isConnecting: false);
        return false;
      }

      state = state.copyWith(connectedPrinter: printer, isConnecting: false);

      await _repo.saveDefaultPrinter(printer);
      await refreshSavedPrinters();

      return true;
    } on PrinterPermissionException catch (e) {
      state = state.copyWith(errorMessage: e.message, isConnecting: false);
      return false;
    } on PrinterTimeoutException catch (e) {
      state = state.copyWith(errorMessage: e.message, isConnecting: false);
      return false;
    } on PrinterConnectionException catch (e) {
      state = state.copyWith(errorMessage: e.message, isConnecting: false);
      return false;
    } on PrinterException catch (e) {
      state = state.copyWith(errorMessage: e.message, isConnecting: false);
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isConnecting: false);
      return false;
    }
  }

  /// Disconnects the currently connected printer.
  Future<void> disconnect() async {
    try {
      await _repo.disconnectPrinter();
      state = const PrintersHardwareState();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Disconnect failed: $e');
    }
  }

  /// Removes a saved printer from the server's list.
  Future<bool> removePrinter(String printerId) async {
    try {
      await _repo.deletePrinter(printerId);
      if (state.connectedPrinter?.id == printerId) {
        state = const PrintersHardwareState();
      }
      await refreshSavedPrinters();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to remove printer: ${_messageFromError(e)}',
      );
      return false;
    }
  }

  /// Prints a receipt through the currently connected printer.
  Future<bool> printReceipt(Receipt receipt, {bool isTestPrint = false}) async {
    final printer = state.connectedPrinter;
    if (printer == null) {
      state = state.copyWith(errorMessage: 'No printer connected.');
      return false;
    }

    state = state.copyWith(isPrinting: true, clearError: true);

    bool ok = false;
    String? failureReason;
    try {
      ok = await _repo.printReceipt(receipt, printer);
    } on PrinterException catch (e) {
      failureReason = e.message;
      ok = false;
    } catch (e) {
      failureReason = _messageFromError(e);
      ok = false;
    }

    state = ok
        ? state.copyWith(isPrinting: false, clearError: true)
        : state.copyWith(
            isPrinting: false,
            errorMessage: failureReason ?? 'Print failed.',
          );

    await _logPrintAttempt(
      receipt: receipt,
      printer: printer,
      success: ok,
      isTestPrint: isTestPrint,
      errorMessage: failureReason,
    );

    return ok;
  }

  /// Builds a sample receipt for test printing.
  Future<bool> printTestReceipt() async {
    if (state.connectedPrinter == null) {
      state = state.copyWith(errorMessage: 'No printer connected.');
      return false;
    }
    final receipt = _buildSampleBill();
    return printReceipt(receipt, isTestPrint: true);
  }

  Receipt _buildSampleBill() {
    final profile = ref.read(settingsControllerProvider).valueOrNull?.profile;

    final now = DateTime.now();
    final items = [
      const ReceiptItem(
        itemName: 'Basmati Rice 5kg',
        quantity: 2,
        unitPrice: 420.00,
        totalAmount: 840.00,
      ),
      const ReceiptItem(
        itemName: 'Sunflower Oil 1L',
        quantity: 1,
        unitPrice: 165.00,
        totalAmount: 165.00,
      ),
      const ReceiptItem(
        itemName: 'Toor Dal 1kg',
        quantity: 3,
        unitPrice: 130.00,
        totalAmount: 390.00,
      ),
      const ReceiptItem(
        itemName: 'Tea Powder 250g',
        quantity: 1,
        unitPrice: 95.00,
        totalAmount: 95.00,
      ),
      const ReceiptItem(
        itemName: 'Bath Soap (Pack of 4)',
        quantity: 2,
        unitPrice: 110.00,
        totalAmount: 220.00,
      ),
    ];

    final subTotal = items.fold<double>(0, (sum, i) => sum + i.totalAmount);
    final taxAmount = double.parse((subTotal * 0.05).toStringAsFixed(2));
    final grandTotal = double.parse((subTotal + taxAmount).toStringAsFixed(2));

    return Receipt(
      receiptId: 'TEST-${now.millisecondsSinceEpoch}',
      timestamp: now,
      cashierName: 'Test Cashier',
      items: items,
      subTotal: subTotal,
      taxAmount: taxAmount,
      grandTotal: grandTotal,
      storeName: (profile?.storeName.trim().isNotEmpty ?? false)
          ? profile!.storeName.trim()
          : 'Catalystack Store',
      storeAddress: (profile?.businessAddress.trim().isNotEmpty ?? false)
          ? profile!.businessAddress.trim()
          : null,
      storePhone: (profile?.phoneNumber.trim().isNotEmpty ?? false)
          ? profile!.phoneNumber.trim()
          : null,
      gstNumber: (profile?.gstNumber.trim().isNotEmpty ?? false)
          ? profile!.gstNumber.trim()
          : null,
      footerNote: 'This is a TEST PRINT - not a real sale.',
    );
  }

  Future<void> _logPrintAttempt({
    required Receipt receipt,
    required PrinterDevice printer,
    required bool success,
    required bool isTestPrint,
    String? errorMessage,
  }) async {
    try {
      await _repo.createPrintHistory(
        receipt: receipt,
        printer: printer,
        success: success,
        errorMessage: errorMessage,
      );
    } catch (_) {
      // best‑effort fallback
    }
  }

  Future<void> kickCashDrawer() async {
    if (state.connectedPrinter == null) return;
    try {
      await _repo.openCashDrawer(state.connectedPrinter!);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Cash drawer error: $e');
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  String _messageFromError(Object error) {
    if (error is PrinterException) return error.message;
    return error.toString().replaceFirst('Exception: ', '');
  }
}

final printersHardwareProvider = NotifierProvider.autoDispose<
    PrintersHardwareNotifier, PrintersHardwareState>(
  PrintersHardwareNotifier.new,
);

// ── In-memory local datasource ──────────────────────────────────────────
//
// Printers are kept in memory only for now; no local persistence layer is
// wired up for this build.

class _NoOpLocalDataSource implements PrinterLocalDataSource {
  final List<PrinterDeviceModel> _printers = [];
  String? _defaultPrinterId;

  @override
  Future<void> savePrinter(PrinterDeviceModel printer) async {
    _printers.removeWhere((p) => p.id == printer.id);
    _printers.add(printer);
  }

  @override
  Future<List<PrinterDeviceModel>> getSavedPrinters() async =>
      List.unmodifiable(_printers);

  @override
  Future<PrinterDeviceModel?> getDefaultPrinter() async {
    if (_defaultPrinterId == null) return null;
    for (final printer in _printers) {
      if (printer.id == _defaultPrinterId) return printer;
    }
    return null;
  }

  @override
  Future<void> deletePrinter(String printerId) async {
    _printers.removeWhere((p) => p.id == printerId);
    if (_defaultPrinterId == printerId) _defaultPrinterId = null;
  }

  @override
  Future<void> setDefaultPrinter(String printerId) async {
    _defaultPrinterId = printerId;
  }

  @override
  Future<void> clearAllPrinters() async {
    _printers.clear();
    _defaultPrinterId = null;
  }
}