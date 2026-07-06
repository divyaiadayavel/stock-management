import 'printer_capability.dart';
import 'printer_configuration.dart';

class PrinterDevice {
  final String id;
  final String name;
  final PrinterConfiguration configuration;
  final PrinterCapability capabilities;

  const PrinterDevice({
    required this.id,
    required this.name,
    required this.configuration,
    required this.capabilities,
  });

  PrinterDevice copyWith({
    String? id,
    String? name,
    PrinterConfiguration? configuration,
    PrinterCapability? capabilities,
  }) {
    return PrinterDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      configuration: configuration ?? this.configuration,
      capabilities: capabilities ?? this.capabilities,
    );
  }
}