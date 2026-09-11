// lib/features/reports/presentation/screens/invoice_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/responsive_helper.dart';

import '../../../settings/domain/entities/printers_hardware/receipt/receipt.dart';
import '../../../settings/domain/entities/printers_hardware/receipt/receipt_item.dart';
import '../../../settings/presentation/providers/printers_hardware/printer_management/printers_hardware_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

import '../../domain/entities/report_extras.dart';
import '../providers/report_extras_provider.dart';
import '../widgets/report_shared_widgets.dart';
import '../../../sales/presentation/screens/payment_screen.dart';

class InvoiceDetailsScreen extends ConsumerStatefulWidget {
  final String invoiceId;

  const InvoiceDetailsScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoiceDetailsScreen> createState() =>
      _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends ConsumerState<InvoiceDetailsScreen> {
  bool _isPrinting = false;

  Future<void> _reprintReceipt(InvoiceDetail inv) async {
    if (_isPrinting) return;

    setState(() => _isPrinting = true);

    try {
      final printerNotifier = ref.read(printersHardwareProvider.notifier);

      final printer = await printerNotifier.ensureDefaultPrinterLoaded();

      if (printer == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(
            content: Text(
              'No printer set up yet. Add one in Settings → Printers & Hardware.',
            ),
          ),
        );
        return;
      }

      final profile = ref.read(settingsControllerProvider).valueOrNull?.profile;

      final receipt = Receipt(
        receiptId: inv.invoiceId.isEmpty ? widget.invoiceId : inv.invoiceId,
        timestamp: inv.date,
        cashierName: 'Staff',
        storeName: profile?.storeName,
        storeAddress: profile?.businessAddress,
        storePhone: profile?.phoneNumber,
        gstNumber: profile?.gstNumber,
        logoPath: profile?.logoPath,
        paymentMode: inv.paymentMode,
        items: inv.items.map((item) {
          final map = item is Map<String, dynamic> ? item : <String, dynamic>{};

          final productName = (map['product_name'] ?? 'Item').toString();

          final quantity =
              double.tryParse((map['quantity'] ?? '1').toString()) ?? 1.0;

          final unitPrice =
              double.tryParse(
                (map['price'] ??
                        map['unit_price'] ??
                        map['selling_price'] ??
                        '0')
                    .toString(),
              ) ??
              0.0;

          final total =
              double.tryParse(
                (map['total'] ?? map['line_total'] ?? '0').toString(),
              ) ??
              0.0;

          return ReceiptItem(
            itemName: productName,
            quantity: quantity.round(),
            unitPrice: unitPrice,
            totalAmount: total,
          );
        }).toList(),
        subTotal: inv.subtotal - inv.discount,
        taxAmount: inv.taxGst,
        grandTotal: inv.grandTotal,
      );

      final success = await printerNotifier.printReceipt(receipt);

      if (!mounted) return;

      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Printed on ${printer.name}'
                : 'Print failed. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  void _sharePdf(BuildContext context, InvoiceDetail inv) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating PDF for ${inv.invoiceId}...'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(invoiceDetailProvider(widget.invoiceId));

    return ReportScaffold(
      title: 'Invoice Details',

      // IMPORTANT:
      // Invoice details is a detail screen, so no report
      // period/filter chip should be displayed.
      rangeLabel: null,

      onRefresh: () async {
        ref.invalidate(invoiceDetailProvider(widget.invoiceId));
      },

      child: ReportAsyncView<InvoiceDetail>(
        value: detailAsync,
        builder: (context, inv) {
          // InvoiceDetail now carries the real paidAmount / balanceAmount /
          // paymentStatus straight from the backend (same columns used
          // everywhere else in the app) — no more guessing at property
          // names that didn't exist on this model.
          final double paid = inv.paidAmount;
          final double due = inv.balanceAmount;
          final paymentStatus = inv.paymentStatus.toUpperCase();

          final isPaid = paymentStatus == 'PAID';
          final isPartial = paymentStatus == 'PARTIAL';
          final isPending = paymentStatus == 'PENDING';

          final statusColor = isPaid
              ? const Color(0xFF2E7D32)
              : isPartial
              ? const Color(0xFFE65100)
              : const Color(0xFFC62828);

          final statusBgColor = isPaid
              ? const Color(0xFFE8F5E9)
              : isPartial
              ? const Color(0xFFFFF3E0)
              : const Color(0xFFFFEBEE);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================================
              // COMPLETE INVOICE DETAILS
              // Header + Line Items + Billing Metrics
              // ALL INSIDE ONE CONTAINER
              // ==========================================================
              ReportSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ----------------------------------------------------
                    // INVOICE HEADER
                    // ----------------------------------------------------
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            inv.invoiceId.isEmpty
                                ? widget.invoiceId
                                : inv.invoiceId,
                            style: AppTextStyles.cardValue.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: R.fs(context, 15),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        SizedBox(width: R.sp(context, 8)),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            paymentStatus,
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
                      '${inv.customerName.isEmpty ? 'Walk-in Customer' : inv.customerName} • ${formatReportDate(inv.date)}',
                      style: AppTextStyles.small,
                    ),

                    // ----------------------------------------------------
                    // LINE ITEMS
                    // ----------------------------------------------------
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

                    ...inv.items.map((item) {
                      final map = item is Map<String, dynamic>
                          ? item
                          : <String, dynamic>{};

                      final productName = map['product_name'] ?? 'Item';

                      final qty =
                          double.tryParse(
                            (map['quantity'] ?? '1').toString(),
                          ) ??
                          1.0;

                      final lineTotal =
                          double.tryParse(
                            (map['total'] ?? map['line_total'] ?? '0')
                                .toString(),
                          ) ??
                          0.0;

                      final quantityText = qty % 1 == 0
                          ? qty.toStringAsFixed(0)
                          : qty.toStringAsFixed(2);

                      return Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: R.sp(context, 6),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                '$productName (x$quantityText)',
                                style: AppTextStyles.cardValue.copyWith(
                                  fontSize: R.fs(context, 12.5),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            SizedBox(width: R.sp(context, 8)),

                            Expanded(
                              flex: 1,
                              child: Text(
                                formatRupee(lineTotal),
                                textAlign: TextAlign.right,
                                style: AppTextStyles.cardValue.copyWith(
                                  fontSize: R.fs(context, 12.5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // ----------------------------------------------------
                    // BILLING METRICS
                    // ----------------------------------------------------
                    SizedBox(height: R.sp(context, 12)),

                    Text(
                      'BILLING METRICS',
                      style: AppTextStyles.small.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        fontSize: R.fs(context, 10.5),
                      ),
                    ),

                    SizedBox(height: R.sp(context, 4)),

                    ReportKeyValueRow(
                      label: 'Subtotal Amount',
                      value: formatRupee(inv.subtotal),
                    ),

                    ReportKeyValueRow(
                      label: 'Discount Applied',
                      value: '- ${formatRupee(inv.discount)}',
                      valueColor: AppColors.red,
                    ),

                    ReportKeyValueRow(
                      label: 'Taxes (GST Summary)',
                      value: '+ ${formatRupee(inv.taxGst)}',
                    ),

                    const Divider(
                      height: 24,
                      thickness: 1,
                      color: Colors.black12,
                    ),

                    ReportKeyValueRow(
                      label: 'Grand Total',
                      value: formatRupee(inv.grandTotal),
                      bold: true,
                    ),

                    if (paid > 0.01) ...[
                      SizedBox(height: R.sp(context, 4)),
                      ReportKeyValueRow(
                        label: 'Paid Amount',
                        value: formatRupee(paid),
                        valueColor: const Color(0xFF2E7D32),
                        bold: true,
                      ),
                    ],

                    if (due > 0.01) ...[
                      SizedBox(height: R.sp(context, 4)),
                      ReportKeyValueRow(
                        label: 'Balance Due',
                        value: formatRupee(due),
                        valueColor: AppColors.orange,
                        bold: true,
                      ),
                    ],

                    // ----------------------------------------------------
                    // SPLIT PAYMENT
                    // ----------------------------------------------------
                    if (inv.paymentMode.toUpperCase().contains('SPLIT') &&
                        (inv.splitCashAmount != null ||
                            inv.splitUpiAmount != null))
                      Padding(
                        padding: EdgeInsets.only(top: R.sp(context, 4)),
                        child: Text(
                          'Split: '
                          '${formatRupee(inv.splitCashAmount ?? 0)} '
                          'Cash + '
                          '${formatRupee(inv.splitUpiAmount ?? 0)} '
                          'UPI',
                          style: AppTextStyles.small,
                        ),
                      ),
                  ],
                ),
              ),

              // ==========================================================
              // REPRINT BUTTON
              // ==========================================================
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(
                    R.radius(context, AppSizes.radiusMd),
                  ),
                ),
                child: ElevatedButton.icon(
                  onPressed: _isPrinting
                      ? null
                      : () {
                          _reprintReceipt(inv);
                        },
                  icon: _isPrinting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.print_rounded, color: Colors.white),
                  label: Text(
                    _isPrinting ? 'Printing...' : 'Reprint Invoice Receipt',
                  ),
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
              ),

              if (due > 0.01) ...[
                SizedBox(height: R.sp(context, AppSpacing.sm)),
                // ==========================================================
                // BALANCE PAYMENT BUTTON
                // ==========================================================
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(
                      R.radius(context, AppSizes.radiusMd),
                    ),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final settled = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentScreen(
                            totalAmount: due,
                            existingSaleId: inv.saleId,
                            existingCustomerName: inv.customerName,
                            existingInvoiceNumber: inv.invoiceId,
                          ),
                        ),
                      );

                      // Back from the Payment screen with a recorded
                      // payment: reload this invoice so it shows the
                      // fresh PAID / PARTIAL / PENDING status, and let
                      // the Sales Report list know too.
                      if (settled == true && mounted) {
                        ref.invalidate(invoiceDetailProvider(widget.invoiceId));
                        ref.invalidate(salesReportsProvider);
                      }
                    },
                    icon: const Icon(
                      Icons.payment_rounded,
                      color: Colors.white,
                    ),
                    label: Text('Balance Payment (${formatRupee(due)})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: R.sp(context, 14),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          R.radius(context, AppSizes.radiusMd),
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              SizedBox(height: R.sp(context, AppSpacing.sm)),

              // ==========================================================
              // SHARE PDF BUTTON
              // ==========================================================
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _sharePdf(context, inv);
                  },
                  icon: const Icon(
                    Icons.share_rounded,
                    color: AppColors.primary,
                  ),
                  label: const Text('Share Invoice PDF'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    padding: EdgeInsets.symmetric(vertical: R.sp(context, 14)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        R.radius(context, AppSizes.radiusMd),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
