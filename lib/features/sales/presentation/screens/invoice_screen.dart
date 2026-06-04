import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/db_helper.dart';
import 'billing_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/invoice_provider.dart';
import '../../../../core/constants/app_curve.dart';

class InvoiceScreen extends ConsumerStatefulWidget {
  final int invoiceId;

  const InvoiceScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends ConsumerState<InvoiceScreen> {
  @override
  void initState() {
    super.initState();
    loadInvoice();
  }

  // ================= LOAD INVOICE =================
  void loadInvoice() async {
    final dbClient = await DBHelper.db;

    final invoice = await dbClient.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [widget.invoiceId],
    );

    final invoiceItems = await dbClient.query(
      'invoice_items',
      where: 'invoiceId = ?',
      whereArgs: [widget.invoiceId],
    );
    ref.read(invoiceItemsProvider.notifier).state = invoiceItems;

    ref.read(subtotalProvider.notifier).state =
        (invoice.first['subtotal'] as num).toDouble();

    ref.read(discountProvider.notifier).state =
        (invoice.first['discount'] as num).toDouble();

    ref.read(taxProvider.notifier).state = (invoice.first['tax'] as num)
        .toDouble();

    ref.read(totalProvider.notifier).state = (invoice.first['total'] as num)
        .toDouble();
  }

  // ================= PDF GENERATE =================
  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();

    final items = ref.read(invoiceItemsProvider);
    final subtotal = ref.read(subtotalProvider);
    final discount = ref.read(discountProvider);
    final tax = ref.read(taxProvider);
    final total = ref.read(totalProvider);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,

        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),

            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,

              children: [
                // ================= STORE DETAILS =================
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,

                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,

                      children: [
                        pw.Text(
                          "Your Store",
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),

                        pw.SizedBox(height: 6),

                        pw.Text("No. 45, Anna Nagar"),
                        pw.Text("Chennai - 600080"),
                        pw.Text("Ph: 9876543210"),
                        pw.Text("GSTIN: 33ABCDE1234F1Z5"),
                      ],
                    ),

                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,

                      children: [
                        pw.Text(
                          "INV-${widget.invoiceId}",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),

                        pw.SizedBox(height: 5),

                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),

                          decoration: pw.BoxDecoration(
                            color: PdfColors.green100,
                            borderRadius: pw.BorderRadius.circular(10),
                          ),

                          child: pw.Text(
                            "Paid",
                            style: pw.TextStyle(
                              color: PdfColors.green800,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,

                  children: [
                    pw.Text(
                      "Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                    ),

                    pw.Text("Customer: Walk-in Customer"),
                  ],
                ),

                pw.SizedBox(height: 20),

                // ================= TABLE =================
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),

                  children: [
                    // HEADER
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),

                      children: [
                        _pdfCell("Item", bold: true),
                        _pdfCell("Qty", bold: true),
                        _pdfCell("Price", bold: true),
                        _pdfCell("Amount", bold: true),
                      ],
                    ),

                    // ITEMS
                    ...items.map(
                      (item) => pw.TableRow(
                        children: [
                          _pdfCell(item["name"].toString()),
                          _pdfCell(item["qty"].toString()),
                          _pdfCell(item["price"].toString()),
                          _pdfCell(item["amount"].toString()),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // ================= TOTALS =================
                pw.Align(
                  alignment: pw.Alignment.centerRight,

                  child: pw.Container(
                    width: 220,

                    child: pw.Column(
                      children: [
                        _pdfTotalRow("Subtotal", subtotal),
                        _pdfTotalRow("Discount", discount),
                        _pdfTotalRow("Tax (18%)", tax),

                        pw.Divider(),

                        _pdfTotalRow("Total", total, bold: true),

                        pw.SizedBox(height: 10),

                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,

                          children: [
                            pw.Text(
                              "Paid",
                              style: pw.TextStyle(
                                color: PdfColors.green,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),

                            pw.Text(
                              "₹ ${total.toStringAsFixed(0)}",
                              style: pw.TextStyle(
                                color: PdfColors.green,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        pw.SizedBox(height: 6),

                        _pdfTotalRow("Balance", 0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // ================= DOWNLOAD =================
  Future<void> _downloadInvoice() async {
    final pdfBytes = await _generatePdf();

    final directory = await getExternalStorageDirectory();

    final file = File("${directory!.path}/Invoice_${widget.invoiceId}.pdf");

    await file.writeAsBytes(pdfBytes);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Invoice Downloaded: ${file.path}")));
  }

  // ================= SHARE =================
  Future<void> _shareInvoice() async {
    final pdfBytes = await _generatePdf();

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: "Invoice_${widget.invoiceId}.pdf",
    );
  }

  // ================= PRINT =================
  Future<void> _printInvoice() async {
    final pdfBytes = await _generatePdf();

    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final items = ref.watch(invoiceItemsProvider);

    final subtotal = ref.watch(subtotalProvider);

    final discount = ref.watch(discountProvider);

    final tax = ref.watch(taxProvider);

    final total = ref.watch(totalProvider);
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),

        title: const Text(
          "Invoice",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: Container(
        color: AppColors.primary,
        child: ClipRRect(
          borderRadius: AppCurve.top(context),
          child: Container(
            color: Colors.grey.shade100,
            child: items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ================= HEADER =================
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,

                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: const [
                                  Text(
                                    "Your Store",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),

                                  SizedBox(height: 6),

                                  Text("No. 45, Anna Nagar"),
                                  Text("Chennai - 600080"),
                                  Text("Ph: 9876543210"),
                                  Text("GSTIN: 33ABCDE1234F1Z5"),
                                ],
                              ),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,

                                children: [
                                  Text(
                                    "INV-${widget.invoiceId}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 5),

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),

                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),

                                    child: const Text(
                                      "Paid",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ================= DATE =================
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,

                            children: [
                              Text(
                                "Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                              ),

                              const Text("Customer: Walk-in Customer"),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ================= TABLE HEADER =================
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),

                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),

                            child: const Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    "Item",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "Qty",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    "Price",
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    "Amount",
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ================= ITEMS =================
                          ListView.builder(
                            itemCount: items.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),

                            itemBuilder: (_, i) => _buildItemRow(items[i]),
                          ),

                          const Divider(height: 30),

                          // ================= TOTALS =================
                          _row("Subtotal", subtotal),
                          _row("Discount", discount),
                          _row("Tax (18%)", tax),

                          const Divider(),

                          _row("Total", total, bold: true),

                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,

                            children: [
                              const Text(
                                "Paid",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                "₹ ${total.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          _row("Balance", 0),

                          const SizedBox(height: 30),

                          // ================= BUTTONS =================
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,

                            children: [
                              _btn(
                                Icons.download,
                                "Download",
                                onTap: _downloadInvoice,
                              ),

                              _btn(Icons.share, "Share", onTap: _shareInvoice),

                              _btn(Icons.print, "Print", onTap: _printInvoice),
                            ],
                          ),
                          const SizedBox(height: 25), // ✅ Space between rows
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const BillingScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                              child: const Text(
                                "Exit",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ================= ITEM ROW =================
  Widget _buildItemRow(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),

      child: Row(
        children: [
          Expanded(flex: 4, child: Text(item["name"].toString())),

          Expanded(
            flex: 2,
            child: Text("${item["qty"]}", textAlign: TextAlign.center),
          ),

          Expanded(
            flex: 3,
            child: Text("₹ ${item["price"]}", textAlign: TextAlign.right),
          ),

          Expanded(
            flex: 3,
            child: Text(
              "₹ ${item["amount"]}",
              textAlign: TextAlign.right,

              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ================= TOTAL ROW =================
  Widget _row(String title, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          Text(title),

          Text(
            "₹ ${value.toStringAsFixed(0)}",

            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ================= BUTTON =================
  Widget _btn(IconData icon, String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 12),

        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),

          borderRadius: BorderRadius.circular(12),

          color: Colors.white,
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Icon(icon, color: AppColors.primary),

            const SizedBox(height: 6),

            Text(
              text,

              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // ================= PDF CELL =================
  pw.Widget _pdfCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),

      child: pw.Text(
        text,

        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // ================= PDF TOTAL ROW =================
  pw.Widget _pdfTotalRow(String title, double value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),

      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,

        children: [
          pw.Text(title),

          pw.Text(
            "₹ ${value.toStringAsFixed(0)}",

            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
