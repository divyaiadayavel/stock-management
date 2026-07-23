import '../printer/printer_device.dart';

class DocumentPrintJob {
  final String id;
  final String title;
  final String documentPath;
  final PrinterDevice printer;
  final int copies;

  const DocumentPrintJob({
    required this.id,
    required this.title,
    required this.documentPath,
    required this.printer,
    this.copies = 1,
  });

  DocumentPrintJob copyWith({
    String? id,
    String? title,
    String? documentPath,
    PrinterDevice? printer,
    int? copies,
  }) {
    return DocumentPrintJob(
      id: id ?? this.id,
      title: title ?? this.title,
      documentPath: documentPath ?? this.documentPath,
      printer: printer ?? this.printer,
      copies: copies ?? this.copies,
    );
  }
}