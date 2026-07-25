import '../../../../domain/entities/printers_hardware/printer/printer_configuration.dart';
import '../../../../domain/enums/printers_hardware/printer/printer_connection_type.dart';

class PrinterConfigurationModel extends PrinterConfiguration {
  const PrinterConfigurationModel({
    required super.connectionType,
    super.macAddress,
    super.ipAddress,
    super.port,
    super.vendorId,
    super.productId,
  });

  factory PrinterConfigurationModel.fromEntity(PrinterConfiguration entity) {
    return PrinterConfigurationModel(
      connectionType: entity.connectionType,
      macAddress: entity.macAddress,
      ipAddress: entity.ipAddress,
      port: entity.port,
      vendorId: entity.vendorId,
      productId: entity.productId,
    );
  }

  factory PrinterConfigurationModel.fromJson(Map<String, dynamic> json) {
    return PrinterConfigurationModel(
      connectionType: PrinterConnectionType.values.firstWhere(
        (e) => e.name == json['connectionType'],
        orElse: () => PrinterConnectionType.bluetooth,
      ),
      macAddress: json['macAddress']?.toString().trim(),
      ipAddress: json['ipAddress']?.toString().trim(),
      port: (json['port'] as num?)?.toInt(),
      vendorId: (json['vendorId'] as num?)?.toInt(),
      productId: (json['productId'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'connectionType': connectionType.name,
      'macAddress': macAddress,
      'ipAddress': ipAddress,
      'port': port,
      'vendorId': vendorId,
      'productId': productId,
    };
  }

  @override
  PrinterConfigurationModel copyWith({
    PrinterConnectionType? connectionType,
    String? macAddress,
    String? ipAddress,
    int? port,
    int? vendorId,
    int? productId,
  }) {
    return PrinterConfigurationModel(
      connectionType: connectionType ?? this.connectionType,
      macAddress: macAddress ?? this.macAddress,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      vendorId: vendorId ?? this.vendorId,
      productId: productId ?? this.productId,
    );
  }

  PrinterConfiguration toEntity() => this;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrinterConfigurationModel &&
          runtimeType == other.runtimeType &&
          connectionType == other.connectionType &&
          macAddress == other.macAddress &&
          ipAddress == other.ipAddress &&
          port == other.port &&
          vendorId == other.vendorId &&
          productId == other.productId;

  @override
  int get hashCode =>
      connectionType.hashCode ^
      macAddress.hashCode ^
      ipAddress.hashCode ^
      port.hashCode ^
      vendorId.hashCode ^
      productId.hashCode;
}