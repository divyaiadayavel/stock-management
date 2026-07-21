// lib/features/settings/data/services/backup_sync/data_export_service.dart
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
// import your DBHelper here, e.g.:
// import '../../../../../core/database/db_helper.dart';

class DataExportService {
  Future<String> exportAsCsv() async {
    // Replace this with your real DBHelper queries, one section per table:
    // final products = await DBHelper.getAllProducts();
    // final suppliers = await DBHelper.getAllSuppliers();
    final List<List<dynamic>> rows = [
      ['Table', 'Placeholder'],
      ['products', 'wire up DBHelper.getAllProducts() here'],
    ];

    final csv = ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'catalystack_export_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csv);
    return file.path;
  }
}
