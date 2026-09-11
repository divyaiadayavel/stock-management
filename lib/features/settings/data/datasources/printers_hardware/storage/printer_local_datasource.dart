// ============================================================
// lib/features/settings/data/datasources/printers_hardware/storage/
// printer_local_datasource.dart
// ============================================================


import '../../..../../../models/printers_hardware/printer/printer_device_model.dart';

abstract class PrinterLocalDataSource {
  /// Save a printer.
  Future<void> savePrinter(PrinterDeviceModel printer);

  /// Get all saved printers.
  Future<List<PrinterDeviceModel>> getSavedPrinters();

  /// Get the default printer.
  Future<PrinterDeviceModel?> getDefaultPrinter();

  /// Delete one saved printer.
  Future<void> deletePrinter(String printerId);

  /// Mark one printer as default.
  Future<void> setDefaultPrinter(String printerId);

  /// Remove all saved printers.
  Future<void> clearAllPrinters();
}


/// ============================================================
/// In-memory printer datasource
///
/// IMPORTANT:

///
/// Persistent printer configuration is handled by the backend.
/// This class only maintains the printer state required during
/// the current application session.
/// ============================================================

class PrinterLocalDataSourceImpl
    implements PrinterLocalDataSource {
  final Map<String, PrinterDeviceModel> _printers = {};

  String? _defaultPrinterId;

  @override
  Future<void> savePrinter(
    PrinterDeviceModel printer,
  ) async {
    _printers[printer.id] = printer;

    // First saved printer becomes default automatically.
    _defaultPrinterId ??= printer.id;
  }

  @override
  Future<List<PrinterDeviceModel>> getSavedPrinters() async {
    final printers = _printers.values.toList();

    printers.sort((a, b) {
      if (a.id == _defaultPrinterId) return -1;
      if (b.id == _defaultPrinterId) return 1;

      return a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          );
    });

    return List.unmodifiable(printers);
  }

  @override
  Future<PrinterDeviceModel?> getDefaultPrinter() async {
    final id = _defaultPrinterId;

    if (id == null) {
      return null;
    }

    return _printers[id];
  }

  @override
  Future<void> deletePrinter(
    String printerId,
  ) async {
    _printers.remove(printerId);

    if (_defaultPrinterId == printerId) {
      _defaultPrinterId =
          _printers.isEmpty ? null : _printers.keys.first;
    }
  }

  @override
  Future<void> setDefaultPrinter(
    String printerId,
  ) async {
    if (!_printers.containsKey(printerId)) {
      return;
    }

    _defaultPrinterId = printerId;
  }

  @override
  Future<void> clearAllPrinters() async {
    _printers.clear();
    _defaultPrinterId = null;
  }
}