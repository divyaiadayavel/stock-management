import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../dashboard/presentation/screens/main_navigation.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/db_helper.dart';
import '../../../../core/utils/responsive_helper.dart'; // Make sure this import path matches your directory structure
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
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
        iconTheme: IconThemeData(
          color: Colors.white,
          size: R.icon(context, 24),
        ),
        title: Text(
          "Invoice",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: R.fs(context, 20),
          ),
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
                    padding: R.hPad(context, base: 14.0),
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: R.sp(context, 14)),
                      padding: EdgeInsets.all(R.sp(context, 18)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          R.radius(context, 18),
                        ),
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
                                children: [
                                  Text(
                                    "Your Store",
                                    style: TextStyle(
                                      fontSize: R.fs(context, 22),
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(height: R.sp(context, 6)),
                                  Text(
                                    "No. 45, Anna Nagar",
                                    style: TextStyle(
                                      fontSize: R.fs(context, 14),
                                    ),
                                  ),
                                  Text(
                                    "Chennai - 600080",
                                    style: TextStyle(
                                      fontSize: R.fs(context, 14),
                                    ),
                                  ),
                                  Text(
                                    "Ph: 9876543210",
                                    style: TextStyle(
                                      fontSize: R.fs(context, 14),
                                    ),
                                  ),
                                  Text(
                                    "GSTIN: 33ABCDE1234F1Z5",
                                    style: TextStyle(
                                      fontSize: R.fs(context, 14),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "INV-${widget.invoiceId}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: R.fs(context, 14),
                                    ),
                                  ),
                                  SizedBox(height: R.sp(context, 5)),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: R.sp(context, 10),
                                      vertical: R.sp(context, 4),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(
                                        R.radius(context, 20),
                                      ),
                                    ),
                                    child: Text(
                                      "Paid",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: R.fs(context, 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          SizedBox(height: R.sp(context, 20)),

                          // ================= DATE =================
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                                style: TextStyle(fontSize: R.fs(context, 14)),
                              ),
                              Text(
                                "Customer: Walk-in Customer",
                                style: TextStyle(fontSize: R.fs(context, 14)),
                              ),
                            ],
                          ),

                          SizedBox(height: R.sp(context, 20)),

                          // ================= TABLE HEADER =================
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: R.sp(context, 10),
                              horizontal: R.sp(context, 8),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(
                                R.radius(context, 8),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    "Item",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: R.fs(context, 14),
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
                                      fontSize: R.fs(context, 14),
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
                                      fontSize: R.fs(context, 14),
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
                                      fontSize: R.fs(context, 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: R.sp(context, 10)),

                          // ================= ITEMS =================
                          ListView.builder(
                            itemCount: items.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (_, i) => _buildItemRow(items[i]),
                          ),

                          Divider(height: R.sp(context, 30)),

                          // ================= TOTALS =================
                          _row("Subtotal", subtotal),
                          _row("Discount", discount),
                          _row("Tax (18%)", tax),

                          const Divider(),

                          _row("Total", total, bold: true),

                          SizedBox(height: R.sp(context, 10)),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Paid",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: R.fs(context, 14),
                                ),
                              ),
                              Text(
                                "₹ ${total.toStringAsFixed(0)}",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: R.fs(context, 14),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: R.sp(context, 6)),

                          _row("Balance", 0),

                          SizedBox(height: R.sp(context, 30)),

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

                          SizedBox(height: R.sp(context, 25)),

                          SizedBox(
                            width: double.infinity,
                            height: R.btnH(context),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    R.radius(context, 12),
                                  ),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const MainNavigationScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                              child: Text(
                                "Exit",
                                style: TextStyle(
                                  fontSize: R.fs(context, 16),
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
      padding: EdgeInsets.symmetric(vertical: R.sp(context, 10)),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              item["name"].toString(),
              style: TextStyle(fontSize: R.fs(context, 14)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "${item["qty"]}",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: R.fs(context, 14)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              "₹ ${item["price"]}",
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: R.fs(context, 14)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              "₹ ${item["amount"]}",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: R.fs(context, 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= TOTAL ROW =================
  Widget _row(String title, double value, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: R.sp(context, 4)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: R.fs(context, 14))),
          Text(
            "₹ ${value.toStringAsFixed(0)}",
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: R.fs(context, 14),
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
        width: R.fluid(context, 90, 120),
        padding: EdgeInsets.symmetric(vertical: R.sp(context, 12)),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(R.radius(context, 12)),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: R.icon(context, 24)),
            SizedBox(height: R.sp(context, 6)),
            Text(
              text,
              style: TextStyle(
                fontSize: R.fs(context, 12),
                fontWeight: FontWeight.w500,
              ),
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
        children: [
          pw.Text(title),
          pw.Spacer(), // Push the value to the far right side of the row
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
