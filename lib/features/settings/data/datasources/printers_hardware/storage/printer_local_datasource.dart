import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import '../../../models/printers_hardware/printer/printer_device_model.dart';
import '../../../models/printers_hardware/printer/printer_configuration_model.dart';
import '../../../models/printers_hardware/printer/printer_capability_model.dart';
 // adjust to actual path

abstract class PrinterLocalDataSource {
  /// Save a printer (insert or update if exists).
  Future<void> savePrinter(PrinterDeviceModel printer);

  /// Get all saved printers.
  Future<List<PrinterDeviceModel>> getSavedPrinters();

  /// Get the default printer (the one marked as default).
  Future<PrinterDeviceModel?> getDefaultPrinter();

  /// Remove a single saved printer.
  Future<void> deletePrinter(String printerId);

  /// Mark the given printer as the default one.
  Future<void> setDefaultPrinter(String printerId);

  /// Clear all saved printers.
  Future<void> clearAllPrinters();
}

class PrinterLocalDataSourceImpl implements PrinterLocalDataSource {
  final Database database;

  PrinterLocalDataSourceImpl({required this.database});

  @override
  Future<void> savePrinter(PrinterDeviceModel printer) async {
    await database.insert(
      'printers',
      {
        'id': printer.id,
        'name': printer.name,
        'configuration': jsonEncode(
          PrinterConfigurationModel.fromEntity(printer.configuration).toJson(),
        ),
        'capabilities': jsonEncode(
          PrinterCapabilityModel.fromEntity(printer.capabilities).toJson(),
        ),
        'isDefault': 0, // we'll handle default separately
        'lastConnected': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<PrinterDeviceModel>> getSavedPrinters() async {
    final List<Map<String, dynamic>> maps = await database.query('printers');
    return maps.map((map) {
      final configJson = jsonDecode(map['configuration'] as String);
      final capJson = jsonDecode(map['capabilities'] as String);
      return PrinterDeviceModel(
        id: map['id'] as String,
        name: map['name'] as String,
        configuration: PrinterConfigurationModel.fromJson(configJson),
        capabilities: PrinterCapabilityModel.fromJson(capJson),
      );
    }).toList();
  }

  @override
  Future<PrinterDeviceModel?> getDefaultPrinter() async {
    final maps = await database.query(
      'printers',
      where: 'isDefault = 1',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final map = maps.first;
    final configJson = jsonDecode(map['configuration'] as String);
    final capJson = jsonDecode(map['capabilities'] as String);
    return PrinterDeviceModel(
      id: map['id'] as String,
      name: map['name'] as String,
      configuration: PrinterConfigurationModel.fromJson(configJson),
      capabilities: PrinterCapabilityModel.fromJson(capJson),
    );
  }

  @override
  Future<void> deletePrinter(String printerId) async {
    await database.delete('printers', where: 'id = ?', whereArgs: [printerId]);
  }

  @override
  Future<void> setDefaultPrinter(String printerId) async {
    await database.transaction((txn) async {
      await txn.update('printers', {'isDefault': 0});
      await txn.update(
        'printers',
        {'isDefault': 1},
        where: 'id = ?',
        whereArgs: [printerId],
      );
    });
  }

  @override
  Future<void> clearAllPrinters() async {
    await database.delete('printers');
  }
}