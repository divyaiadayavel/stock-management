// lib/features/reports/presentation/screens/provider_invoice_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../services/data/models/provider_recharge_model.dart';
import '../../../services/presentation/screens/provider_recharge_form_screen.dart';
import '../../../services/presentation/providers/provider_recharge_provider.dart';
import '../../../settings/domain/entities/printers_hardware/receipt/receipt.dart';
import '../../../settings/domain/entities/printers_hardware/receipt/receipt_item.dart';
import '../../../settings/presentation/providers/printers_hardware/printer_management/printers_hardware_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/provider_reports_data_provider.dart';
import '../widgets/report_shared_widgets.dart';

/// Provider invoice detail screen.
/// Matches the Sales Invoice Details layout while using provider recharge
/// data and the provider payment screen for outstanding balances.
class ProviderInvoiceDetailsScreen extends ConsumerStatefulWidget {
  final ProviderRechargeModel recharge;

  const ProviderInvoiceDetailsScreen({
    super.key,
    required this.recharge,
  });

  @override
  ConsumerState<ProviderInvoiceDetailsScreen> createState() =>
      _ProviderInvoiceDetailsScreenState();
}

class _ProviderInvoiceDetailsScreenState
    extends ConsumerState<ProviderInvoiceDetailsScreen> {
  late ProviderRechargeModel _recharge = widget.recharge;
  bool _isPrinting = false;
  bool _isSharing = false;

  String _money(double value) => formatRupee(value);

  Future<void> _reprintReceipt() async {
    if (_isPrinting) return;

    setState(() => _isPrinting = true);

    try {
      final printerNotifier = ref.read(printersHardwareProvider.notifier);
      final printer = await printerNotifier.ensureDefaultPrinterLoaded();

      if (printer == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No printer set up yet. Add one in Settings → Printers & Hardware.',
            ),
          ),
        );
        return;
      }

      final profile = ref.read(settingsControllerProvider).valueOrNull?.profile;
      final r = _recharge;

      final receipt = Receipt(
        receiptId: r.invoiceNumber ?? 'PROVIDER-${r.id ?? ''}',
        timestamp: r.submittedAt ?? DateTime.now(),
        cashierName: 'Staff',
        storeName: profile?.storeName,
        storeAddress: profile?.businessAddress,
        storePhone: profile?.phoneNumber,
        gstNumber: profile?.gstNumber,
        logoPath: profile?.logoPath,
        paymentMode: r.paymentMethod.isEmpty ? r.paymentStatus : r.paymentMethod,
        items: [
          ReceiptItem(
            itemName: '${r.providerName} recharge',
            quantity: 1,
            unitPrice: r.amount,
            totalAmount: r.amount,
          ),
        ],
        subTotal: r.amount,
        taxAmount: 0,
        grandTotal: r.amount,
      );

      final success = await printerNotifier.printReceipt(receipt);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Printed on ${printer.name}'
                : 'Print failed. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _sharePdf() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final r = _recharge;
      final invoice = r.invoiceNumber ?? 'provider-recharge';

      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(28),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Invoice Details',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text('Invoice: $invoice'),
                  pw.Text('Provider: ${r.providerName}'),
                  pw.Text('Category: ${r.categoryName}'),
                  if (r.submittedAt != null)
                    pw.Text('Date: ${formatReportDate(r.submittedAt!)}'),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    '${r.providerName} recharge',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('Grand Total: ${_money(r.amount)}'),
                  pw.Text('Paid Amount: ${_money(r.paidAmount)}'),
                  pw.Text('Balance Due: ${_money(r.balanceAmount)}'),
                  pw.Text('Payment Status: ${r.paymentStatus}'),
                ],
              ),
            );
          },
        ),
      );

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'Provider_$invoice.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to share invoice PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _payBalance() async {
    final r = _recharge;
    if (r.balanceAmount <= 0.01 || r.id == null) return;

    // Balance payments now go through the recharge form screen itself,
    // in its "settle balance" mode — same screen the customer's original
    // recharge was entered on, with everything except the payment amount
    // locked, instead of a separate split-tender screen.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderRechargeFormScreen(
          providerId: r.providerId,
          existingRecharge: r,
        ),
      ),
    );

    if (!mounted) return;

    if (result is ProviderRechargeModel) {
      setState(() => _recharge = result);
      ref.invalidate(providerRechargeHistoryProvider);
    } else if (result == true) {
      ref.invalidate(providerRechargeHistoryProvider);
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return const Color(0xFF2E7D32);
      case 'PARTIAL':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFFC62828);
    }
  }

  Color _statusBg(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return const Color(0xFFE8F5E9);
      case 'PARTIAL':
        return const Color(0xFFFFF3E0);
      default:
        return const Color(0xFFFFEBEE);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _recharge;
    final status = r.paymentStatus.toUpperCase();
    final statusColor = _statusColor(status);
    final statusBg = _statusBg(status);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        title: const Text('Invoice Details'),
        titleTextStyle: AppTextStyles.heading.copyWith(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w700,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          R.hPad(context, base: 20).left,
          R.sp(context, 4),
          R.hPad(context, base: 20).right,
          R.sp(context, 24),
        ),
        children: [
          ReportSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.invoiceNumber?.isNotEmpty == true
                            ? r.invoiceNumber!
                            : 'Provider Invoice',
                        style: AppTextStyles.cardValue.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: R.fs(context, 15),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: R.fs(context, 10),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: R.sp(context, 4)),
                Text(
                  '${r.providerName.isEmpty ? 'Provider' : r.providerName}'
                  ' • ${r.categoryName}'
                  '${r.submittedAt != null ? ' • ${formatReportDate(r.submittedAt!)}' : ''}',
                  style: AppTextStyles.small,
                ),
                SizedBox(height: R.sp(context, 18)),
                Text(
                  'LINE ITEMS PURCHASED',
                  style: AppTextStyles.small.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    fontSize: R.fs(context, 10.5),
                  ),
                ),
                SizedBox(height: R.sp(context, 4)),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: R.sp(context, 6),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          '${r.providerName} Recharge (x1)',
                          style: AppTextStyles.cardValue.copyWith(
                            fontSize: R.fs(context, 12.5),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          _money(r.amount),
                          textAlign: TextAlign.right,
                          style: AppTextStyles.cardValue.copyWith(
                            fontSize: R.fs(context, 12.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: R.sp(context, 12)),
                Text(
                  'BILLING METRICS',
                  style: AppTextStyles.small.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    fontSize: R.fs(context, 10.5),
                  ),
                ),
                SizedBox(height: R.sp(context, 8)),
                ReportKeyValueRow(
                  label: 'Subtotal Amount',
                  value: _money(r.amount),
                ),
                ReportKeyValueRow(
                  label: 'Discount Applied',
                  value: '- ${_money(0)}',
                  valueColor: AppColors.red,
                ),
                ReportKeyValueRow(
                  label: 'Taxes (GST Summary)',
                  value: '+ ${_money(0)}',
                ),
                const Divider(
                  height: 24,
                  thickness: 1,
                  color: Colors.black12,
                ),
                ReportKeyValueRow(
                  label: 'Grand Total',
                  value: _money(r.amount),
                  bold: true,
                ),
                SizedBox(height: R.sp(context, 4)),
                ReportKeyValueRow(
                  label: 'Paid Amount',
                  value: _money(r.paidAmount),
                  valueColor: const Color(0xFF2E7D32),
                  bold: true,
                ),
                SizedBox(height: R.sp(context, 4)),
                ReportKeyValueRow(
                  label: 'Balance Due',
                  value: _money(r.balanceAmount),
                  valueColor: r.balanceAmount > 0.01
                      ? AppColors.orange
                      : const Color(0xFF2E7D32),
                  bold: true,
                ),
              ],
            ),
          ),
          SizedBox(height: R.sp(context, AppSpacing.sm)),
          _gradientButton(
            context,
            icon: _isPrinting
                ? Icons.hourglass_top_rounded
                : Icons.print_rounded,
            label: _isPrinting
                ? 'Printing...'
                : 'Reprint Invoice Receipt',
            onPressed: _isPrinting ? null : _reprintReceipt,
          ),
          if (r.balanceAmount > 0.01) ...[
            SizedBox(height: R.sp(context, AppSpacing.sm)),
            _gradientButton(
              context,
              icon: Icons.payment_rounded,
              label: 'Balance Payment (${_money(r.balanceAmount)})',
              onPressed: _payBalance,
            ),
          ],
          SizedBox(height: R.sp(context, AppSpacing.sm)),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isSharing ? null : _sharePdf,
              icon: _isSharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share_rounded),
              label: const Text('Share Invoice PDF'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(
                  vertical: R.sp(context, 14),
                ),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    R.radius(context, AppSizes.radiusMd),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(
          R.radius(context, AppSizes.radiusMd),
        ),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: R.sp(context, 14)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              R.radius(context, AppSizes.radiusMd),
            ),
          ),
        ),
      ),
    );
  }
}
