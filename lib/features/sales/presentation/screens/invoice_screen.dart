import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/screens/main_navigation.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/storage/db_helper.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../providers/invoice_provider.dart';

class InvoiceScreen extends ConsumerStatefulWidget {
  final int invoiceId;
  final String customerName;
  final double balanceDue;

  const InvoiceScreen({
    super.key,
    required this.invoiceId,
    this.customerName = 'Walk-in Customer',
    this.balanceDue = 0,
  });

  @override
  ConsumerState<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends ConsumerState<InvoiceScreen> {
  DateTime _invoiceDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadInvoice();
  }

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

    if (invoice.first['createdAt'] != null) {
      setState(() {
        _invoiceDate =
            DateTime.tryParse(invoice.first['createdAt'].toString()) ??
            DateTime.now();
      });
    }
  }

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();
    final items = ref.read(invoiceItemsProvider);
    final subtotal = ref.read(subtotalProvider);
    final discount = ref.read(discountProvider);
    final tax = ref.read(taxProvider);
    final total = ref.read(totalProvider);
    final taxable = subtotal - discount;
    final halfTax = tax / 2;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Your Store',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'INV-${widget.invoiceId}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '${_invoiceDate.day}/${_invoiceDate.month}/${_invoiceDate.year}  ·  Bill to: ${widget.customerName}',
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      _pdfCell('Item', bold: true),
                      _pdfCell('Qty', bold: true),
                      _pdfCell('Amount', bold: true),
                    ],
                  ),
                  ...items.map(
                    (item) => pw.TableRow(
                      children: [
                        _pdfCell(item['name'].toString()),
                        _pdfCell(item['qty'].toString()),
                        _pdfCell(item['amount'].toString()),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.SizedBox(
                  width: 240,
                  child: pw.Column(
                    children: [
                      _pdfTotalRow('Taxable', taxable),
                      _pdfTotalRow('CGST 9%', halfTax),
                      _pdfTotalRow('SGST 9%', halfTax),
                      pw.Divider(),
                      _pdfTotalRow('Grand total', total, bold: true),
                      if (widget.balanceDue > 0)
                        _pdfTotalRow('Balance due', widget.balanceDue),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return pdf.save();
  }

  Future<void> _downloadInvoice() async {
    final pdfBytes = await _generatePdf();
    final directory = await getExternalStorageDirectory();
    final file = File('${directory!.path}/Invoice_${widget.invoiceId}.pdf');
    await file.writeAsBytes(pdfBytes);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice downloaded: ${file.path}')),
      );
    }
  }

  Future<void> _shareInvoice() async {
    final pdfBytes = await _generatePdf();
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Invoice_${widget.invoiceId}.pdf',
    );
  }

  Future<void> _printInvoice() async {
    final pdfBytes = await _generatePdf();
    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(invoiceItemsProvider);
    final subtotal = ref.watch(subtotalProvider);
    final discount = ref.watch(discountProvider);
    final tax = ref.watch(taxProvider);
    final total = ref.watch(totalProvider);
    final taxable = subtotal - discount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimaryDark,
            size: R.icon(context, AppSizes.iconLg),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Invoice', style: AppTextStyles.heading),
        actions: [
          _CircleIconButton(
            icon: Icons.download_outlined,
            onTap: _downloadInvoice,
          ),
          SizedBox(width: R.sp(context, AppSpacing.xs)),
          _CircleIconButton(icon: Icons.sync, onTap: loadInvoice),
          SizedBox(width: R.sp(context, AppSpacing.sm)),
        ],
      ),
      body: items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Main Scrollable Content ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: R
                        .hPad(context, base: AppSpacing.screenPadding)
                        .copyWith(
                          top: R.sp(context, AppSpacing.sm),
                          bottom: R.sp(context, AppSpacing.md),
                        ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Store header card ──
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(
                            R.sp(context, AppSpacing.cardPadding),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(
                              R.radius(context, AppSizes.cardRadius),
                            ),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Anna Nagar Store',
                                style: AppTextStyles.cardValue.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: R.fs(context, 16),
                                ),
                              ),
                              SizedBox(height: R.sp(context, AppSpacing.xs)),
                              Text(
                                'INV-${widget.invoiceId} · ${_invoiceDate.day} '
                                '${_monthShort(_invoiceDate.month)} ${_invoiceDate.year}',
                                style: AppTextStyles.small.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: R.sp(context, AppSpacing.md)),

                        // ── Items Box (Matched to image layout) ──
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(
                              R.radius(context, AppSizes.cardRadius),
                            ),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: items.asMap().entries.map((entry) {
                              int index = entry.key;
                              var item = entry.value;
                              return Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: R.sp(
                                        context,
                                        AppSpacing.cardPadding,
                                      ),
                                      vertical: R.sp(context, AppSpacing.sm),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${item['name']} × ${item['qty']}',
                                          style: AppTextStyles.cardValue
                                              .copyWith(
                                                color:
                                                    AppColors.textPrimaryDark,
                                              ),
                                        ),
                                        Text(
                                          '₹${item['amount']}',
                                          style: AppTextStyles.cardValue,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (index < items.length - 1)
                                    Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: AppColors.border,
                                    ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),

                        SizedBox(height: R.sp(context, AppSpacing.md)),

                        // ── Summary box ──
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(
                            R.sp(context, AppSpacing.cardPadding),
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F3F5),
                            borderRadius: BorderRadius.circular(
                              R.radius(context, AppSizes.cardRadius),
                            ),
                          ),
                          child: Column(
                            children: [
                              _summaryRow('Taxable', taxable),
                              _summaryRow('CGST 9% · SGST 9%', tax),
                              SizedBox(height: R.sp(context, AppSpacing.xs)),
                              _summaryRow('Grand total', total, bold: true),
                              if (widget.balanceDue > 0) ...[
                                SizedBox(height: R.sp(context, AppSpacing.xs)),
                                _summaryRow(
                                  'Balance due',
                                  widget.balanceDue,
                                  color: AppColors.orange,
                                ),
                              ],
                            ],
                          ),
                        ),

                        SizedBox(height: R.sp(context, AppSpacing.md)),

                        // ── Bill to ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Bill to',
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              widget.customerName,
                              style: AppTextStyles.cardValue.copyWith(
                                color: AppColors.textPrimaryDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Fixed Bottom Buttons ──
                Container(
                  padding: R
                      .hPad(context, base: AppSpacing.screenPadding)
                      .copyWith(
                        top: R.sp(context, AppSpacing.sm),
                        bottom: R.sp(
                          context,
                          AppSpacing.lg,
                        ), // Add padding for bottom edge
                      ),
                  decoration: const BoxDecoration(color: AppColors.background),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: R.btnH(context),
                                child: OutlinedButton(
                                  onPressed: _shareInvoice,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        R.radius(context, AppSizes.radiusMd),
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Share',
                                    style: AppTextStyles.button.copyWith(
                                      color: AppColors.textPrimaryDark,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: R.sp(context, AppSpacing.sm)),
                            Expanded(
                              child: SizedBox(
                                height: R.btnH(context),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: AppColors.brandGradient,
                                    borderRadius: BorderRadius.circular(
                                      R.radius(context, AppSizes.radiusMd),
                                    ),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _printInvoice,
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          R.radius(context, AppSizes.radiusMd),
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'Print',
                                      style: AppTextStyles.button.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: R.sp(context, AppSpacing.xs)),
                        SizedBox(
                          width: double.infinity,
                          height: R.btnH(context),
                          child: TextButton(
                            onPressed: () => Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MainNavigationScreen(),
                              ),
                              (route) => false,
                            ),
                            child: Text(
                              'Exit',
                              style: AppTextStyles.button.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _summaryRow(
    String title,
    double value, {
    bool bold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.small.copyWith(
            color: color ?? AppColors.textSecondary,
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: (bold ? AppTextStyles.cardValue : AppTextStyles.small)
              .copyWith(
                color: color ?? AppColors.textPrimaryDark,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ],
    );
  }

  String _monthShort(int m) => const [
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
  ][m - 1];

  pw.Widget _pdfCell(String text, {bool bold = false}) => pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );

  pw.Widget _pdfTotalRow(String title, double value, {bool bold = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          children: [
            pw.Text(title),
            pw.Spacer(),
            pw.Text(
              '₹ ${value.toStringAsFixed(0)}',
              style: pw.TextStyle(
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ],
        ),
      );
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: R.sp(context, 36),
        height: R.sp(context, 36),
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          size: R.icon(context, AppSizes.iconSm),
          color: AppColors.textPrimaryDark,
        ),
      ),
    );
  }
}
