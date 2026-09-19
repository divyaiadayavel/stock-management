
// lib/features/services/presentation/screens/service_receipt_screen.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/validators.dart';
import '../../../settings/domain/entities/printers_hardware/receipt/receipt.dart';
import '../../../settings/domain/entities/printers_hardware/receipt/receipt_item.dart';
import '../../../settings/presentation/providers/printers_hardware/printer_management/printers_hardware_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/service_answer_model.dart';
import '../../data/models/service_request_model.dart';

class ServiceReceiptScreen extends ConsumerStatefulWidget {
  final ServiceRequestModel request;

  const ServiceReceiptScreen({
    super.key,
    required this.request,
  });

  @override
  ConsumerState<ServiceReceiptScreen> createState() =>
      _ServiceReceiptScreenState();
}

class _ServiceReceiptScreenState
    extends ConsumerState<ServiceReceiptScreen> {
  bool _isPrinting = false;
  bool _isDownloading = false;
  bool _isSharing = false;

  ServiceRequestModel get request => widget.request;

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────

  String _capitalizeWords(String text) {
    if (text.trim().isEmpty) return text;

    return text
        .trim()
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return word;

          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  bool _isCustomerDetail(String label) {
    final lower = label.toLowerCase();

    return lower.contains('name') ||
        lower.contains('phone') ||
        lower.contains('mobile') ||
        lower.contains('email') ||
        lower.contains('contact') ||
        lower.contains('customer') ||
        lower.contains('user');
  }

  bool _isPhoneField(String label) {
    final lower = label.toLowerCase();

    return lower.contains('phone') ||
        lower.contains('mobile') ||
        lower.contains('contact');
  }

  String _formatValue(ServiceAnswerModel answer) {
    var value = answer.value.trim();

    if (value.isEmpty) {
      return '—';
    }

    if (_isPhoneField(answer.label) &&
        !value.startsWith('+91')) {
      value = '+91 $value';
    } else {
      final lower = answer.label.toLowerCase();
      if (lower.contains('name') ||
          lower.contains('customer') ||
          lower.contains('user')) {
        value = Validators.normalizeName(value);
      }
    }

    return value;
  }

  String _formatAmount(double amount) {
    return '₹ ${amount.toStringAsFixed(2)}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')} '
        '${_monthName(dateTime.month)} '
        '${dateTime.year}, '
        '${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0
        ? 12
        : dateTime.hour % 12;

    final minute = dateTime.minute.toString().padLeft(2, '0');

    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  String _statusLabel(String status) {
    if (status.trim().isEmpty) {
      return 'Submitted';
    }

    return _capitalizeWords(status);
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'COMPLETED':
      case 'SUCCESS':
        return const Color(0xFF15803D);

      case 'CANCELLED':
      case 'REJECTED':
      case 'FAILED':
        return const Color(0xFFDC2626);

      default:
        return const Color(0xFF2563EB);
    }
  }

  Color _statusBackground(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'COMPLETED':
      case 'SUCCESS':
        return const Color(0xFFDCFCE7);

      case 'CANCELLED':
      case 'REJECTED':
      case 'FAILED':
        return const Color(0xFFFEE2E2);

      default:
        return const Color(0xFFDBEAFE);
    }
  }

  String _invoiceNumber() {
    final value = request.invoiceNumber?.trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    if (request.id != null) {
      return 'SR-${request.id}';
    }

    return 'SERVICE-RECEIPT';
  }

  DateTime _submittedAt() {
    return request.submittedAt ?? DateTime.now();
  }

  List<ServiceAnswerModel> get _customerAnswers {
    return request.answerModels
        .where((answer) => _isCustomerDetail(answer.label))
        .toList();
  }

  List<ServiceAnswerModel> get _serviceAnswers {
    return request.answerModels
        .where((answer) => !_isCustomerDetail(answer.label))
        .toList();
  }

  // ─────────────────────────────────────────────────────────────
  // PDF GENERATION
  // ─────────────────────────────────────────────────────────────

  Future<Uint8List> _generateInvoicePdf() async {
    final pdf = pw.Document();

    final submittedAt = _submittedAt();
    final invoiceNumber = _invoiceNumber();
    final profile =
        ref.read(settingsControllerProvider).valueOrNull?.profile;

    final storeName =
        profile?.storeName?.trim().isNotEmpty == true
            ? profile!.storeName!.trim()
            : 'E-Services';

    final storeAddress =
        profile?.businessAddress?.trim() ?? '';

    final storePhone =
        profile?.phoneNumber?.trim() ?? '';

    final gstNumber =
        profile?.gstNumber?.trim() ?? '';

    final amount = request.amount;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            // ─────────────────────────────────────────
            // HEADER
            // ─────────────────────────────────────────

            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment:
                  pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        storeName,
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900,
                        ),
                      ),

                      if (storeAddress.isNotEmpty)
                        pw.Padding(
                          padding:
                              const pw.EdgeInsets.only(top: 5),
                          child: pw.Text(
                            storeAddress,
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ),

                      if (storePhone.isNotEmpty)
                        pw.Padding(
                          padding:
                              const pw.EdgeInsets.only(top: 3),
                          child: pw.Text(
                            'Phone: $storePhone',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ),

                      if (gstNumber.isNotEmpty)
                        pw.Padding(
                          padding:
                              const pw.EdgeInsets.only(top: 3),
                          child: pw.Text(
                            'GST: $gstNumber',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      invoiceNumber,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      _formatDateTime(submittedAt),
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 18),

            pw.Divider(
              color: PdfColors.grey300,
              thickness: 1,
            ),

            pw.SizedBox(height: 16),

            // ─────────────────────────────────────────
            // SERVICE HEADER
            // ─────────────────────────────────────────

            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius:
                    pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 42,
                    height: 42,
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blue100,
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'S',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                    ),
                  ),

                  pw.SizedBox(width: 12),

                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment:
                          pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          request.serviceName.isEmpty
                              ? 'Service'
                              : _capitalizeWords(
                                  request.serviceName,
                                ),
                          style: pw.TextStyle(
                            fontSize: 17,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          request.categoryName.isEmpty
                              ? 'E-Services'
                              : _capitalizeWords(
                                  request.categoryName,
                                ),
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green100,
                      borderRadius:
                          pw.BorderRadius.circular(20),
                    ),
                    child: pw.Text(
                      _statusLabel(request.status),
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 22),

            // ─────────────────────────────────────────
            // CUSTOMER DETAILS
            // ─────────────────────────────────────────

            if (_customerAnswers.isNotEmpty) ...[
              _pdfSectionTitle('Customer Details'),

              pw.SizedBox(height: 8),

              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.grey300,
                  ),
                  borderRadius:
                      pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  children: _customerAnswers
                      .map(
                        (answer) => _pdfDetailRow(
                          _capitalizeWords(answer.label),
                          _formatValue(answer),
                        ),
                      )
                      .toList(),
                ),
              ),

              pw.SizedBox(height: 20),
            ],

            // ─────────────────────────────────────────
            // SERVICE DETAILS
            // ─────────────────────────────────────────

            _pdfSectionTitle('Service Details'),

            pw.SizedBox(height: 8),

            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColors.grey300,
                ),
                borderRadius:
                    pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                children: [
                  _pdfDetailRow(
                    'Service',
                    request.serviceName.isEmpty
                        ? 'Service'
                        : _capitalizeWords(
                            request.serviceName,
                          ),
                  ),
                  _pdfDetailRow(
                    'Category',
                    request.categoryName.isEmpty
                        ? 'E-Services'
                        : _capitalizeWords(
                            request.categoryName,
                          ),
                  ),
                  ..._serviceAnswers.map(
                    (answer) => _pdfDetailRow(
                      _capitalizeWords(answer.label),
                      _formatValue(answer),
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 22),

            // ─────────────────────────────────────────
            // AMOUNT SUMMARY
            // ─────────────────────────────────────────

            _pdfSectionTitle('Transaction Details'),

            pw.SizedBox(height: 8),

            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColors.grey300,
                ),
                borderRadius:
                    pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                children: [
                  _pdfAmountRow(
                    'Service Charge',
                    amount,
                  ),

                  pw.SizedBox(height: 8),

                  pw.Divider(
                    color: PdfColors.grey300,
                  ),

                  pw.SizedBox(height: 8),

                  _pdfAmountRow(
                    'Total Amount',
                    amount,
                    bold: true,
                    fontSize: 16,
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // ─────────────────────────────────────────
            // FOOTER
            // ─────────────────────────────────────────

            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius:
                    pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'Thank you for using our e-services.',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'This is a system generated invoice.',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    invoiceNumber,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfSectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: const pw.BoxDecoration(
        color: PdfColors.blue50,
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue800,
        ),
      ),
    );
  }

  pw.Widget _pdfDetailRow(
    String label,
    String value,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: pw.Row(
        crossAxisAlignment:
            pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 145,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfAmountRow(
    String label,
    double amount, {
    bool bold = false,
    double fontSize = 11,
  }) {
    return pw.Row(
      mainAxisAlignment:
          pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight:
                bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: PdfColors.grey800,
          ),
        ),
        pw.Text(
          'INR ${amount.toStringAsFixed(2)}',
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight:
                bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: bold
                ? PdfColors.blue800
                : PdfColors.grey900,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DOWNLOAD PDF
  // ─────────────────────────────────────────────────────────────

  Future<void> _downloadInvoice() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      final pdfBytes = await _generateInvoicePdf();

      final directory = await getExternalStorageDirectory();

      if (directory == null) {
        throw Exception('Storage directory unavailable');
      }

      final invoiceNumber = _invoiceNumber()
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

      final file = File(
        '${directory.path}/Invoice_$invoiceNumber.pdf',
      );

      await file.writeAsBytes(pdfBytes, flush: true);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invoice downloaded successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Unable to download invoice.',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SHARE PDF
  // ─────────────────────────────────────────────────────────────

  Future<void> _shareInvoice() async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      final pdfBytes = await _generateInvoicePdf();

      final invoiceNumber = _invoiceNumber()
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Invoice_$invoiceNumber.pdf',
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Unable to share invoice.',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // THERMAL RECEIPT
  // ─────────────────────────────────────────────────────────────

  Receipt _buildReceiptFromService(
    String? storeName,
    String? storeAddress,
    String? storePhone,
    String? gstNumber,
    String? logoPath,
  ) {
    final amount = request.amount;

    return Receipt(
      receiptId: _invoiceNumber(),
      timestamp: _submittedAt(),
      storeName: storeName,
      storeAddress: storeAddress,
      storePhone: storePhone,
      gstNumber: gstNumber,
      cashierName: 'Staff',
      logoPath: logoPath,

      items: [
        ReceiptItem(
          itemName: request.serviceName.isEmpty
              ? 'Service'
              : request.serviceName,
          quantity: 1,
          unitPrice: amount,
          totalAmount: amount,
        ),
      ],

      subTotal: amount,
      taxAmount: 0,
      grandTotal: amount,

      footerNote:
          'Thank you for using our e-services.',
      paymentMode: null,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // THERMAL PRINT
  // ─────────────────────────────────────────────────────────────

  Future<void> _printInvoice() async {
    if (_isPrinting) return;

    setState(() {
      _isPrinting = true;
    });

    try {
      final printerNotifier =
          ref.read(printersHardwareProvider.notifier);

      final printer =
          await printerNotifier.ensureDefaultPrinterLoaded();

      if (printer == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No printer set up yet. Add one in Settings → Printers & Hardware.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final profile =
          ref.read(settingsControllerProvider)
              .valueOrNull
              ?.profile;

      final receipt = _buildReceiptFromService(
        profile?.storeName,
        profile?.businessAddress,
        profile?.phoneNumber,
        profile?.gstNumber,
        profile?.logoPath,
      );

      final success =
          await printerNotifier.printReceipt(receipt);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Printed on ${printer.name}'
                : 'Print failed. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Unable to print invoice.',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final submittedAt = _submittedAt();
    final invoiceNumber = _invoiceNumber();
    final status = _statusLabel(request.status);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        centerTitle: false,
        title: Text(
          'Invoice',
          style: TextStyle(
            fontSize: R.fs(context, 20),
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            R.sp(context, 16),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ─────────────────────────────────────
              // MAIN INVOICE CARD
              // ─────────────────────────────────────

              Container(
                width: double.infinity,
                padding: EdgeInsets.all(
                  R.sp(context, 18),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: 0.05,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // SERVICE HEADER
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.miscellaneous_services_outlined,
                            color: Color(0xFF2563EB),
                            size: 25,
                          ),
                        ),

                        SizedBox(
                          width: R.sp(context, 12),
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.serviceName.isEmpty
                                    ? 'Service'
                                    : _capitalizeWords(
                                        request.serviceName,
                                      ),
                                maxLines: 2,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: R.fs(
                                    context,
                                    17,
                                  ),
                                  fontWeight:
                                      FontWeight.w800,
                                  color:
                                      const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                request.categoryName.isEmpty
                                    ? 'E-Services'
                                    : _capitalizeWords(
                                        request.categoryName,
                                      ),
                                style: TextStyle(
                                  fontSize: R.fs(
                                    context,
                                    12,
                                  ),
                                  color:
                                      const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _statusBackground(
                              request.status,
                            ),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: R.fs(
                                context,
                                11,
                              ),
                              fontWeight:
                                  FontWeight.w700,
                              color: _statusColor(
                                request.status,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    const Divider(
                      height: 1,
                      color: Color(0xFFE2E8F0),
                    ),

                    const SizedBox(height: 20),

                    // INVOICE META
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildMeta(
                            context,
                            'Invoice Number',
                            invoiceNumber,
                          ),
                        ),
                        SizedBox(
                          width: R.sp(context, 15),
                        ),
                        Expanded(
                          child: _buildMeta(
                            context,
                            'Date & Time',
                            _formatDateTime(
                              submittedAt,
                            ),
                            alignRight: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // CUSTOMER DETAILS
                    if (_customerAnswers.isNotEmpty) ...[
                      _buildSectionHeader(
                        context,
                        'Customer Details',
                        Icons.person_outline,
                      ),
                      const SizedBox(height: 8),

                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(
                          R.sp(context, 13),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius:
                              BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          children: _customerAnswers
                              .map(
                                (answer) => _buildDetailRow(
                                  context,
                                  _capitalizeWords(
                                    answer.label,
                                  ),
                                  _formatValue(answer),
                                ),
                              )
                              .toList(),
                        ),
                      ),

                      const SizedBox(height: 22),
                    ],

                    // SERVICE DETAILS
                    _buildSectionHeader(
                      context,
                      'Service Details',
                      Icons.miscellaneous_services_outlined,
                    ),

                    const SizedBox(height: 8),

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(
                        R.sp(context, 13),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            context,
                            'Service',
                            request.serviceName.isEmpty
                                ? 'Service'
                                : _capitalizeWords(
                                    request.serviceName,
                                  ),
                          ),
                          _buildDetailRow(
                            context,
                            'Category',
                            request.categoryName.isEmpty
                                ? 'E-Services'
                                : _capitalizeWords(
                                    request.categoryName,
                                  ),
                          ),
                          ..._serviceAnswers.map(
                            (answer) => _buildDetailRow(
                              context,
                              _capitalizeWords(
                                answer.label,
                              ),
                              _formatValue(answer),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // TRANSACTION DETAILS
                    _buildSectionHeader(
                      context,
                      'Transaction Details',
                      Icons.receipt_long_outlined,
                    ),

                    const SizedBox(height: 8),

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(
                        R.sp(context, 14),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildAmountRow(
                            context,
                            'Service Charge',
                            _formatAmount(
                              request.amount,
                            ),
                          ),

                          const SizedBox(height: 12),

                          const Divider(
                            height: 1,
                            color: Color(0xFFE2E8F0),
                          ),

                          const SizedBox(height: 12),

                          _buildAmountRow(
                            context,
                            'Total Amount',
                            _formatAmount(
                              request.amount,
                            ),
                            bold: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // FOOTER
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(
                        R.sp(context, 14),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Thank you for using our e-services.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: R.fs(
                                context,
                                12,
                              ),
                              fontWeight:
                                  FontWeight.w700,
                              color:
                                  const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'This is a system generated invoice.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: R.fs(
                                context,
                                10,
                              ),
                              color:
                                  const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: R.sp(context, 18),
              ),

              // ─────────────────────────────────────
              // ACTION BUTTONS
              // ─────────────────────────────────────

              _buildActionButton(
                context,
                icon: Icons.picture_as_pdf_outlined,
                label: 'Download PDF',
                isLoading: _isDownloading,
                onPressed: _downloadInvoice,
                backgroundColor: const Color(0xFFDC2626),
              ),

              const SizedBox(height: 10),

              _buildActionButton(
                context,
                icon: Icons.share_outlined,
                label: 'Share Invoice',
                isLoading: _isSharing,
                onPressed: _shareInvoice,
                backgroundColor: const Color(0xFF2563EB),
              ),

              const SizedBox(height: 10),

              _buildActionButton(
                context,
                icon: Icons.print_outlined,
                label: 'Print Invoice',
                isLoading: _isPrinting,
                onPressed: _printInvoice,
                backgroundColor: const Color(0xFF7C3AED),
              ),

              SizedBox(
                height: R.sp(context, 12),
              ),

              // BACK BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 19,
                  ),
                  label: const Text(
                    'Back to Services',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        const Color(0xFF475569),
                    side: const BorderSide(
                      color: Color(0xFFCBD5E1),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              SizedBox(
                height: R.sp(context, 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // UI HELPERS
  // ─────────────────────────────────────────────────────────────

  Widget _buildMeta(
    BuildContext context,
    String label,
    String value, {
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textAlign:
              alignRight ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            fontSize: R.fs(context, 11),
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          textAlign:
              alignRight ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            fontSize: R.fs(context, 13),
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            size: 17,
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: TextStyle(
            fontSize: R.fs(context, 14),
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: R.fs(context, 12),
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: R.fs(context, 12),
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: R.fs(
              context,
              bold ? 14 : 13,
            ),
            color: bold
                ? const Color(0xFF0F172A)
                : const Color(0xFF64748B),
            fontWeight:
                bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: R.fs(
              context,
              bold ? 17 : 13,
            ),
            color: bold
                ? const Color(0xFF2563EB)
                : const Color(0xFF0F172A),
            fontWeight:
                bold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              )
            : Icon(
                icon,
                size: 20,
              ),
        label: Text(
          isLoading
              ? 'Please wait...'
              : label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              backgroundColor.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }
}

