// lib/features/sales/presentation/screens/invoice_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../settings/domain/entities/printers_hardware/receipt/receipt.dart';
import '../../../settings/domain/entities/printers_hardware/receipt/receipt_item.dart';
import '../../../settings/presentation/providers/printers_hardware/printer_management/printers_hardware_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/sales_provider.dart';
import '../../data/models/sale_model.dart';
import '../../../customers/presentation/provider/customer_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import 'current_bill_screen.dart';

class InvoiceScreen extends ConsumerStatefulWidget {
  final int saleId;

  const InvoiceScreen({super.key, required this.saleId});

  @override
  ConsumerState<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends ConsumerState<InvoiceScreen> {
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(invoiceProvider.notifier).loadInvoice(widget.saleId);
    });
  }

  void _navigateToBilling() {
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const CurrentBillScreen()),
      (route) => route.isFirst,
    );
  }

  Future<Uint8List> _generatePdf(SaleModel sale) async {
    final pdf = pw.Document();
    final balanceVal =
        sale.balanceAmount ?? (sale.grandTotal - (sale.paidAmount ?? 0.0));

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
                    sale.invoiceNumber,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '${sale.createdAt.day}/${sale.createdAt.month}/${sale.createdAt.year}  ·  Bill to: ${sale.customerName}',
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1.4),
                  3: pw.FlexColumnWidth(1.4),
                  4: pw.FlexColumnWidth(1.4),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      _pdfCell('Item', bold: true),
                      _pdfCell('Qty', bold: true),
                      _pdfCell('Discount', bold: true),
                      _pdfCell('GST', bold: true),
                      _pdfCell('Amount', bold: true),
                    ],
                  ),
                  ...sale.items.map(
                    (item) => pw.TableRow(
                      children: [
                        _pdfCell(item.name),
                        _pdfCell(item.qty.toString()),
                        _pdfCell(
                          item.discountAmount > 0
                              ? item.discountAmount.toStringAsFixed(2)
                              : '-',
                        ),
                        _pdfCell(
                          item.tax > 0 ? item.tax.toStringAsFixed(2) : '-',
                        ),
                        _pdfCell(item.total.toStringAsFixed(2)),
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
                      _pdfTotalRow(
                        'Taxable',
                        sale.subtotal - sale.discountAmount,
                      ),
                      _pdfTotalRow('CGST 9%', sale.taxAmount / 2),
                      _pdfTotalRow('SGST 9%', sale.taxAmount / 2),
                      pw.Divider(),
                      _pdfTotalRow('Grand total', sale.grandTotal, bold: true),
                      if (balanceVal > 0)
                        _pdfTotalRow('Balance due', balanceVal),
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

  Future<void> _downloadInvoice(SaleModel sale) async {
    final pdfBytes = await _generatePdf(sale);
    final directory = await getExternalStorageDirectory();
    final file = File('${directory!.path}/Invoice_${sale.invoiceNumber}.pdf');
    await file.writeAsBytes(pdfBytes);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice downloaded: ${file.path}')),
      );
    }
  }

  Future<void> _shareInvoice(SaleModel sale) async {
    final pdfBytes = await _generatePdf(sale);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Invoice_${sale.invoiceNumber}.pdf',
    );
  }

  Receipt _buildReceiptFromInvoice(
    SaleModel sale,
    String? storeName,
    String? storeAddress,
    String? storePhone,
    String? gstNumber,
    String? logoPath,
  ) {
    return Receipt(
      receiptId: sale.invoiceNumber,
      timestamp: sale.createdAt,
      cashierName: 'Staff',
      storeName: storeName,
      storeAddress: storeAddress,
      storePhone: storePhone,
      gstNumber: gstNumber,
      logoPath: logoPath,
      paymentMode: sale.paymentMethod,
      items: sale.items.map((item) {
        return ReceiptItem(
          itemName: item.name,
          quantity: item.qty,
          unitPrice: item.price,
          totalAmount: item.total,
        );
      }).toList(),
      subTotal: sale.subtotal - sale.discountAmount,
      taxAmount: sale.taxAmount,
      grandTotal: sale.grandTotal,
    );
  }

  Future<void> _printInvoice(SaleModel sale) async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);

    try {
      final printerNotifier = ref.read(printersHardwareProvider.notifier);
      final printer = await printerNotifier.ensureDefaultPrinterLoaded();

      if (printer == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No printer set up yet. Add one in Settings → Printers & Hardware.',
              ),
            ),
          );
        }
        return;
      }

      final profile = ref.read(settingsControllerProvider).valueOrNull?.profile;
      final receipt = _buildReceiptFromInvoice(
        sale,
        profile?.storeName,
        profile?.businessAddress,
        profile?.phoneNumber,
        profile?.gstNumber,
        profile?.logoPath,
      );
      final success = await printerNotifier.printReceipt(receipt);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Printed on ${printer.name}'
                  : 'Print failed. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoiceState = ref.watch(invoiceProvider);

    if (invoiceState.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (invoiceState.invoice == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: R.sp(context, AppSpacing.md)),
              Text('Could not load invoice', style: AppTextStyles.sectionTitle),
              SizedBox(height: R.sp(context, AppSpacing.sm)),
              Text(
                'Please try again',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: R.sp(context, AppSpacing.lg)),
              ElevatedButton(
                onPressed: () {
                  ref.read(invoiceProvider.notifier).loadInvoice(widget.saleId);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final sale = invoiceState.invoice!;
    final status = sale.paymentStatus.toUpperCase();
    final isPaid = status == "PAID";
    final isPartial = status == "PARTIAL";
    final isPending = status == "PENDING";

    final paidVal = sale.paidAmount ?? (isPaid ? sale.grandTotal : 0.0);
    final balanceVal = sale.balanceAmount ?? (sale.grandTotal - paidVal);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _navigateToBilling();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: AppColors.textPrimaryDark,
              size: R.icon(context, AppSizes.iconLg),
            ),
            onPressed: _navigateToBilling,
          ),
          title: Text('Invoice Summary', style: AppTextStyles.heading),
          actions: [
            _CircleIconButton(
              icon: Icons.download_outlined,
              onTap: () => _downloadInvoice(sale),
            ),
            SizedBox(width: R.sp(context, AppSpacing.xs)),
            _CircleIconButton(
              icon: Icons.sync,
              onTap: () {
                ref.read(invoiceProvider.notifier).loadInvoice(widget.saleId);
              },
            ),
            SizedBox(width: R.sp(context, AppSpacing.sm)),
          ],
        ),
        body: Column(
          children: [
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  ref
                                          .read(settingsControllerProvider)
                                          .valueOrNull
                                          ?.profile
                                          ?.storeName ??
                                      'Anna Nagar Store',
                                  style: AppTextStyles.cardValue.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: R.fs(context, 18),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isPaid
                                      ? const Color(0xFFE8F5E9)
                                      : isPartial
                                      ? const Color(0xFFFFF3E0)
                                      : const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  sale.paymentStatus,
                                  style: TextStyle(
                                    color: isPaid
                                        ? const Color(0xFF2E7D32)
                                        : isPartial
                                        ? const Color(0xFFE65100)
                                        : const Color(0xFFC62828),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: R.sp(context, AppSpacing.sm)),
                          Text(
                            'Invoice No: ${sale.invoiceNumber.isEmpty ? "Generating..." : sale.invoiceNumber}',
                            style: AppTextStyles.small.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Date: ${sale.createdAt.day} ${_monthShort(sale.createdAt.month)} ${sale.createdAt.year} · ${sale.createdAt.hour}:${sale.createdAt.minute.toString().padLeft(2, '0')}',
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: R.sp(context, AppSpacing.md)),
                    Text(
                      'ITEMS ORDERED',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: R.sp(context, AppSpacing.xs)),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(
                          R.radius(context, AppSizes.cardRadius),
                        ),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          ...sale.items.asMap().entries.map((entry) {
                            int index = entry.key;
                            var item = entry.value;
                            final hasDiscount = item.discountAmount > 0;
                            final hasTax = item.tax > 0;
                            return Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: R.sp(
                                      context,
                                      AppSpacing.cardPadding,
                                    ),
                                    vertical: R.sp(context, AppSpacing.md),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.name.isEmpty
                                                      ? 'Unknown Product'
                                                      : item.name,
                                                  style: AppTextStyles.cardValue
                                                      .copyWith(
                                                        color: AppColors
                                                            .textPrimaryDark,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '₹${item.price.toStringAsFixed(2)} × ${item.qty}',
                                                  style: AppTextStyles.small
                                                      .copyWith(
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '₹${item.total.toStringAsFixed(2)}',
                                            style: AppTextStyles.cardValue
                                                .copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                      if (hasDiscount || hasTax) ...[
                                        SizedBox(
                                          height: R.sp(context, AppSpacing.xs),
                                        ),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            if (hasDiscount)
                                              _lineTag(
                                                'Discount -₹${item.discountAmount.toStringAsFixed(2)}',
                                                const Color(0xFF2E7D32),
                                              ),
                                            if (hasTax)
                                              _lineTag(
                                                'GST ₹${item.tax.toStringAsFixed(2)}',
                                                const Color(0xFF1565C0),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (index < sale.items.length - 1)
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: AppColors.border,
                                  ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                    SizedBox(height: R.sp(context, AppSpacing.md)),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(
                        R.sp(context, AppSpacing.cardPadding),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(
                          R.radius(context, AppSizes.cardRadius),
                        ),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _summaryRow('Subtotal', sale.subtotal),
                          const SizedBox(height: 6),
                          _summaryRow(
                            'Discount Applied',
                            -sale.discountAmount,
                            color: const Color(0xFF2E7D32),
                          ),
                          const SizedBox(height: 6),
                          _summaryRow(
                            'Taxable Amount',
                            sale.subtotal - sale.discountAmount,
                          ),
                          const SizedBox(height: 6),
                          _summaryRow('GST Collected', sale.taxAmount),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: _DottedLine(),
                          ),
                          _summaryRow(
                            'Grand Total',
                            sale.grandTotal,
                            bold: true,
                          ),
                          const SizedBox(height: 6),
                          _summaryRow(
                            'Paid Amount',
                            paidVal,
                            color: const Color(0xFF2E7D32),
                            bold: true,
                          ),
                          const SizedBox(height: 6),
                          _summaryRow(
                            'Balance Due',
                            balanceVal,
                            color: balanceVal > 0
                                ? AppColors.orange
                                : AppColors.textPrimaryDark,
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                    if (sale.payments.isNotEmpty) ...[
                      SizedBox(height: R.sp(context, AppSpacing.md)),
                      Text(
                        'PAYMENT HISTORY',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: R.sp(context, AppSpacing.xs)),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...sale.payments.map(
                              (p) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '● ${p.paymentMethod}',
                                          style: AppTextStyles.cardValue
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        if (p.referenceNumber != null &&
                                            p.referenceNumber!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Ref: ${p.referenceNumber}',
                                            style: AppTextStyles.small.copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                        if (p.paymentDate != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '${p.paymentDate}',
                                            style: AppTextStyles.small.copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      '₹${p.amount.toStringAsFixed(2)}',
                                      style: AppTextStyles.cardValue.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: R.sp(context, AppSpacing.md)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Billed Customer:',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          sale.customerName,
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
            Container(
              padding: R
                  .hPad(context, base: AppSpacing.screenPadding)
                  .copyWith(
                    top: R.sp(context, AppSpacing.sm),
                    bottom: R.sp(context, AppSpacing.lg),
                  ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
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
                              onPressed: () => _shareInvoice(sale),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    R.radius(context, AppSizes.radiusMd),
                                  ),
                                ),
                              ),
                              child: Text(
                                'Share PDF',
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
                                onPressed: _isPrinting
                                    ? null
                                    : () => _printInvoice(sale),
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
                                child: _isPrinting
                                    ? SizedBox(
                                        width: R.sp(context, 18),
                                        height: R.sp(context, 18),
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Print Receipt',
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
                        onPressed: _navigateToBilling,
                        child: Text(
                          'Back to Billing Screen',
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
      ),
    );
  }

  Widget _summaryRow(
    String title,
    double value, {
    bool bold = false,
    Color? color,
  }) {
    final displayVal = value < 0
        ? '-₹${value.abs().toStringAsFixed(2)}'
        : '₹${value.toStringAsFixed(2)}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.small.copyWith(
            color:
                color ??
                (bold ? AppColors.textPrimaryDark : AppColors.textSecondary),
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          displayVal,
          style: (bold ? AppTextStyles.cardValue : AppTextStyles.small)
              .copyWith(
                color: color ?? AppColors.textPrimaryDark,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
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

  Widget _lineTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

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
              '₹ ${value.toStringAsFixed(2)}',
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

class _DottedLine extends StatelessWidget {
  const _DottedLine();
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashSpace = 4.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFCBD5E1)),
              ),
            );
          }),
        );
      },
    );
  }
}
