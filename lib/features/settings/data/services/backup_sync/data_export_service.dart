// lib/features/settings/data/services/backup_sync/data_export_service.dart

import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

class DataExportService {
  Future<String> exportAsCsv() async {
    final List<List<dynamic>> rows = [
      ['Table', 'Status'],
      ['products', 'Remote API export pending'],
      ['suppliers', 'Remote API export pending'],
      ['customers', 'Remote API export pending'],
      ['sales', 'Remote API export pending'],
      ['invoices', 'Remote API export pending'],
    ];

    final csv = const ListToCsvConverter().convert(rows);

    final dir = await getApplicationDocumentsDirectory();

    final fileName =
        'catalystack_export_${DateTime.now().millisecondsSinceEpoch}.csv';

    final file = File('${dir.path}/$fileName');

    await file.writeAsString(csv);

    return file.path;
  }
}