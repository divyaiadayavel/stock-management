import 'dart:typed_data';
import 'package:printing/printing.dart';

abstract class DocumentPrintService {
  Future<bool> printPdf({required Uint8List pdfBytes, String jobName = 'Document'});
  Future<bool> sharePdf({required Uint8List pdfBytes, String fileName = 'document.pdf'});
  Future<bool> printImage({required Uint8List imageBytes, String jobName = 'Image'});
  Future<bool> printInvoice({required Uint8List pdfBytes, String jobName = 'Invoice'});
  Future<bool> printReceipt({required Uint8List pdfBytes, String jobName = 'Receipt'});
  Future<bool> shareImage({required Uint8List imageBytes, String fileName = 'image.png'});
  Future<bool> cancelPrint();
  Future<List<Printer>> getInstalledPrinters();
}

class DocumentPrintServiceImpl implements DocumentPrintService {
  @override
  Future<bool> printPdf({required Uint8List pdfBytes, String jobName = 'Document'}) async {
    try {
      await Printing.layoutPdf(name: jobName, onLayout: (_) async => pdfBytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> sharePdf({required Uint8List pdfBytes, String fileName = 'document.pdf'}) async {
    try {
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> printImage({required Uint8List imageBytes, String jobName = 'Image'}) async {
    // Image to PDF conversion not yet implemented; return false.
    return false;
  }

  @override
  Future<bool> printInvoice({required Uint8List pdfBytes, String jobName = 'Invoice'}) {
    return printPdf(pdfBytes: pdfBytes, jobName: jobName);
  }

  @override
  Future<bool> printReceipt({required Uint8List pdfBytes, String jobName = 'Receipt'}) {
    return printPdf(pdfBytes: pdfBytes, jobName: jobName);
  }

  @override
  Future<bool> shareImage({required Uint8List imageBytes, String fileName = 'image.png'}) async {
    // Not a PDF – cannot share via sharePdf; return false.
    return false;
  }

  @override
  Future<bool> cancelPrint() async {
    // Printing package does not expose cancel; placeholder.
    return true;
  }

  @override
  Future<List<Printer>> getInstalledPrinters() async {
    try {
      return await Printing.listPrinters();
    } catch (_) {
      return <Printer>[];
    }
  }
}