import '../../../../domain/entities/printers_hardware/document/document_print_job.dart';
import '../../../../domain/entities/printers_hardware/printer/printer_device.dart';
import '../printer/printer_device_model.dart';

class DocumentPrintJobModel extends DocumentPrintJob {
  const DocumentPrintJobModel({
    required super.id,
    required super.title,
    required super.documentPath,
    required super.printer,
    super.copies = 1,
  });

  factory DocumentPrintJobModel.fromEntity(DocumentPrintJob entity) {
    return DocumentPrintJobModel(
      id: entity.id,
      title: entity.title,
      documentPath: entity.documentPath,
      printer: entity.printer,
      copies: entity.copies,
    );
  }

  factory DocumentPrintJobModel.fromJson(Map<String, dynamic> json) {
    final printerJson = json['printer'] as Map<String, dynamic>?;
    if (printerJson == null) {
      throw const FormatException('DocumentPrintJob requires a printer.');
    }
    return DocumentPrintJobModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      documentPath: json['documentPath']?.toString() ?? '',
      printer: PrinterDeviceModel.fromJson(printerJson),
      copies: (json['copies'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'documentPath': documentPath,
      'printer': PrinterDeviceModel.fromEntity(printer).toJson(),
      'copies': copies,
    };
  }

  @override
  DocumentPrintJobModel copyWith({
    String? id,
    String? title,
    String? documentPath,
    PrinterDevice? printer,
    int? copies,
  }) {
    return DocumentPrintJobModel(
      id: id ?? this.id,
      title: title ?? this.title,
      documentPath: documentPath ?? this.documentPath,
      printer: printer ?? this.printer,
      copies: copies ?? this.copies,
    );
  }

  DocumentPrintJob toEntity() => this;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentPrintJobModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          documentPath == other.documentPath &&
          printer == other.printer &&
          copies == other.copies;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      documentPath.hashCode ^
      printer.hashCode ^
      copies.hashCode;
}