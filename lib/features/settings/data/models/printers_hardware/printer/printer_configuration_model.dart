import '../../../../domain/entities/printers_hardware/printer/printer_configuration.dart';
import '../../../../domain/enums/printers_hardware/printer/printer_connection_type.dart';
import '../../../../domain/enums/printers_hardware/printer/printer_type.dart';

class PrinterConfigurationModel extends PrinterConfiguration {
  const PrinterConfigurationModel({
    required super.connectionType,
    super.type = PrinterType.thermal,
    super.macAddress,
    super.ipAddress,
    super.port,
    super.vendorId,
    super.productId,
    super.discoveryMethod,
  });

  factory PrinterConfigurationModel.fromEntity(PrinterConfiguration entity) {
    return PrinterConfigurationModel(
      connectionType: entity.connectionType,
      type: entity.type,
      macAddress: entity.macAddress,
      ipAddress: entity.ipAddress,
      port: entity.port,
      vendorId: entity.vendorId,
      productId: entity.productId,
      discoveryMethod: entity.discoveryMethod,
    );
  }

  factory PrinterConfigurationModel.fromJson(Map<String, dynamic> json) {
    return PrinterConfigurationModel(
      connectionType: PrinterConnectionType.values.firstWhere(
        (e) => e.name == json['connectionType'],
        orElse: () => PrinterConnectionType.bluetooth,
      ),
      type: PrinterType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PrinterType.thermal,
      ),
      macAddress: json['macAddress']?.toString().trim(),
      ipAddress: json['ipAddress']?.toString().trim(),
      port: (json['port'] as num?)?.toInt(),
      vendorId: (json['vendorId'] as num?)?.toInt(),
      productId: (json['productId'] as num?)?.toInt(),
      discoveryMethod: json['discoveryMethod']?.toString().trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'connectionType': connectionType.name,
      'type': type.name,
      'macAddress': macAddress,
      'ipAddress': ipAddress,
      'port': port,
      'vendorId': vendorId,
      'productId': productId,
      'discoveryMethod': discoveryMethod,
    };
  }

  @override
  PrinterConfigurationModel copyWith({
    PrinterConnectionType? connectionType,
    PrinterType? type,
    String? macAddress,
    String? ipAddress,
    int? port,
    int? vendorId,
    int? productId,
    String? discoveryMethod,
  }) {
    return PrinterConfigurationModel(
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

  PrinterConfiguration toEntity() => this;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is PrinterConfigurationModel &&
          runtimeType == other.runtimeType &&
          connectionType == other.connectionType &&
          type == other.type &&
          macAddress == other.macAddress &&
          ipAddress == other.ipAddress &&
          port == other.port &&
          vendorId == other.vendorId &&
          productId == other.productId &&
          discoveryMethod == other.discoveryMethod;

  @override
  int get hashCode =>
      connectionType.hashCode ^
      type.hashCode ^
      macAddress.hashCode ^
      ipAddress.hashCode ^
      port.hashCode ^
      vendorId.hashCode ^
      productId.hashCode ^
      discoveryMethod.hashCode;
}
