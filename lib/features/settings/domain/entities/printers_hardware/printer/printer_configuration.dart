import '../../../enums/printers_hardware/printer/printer_connection_type.dart';

class PrinterConfiguration {
  final PrinterConnectionType connectionType;
  final String? macAddress;
  final String? ipAddress;
  final int? port;
  final int? vendorId;
  final int? productId;

  const PrinterConfiguration({
    required this.connectionType,
    this.macAddress,
    this.ipAddress,
    this.port,
    this.vendorId,
    this.productId,
  });

  PrinterConfiguration copyWith({
    PrinterConnectionType? connectionType,
    String? macAddress,
    String? ipAddress,
    int? port,
    int? vendorId,
    int? productId,
  }) {
    return PrinterConfiguration(
      connectionType: connectionType ?? this.connectionType,
      macAddress: macAddress ?? this.macAddress,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      vendorId: vendorId ?? this.vendorId,
      productId: productId ?? this.productId,
    );
  }
}