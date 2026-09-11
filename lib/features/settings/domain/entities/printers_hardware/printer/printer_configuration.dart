import '../../../enums/printers_hardware/printer/printer_connection_type.dart';
import '../../../enums/printers_hardware/printer/printer_type.dart';

class PrinterConfiguration {
  final PrinterConnectionType connectionType;
  final PrinterType type;
  final String? macAddress;
  final String? ipAddress;
  final int? port;
  final int? vendorId;
  final int? productId;
  final String? discoveryMethod;

  const PrinterConfiguration({
    required this.connectionType,
    this.type = PrinterType.thermal,
    this.macAddress,
    this.ipAddress,
    this.port,
    this.vendorId,
    this.productId,
    this.discoveryMethod,
  });

  PrinterConfiguration copyWith({
    PrinterConnectionType? connectionType,
    PrinterType? type,
    String? macAddress,
    String? ipAddress,
    int? port,
    int? vendorId,
    int? productId,
    String? discoveryMethod,
  }) {
    return PrinterConfiguration(
      connectionType: connectionType ?? this.connectionType,
      type: type ?? this.type,
      macAddress: macAddress ?? this.macAddress,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      vendorId: vendorId ?? this.vendorId,
      productId: productId ?? this.productId,
      discoveryMethod: discoveryMethod ?? this.discoveryMethod,
    );
  }
}
