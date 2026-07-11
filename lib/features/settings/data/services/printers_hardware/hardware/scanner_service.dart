import '../../../../data/datasources/printers_hardware/hardware/scanner_datasource.dart';

class ScannerService {
  final ScannerDataSource datasource;

  ScannerService(this.datasource);

  Stream<String> get barcodeStream => datasource.barcodeStream;

  void start() {
    datasource.startListening();
  }

  void stop() {
    datasource.stopListening();
  }

  void dispose() {
    datasource.dispose();
  }
}