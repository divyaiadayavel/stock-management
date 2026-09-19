// lib/features/services/presentation/screens/provider_recharge_receipt_screen.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/validators.dart';
import '../../../settings/service_management/data/models/service_category_model.dart';
import '../../../settings/service_management/domain/enums/service_category_type.dart';
import '../../data/models/provider_recharge_model.dart';
import 'services_screen.dart';
import '../providers/services_provider.dart';

/// SCREEN 8 — "Receipt"
///
/// Invoice header, the answered details, the amount, and
/// Print / Download / Share — the same three actions (and the same pdf +
/// printing packages) the service receipt already uses.
class ProviderRechargeReceiptScreen extends ConsumerStatefulWidget {
  final ProviderRechargeModel recharge;

  const ProviderRechargeReceiptScreen({super.key, required this.recharge});

  @override
  ConsumerState<ProviderRechargeReceiptScreen> createState() =>
      _ProviderRechargeReceiptScreenState();
}

class _ProviderRechargeReceiptScreenState
    extends ConsumerState<ProviderRechargeReceiptScreen> {
  bool _isPrinting = false;
  bool _isDownloading = false;
  bool _isSharing = false;

  /// Local copy so the Paid/Balance rows below can use the
  /// current recharge data.
  late ProviderRechargeModel _recharge = widget.recharge;

  static String money(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final whole = parts.first;
    final buffer = StringBuffer();

    for (var i = 0; i < whole.length; i++) {
      buffer.write(whole[i]);

      final remaining = whole.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
    }

    return '₹${buffer.toString()}.${parts.last}';
  }

  String get _initials {
    final words = widget.recharge.providerName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.isEmpty) return 'PR';

    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }

    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? Colors.red.shade700 : const Color(0xFF16A34A),
        content: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PDF
  // ─────────────────────────────────────────────

  Future<Uint8List> _generatePdf() async {
    final r = _recharge;
    final pdf = pw.Document();

    pw.Widget row(String label, String value, {bool bold = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: bold ? 12 : 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                r.providerName,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Invoice #${r.invoiceNumber ?? '-'}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Divider(height: 24),

              ...r.answerModels.map(
                (a) => row(a.label, _displayAnswerValue(a.label, a.value)),
              ),

              pw.Divider(height: 24),

              row('Payment', '${r.paymentMethod} - ${r.paymentStatus}'),
              row('Balance before', money(r.balanceBefore)),
              row('Balance after', money(r.balanceAfter)),

              pw.SizedBox(height: 12),

              row('Amount recharged', money(r.amount), bold: true),
              row('Paid Amount', money(r.paidAmount)),
              row('Balance Due', money(r.balanceAmount), bold: true),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _print() async {
    if (_isPrinting) return;

    setState(() => _isPrinting = true);

    try {
      final bytes = await _generatePdf();

      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      _snack('Unable to print receipt: $e', error: true);
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  Future<void> _download() async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);

    try {
      final bytes = await _generatePdf();

      final directory = await getApplicationDocumentsDirectory();

      final invoice = widget.recharge.invoiceNumber ?? 'recharge';

      final file = File('${directory.path}/Recharge_$invoice.pdf');

      await file.writeAsBytes(bytes, flush: true);

      _snack('Saved to ${file.path}');
    } catch (e) {
      _snack('Unable to download receipt: $e', error: true);
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _share() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);

    try {
      final bytes = await _generatePdf();

      final invoice = widget.recharge.invoiceNumber ?? 'recharge';

      await Printing.sharePdf(bytes: bytes, filename: 'Recharge_$invoice.pdf');
    } catch (e) {
      _snack('Unable to share receipt: $e', error: true);
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _exitToProviderCategory() async {
    try {
      final categories = await ref.read(userServiceCategoriesProvider.future);

      ServiceCategoryModel? category;

      if (_recharge.categoryId != null) {
        for (final item in categories) {
          if (item.id == _recharge.categoryId &&
              item.type == ServiceCategoryType.provider) {
            category = item;
            break;
          }
        }
      }

      if (category == null) {
        for (final item in categories) {
          if (item.type == ServiceCategoryType.provider &&
              item.name.trim().toLowerCase() ==
                  _recharge.categoryName.trim().toLowerCase()) {
            category = item;
            break;
          }
        }
      }

      if (!mounted) return;

      if (category != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => CategoryProvidersViewScreen(
              category: category!,
              categoryColor: const Color(0xFF2563EB),
            ),
          ),
          (route) => route.isFirst,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ServicesScreen()),
          (route) => route.isFirst,
        );
      }
    } catch (_) {
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ServicesScreen()),
        (route) => route.isFirst,
      );
    }
  }

  // ─────────────────────────────────────────────
  // UI PIECES
  // ─────────────────────────────────────────────

  bool _isPaymentFieldLabel(String label) {
    final normalized = label.trim().toLowerCase().replaceAll('_', ' ');

    return normalized == 'payment status' || normalized == 'payment method';
  }

  String _displayAnswerValue(String label, String value) {
    final lower = label.toLowerCase();

    if (lower.contains('name') ||
        lower.contains('customer') ||
        lower.contains('user')) {
      return Validators.normalizeName(value);
    }

    return value;
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: R.sp(context, 8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: R.fs(context, 13),
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: R.fs(context, 13.5),
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _action({
    required IconData icon,
    required String label,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: loading ? null : onTap,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: R.sp(context, 4)),
          padding: EdgeInsets.symmetric(vertical: R.sp(context, 11)),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(R.radius(context, 10)),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: loading
              ? const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 16, color: const Color(0xFF475569)),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: R.fs(context, 12.5),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _recharge;
    final hPad = R.hPad(context, base: 20);

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              // ─── Header ───
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: hPad.left,
                  vertical: R.sp(context, 12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.black87,
                        size: 24,
                      ),
                      onPressed: _exitToProviderCategory,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Receipt',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                          fontSize: R.fs(context, 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Receipt card ───
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    hPad.left,
                    R.sp(context, 4),
                    hPad.left,
                    R.sp(context, 20),
                  ),
                  children: [
                    Container(
                      padding: EdgeInsets.all(R.sp(context, 18)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          R.radius(context, 16),
                        ),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Avatar
                          Container(
                            width: R.sp(context, 56),
                            height: R.sp(context, 56),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _initials,
                              style: TextStyle(
                                fontSize: R.fs(context, 18),
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          SizedBox(height: R.sp(context, 10)),

                          Text(
                            r.providerName,
                            style: TextStyle(
                              fontSize: R.fs(context, 16),
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),

                          SizedBox(height: R.sp(context, 3)),

                          Text(
                            'Invoice #${r.invoiceNumber ?? '—'}',
                            style: TextStyle(
                              fontSize: R.fs(context, 12),
                              color: const Color(0xFF94A3B8),
                            ),
                          ),

                          SizedBox(height: R.sp(context, 14)),

                          const Divider(height: 1, color: Color(0xFFF1F5F9)),

                          SizedBox(height: R.sp(context, 4)),

                          ...r.answerModels
                              .where((a) => !_isPaymentFieldLabel(a.label))
                              .map(
                                (a) => _detailRow(
                                  a.label,
                                  _displayAnswerValue(a.label, a.value),
                                ),
                              ),

                          _detailRow(
                            'Payment status',
                            r.paymentStatus.isEmpty ? '—' : r.paymentStatus,
                          ),

                          _detailRow(
                            'Payment method',
                            r.paymentMethod.isEmpty ? '—' : r.paymentMethod,
                          ),

                          SizedBox(height: R.sp(context, 6)),

                          const Divider(height: 1, color: Color(0xFFF1F5F9)),

                          SizedBox(height: R.sp(context, 14)),

                          Text(
                            money(r.amount),
                            style: TextStyle(
                              fontSize: R.fs(context, 26),
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF16A34A),
                            ),
                          ),

                          SizedBox(height: R.sp(context, 3)),

                          Text(
                            'Amount recharged',
                            style: TextStyle(
                              fontSize: R.fs(context, 12),
                              color: const Color(0xFF64748B),
                            ),
                          ),

                          if (r.paymentStatus.toUpperCase() != 'PAID') ...[
                            SizedBox(height: R.sp(context, 14)),

                            const Divider(height: 1, color: Color(0xFFF1F5F9)),

                            SizedBox(height: R.sp(context, 12)),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Paid amount',
                                  style: TextStyle(
                                    fontSize: R.fs(context, 13),
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  money(r.paidAmount),
                                  style: TextStyle(
                                    fontSize: R.fs(context, 13),
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: R.sp(context, 6)),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Balance amount',
                                  style: TextStyle(
                                    fontSize: R.fs(context, 13),
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFC62828),
                                  ),
                                ),
                                Text(
                                  money(r.balanceAmount),
                                  style: TextStyle(
                                    fontSize: R.fs(context, 15),
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFC62828),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          SizedBox(height: R.sp(context, 16)),

                          Row(
                            children: [
                              _action(
                                icon: Icons.print_outlined,
                                label: 'Print',
                                loading: _isPrinting,
                                onTap: _print,
                              ),
                              _action(
                                icon: Icons.download_outlined,
                                label: 'Download',
                                loading: _isDownloading,
                                onTap: _download,
                              ),
                              _action(
                                icon: Icons.share_outlined,
                                label: 'Share',
                                loading: _isSharing,
                                onTap: _share,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: R.sp(context, 14)),

                    // ─── Balance strip ───
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: R.sp(context, 14),
                        vertical: R.sp(context, 12),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(
                          R.radius(context, 10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Provider balance',
                            style: TextStyle(
                              fontSize: R.fs(context, 13),
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            '${money(r.balanceBefore)} → '
                            '${money(r.balanceAfter)}',
                            style: TextStyle(
                              fontSize: R.fs(context, 13),
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: R.sp(context, 12)),

                    // ─── Exit ───
                    SizedBox(
                      width: double.infinity,
                      height: R.sp(context, 48),
                      child: GestureDetector(
                        onTap: _exitToProviderCategory,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(
                              R.radius(context, 10),
                            ),
                          ),
                          child: Text(
                            'Exit',
                            style: TextStyle(
                              fontSize: R.fs(context, 14.5),
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
