import '../../../../domain/entities/printers_hardware/printer/printer_device.dart';
import '../../../../domain/entities/printers_hardware/printer/printer_configuration.dart';
import '../../../../domain/entities/printers_hardware/printer/printer_capability.dart';
import 'printer_capability_model.dart';
import 'printer_configuration_model.dart';

class PrinterDeviceModel extends PrinterDevice {
  const PrinterDeviceModel({
    required super.id,
    required super.name,
    required super.configuration,
    required super.capabilities,
  });

  factory PrinterDeviceModel.fromEntity(PrinterDevice entity) {
    return PrinterDeviceModel(
      id: entity.id,
      name: entity.name,
      configuration: PrinterConfigurationModel.fromEntity(entity.configuration),
      capabilities: PrinterCapabilityModel.fromEntity(entity.capabilities),
    );
  }

  factory PrinterDeviceModel.fromJson(Map<String, dynamic> json) {
    final configJson = json['configuration'] as Map<String, dynamic>?;
    final capJson = json['capabilities'] as Map<String, dynamic>?;

    if (configJson == null) {
      throw const FormatException('PrinterDevice requires a configuration.');
    }
    if (capJson == null) {
      throw const FormatException('PrinterDevice requires capabilities.');
    }

    return PrinterDeviceModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Printer',
      configuration: PrinterConfigurationModel.fromJson(configJson),
      capabilities: PrinterCapabilityModel.fromJson(capJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'configuration': PrinterConfigurationModel.fromEntity(configuration).toJson(),
      'capabilities': PrinterCapabilityModel.fromEntity(capabilities).toJson(),
    };
  }

  @override
  PrinterDeviceModel copyWith({
    String? id,
    String? name,
    PrinterConfiguration? configuration,
    PrinterCapability? capabilities,
  }) {
    return PrinterDeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      configuration: configuration ?? this.configuration,
      capabilities: capabilities ?? this.capabilities,
    );
  }

  PrinterDevice toEntity() => this;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrinterDeviceModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          configuration == other.configuration &&
          capabilities == other.capabilities;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      configuration.hashCode ^
      capabilities.hashCode;
}