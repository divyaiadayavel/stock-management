
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

import '../providers/report_extras_provider.dart';
import '../widgets/report_shared_widgets.dart';

class ServiceJobDetailsScreen extends ConsumerStatefulWidget {
  final String jobId;

  const ServiceJobDetailsScreen({
    super.key,
    required this.jobId,
  });

  @override
  ConsumerState<ServiceJobDetailsScreen> createState() =>
      _ServiceJobDetailsScreenState();
}

class _ServiceJobDetailsScreenState
    extends ConsumerState<ServiceJobDetailsScreen> {
  bool _isPrinting = false;

  String _mapStringValue(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') {
      return fallback;
    }

    return text;
  }

  String _answerLabel(dynamic answer) {
    if (answer is Map) {
      final map = Map<String, dynamic>.from(answer);

      return _mapStringValue(
        map['label'] ??
            map['question'] ??
            map['question_label'] ??
            map['field_label'] ??
            map['name'] ??
            map['title'],
        fallback: 'Answer',
      );
    }

    return 'Answer';
  }

  String _answerValue(dynamic answer) {
    if (answer is Map) {
      final map = Map<String, dynamic>.from(answer);

      final value =
          map['value'] ??
          map['answer'] ??
          map['answer_value'] ??
          map['field_value'] ??
          map['response'] ??
          map['selected_value'];

      if (value is List) {
        return value
            .map((item) => _mapStringValue(item))
            .where((item) => item.isNotEmpty)
            .join(', ');
      }

      if (value is Map) {
        final nested = Map<String, dynamic>.from(value);

        return _mapStringValue(
          nested['value'] ??
              nested['name'] ??
              nested['label'] ??
              nested['text'],
          fallback: nested.toString(),
        );
      }

      return _mapStringValue(value, fallback: '');
    }

    return _mapStringValue(answer);
  }

  List<Widget> _buildAnswerRows(
    BuildContext context,
    List<dynamic> answers,
  ) {
    if (answers.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: R.sp(context, 8),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'No answers recorded.',
              style: AppTextStyles.small.copyWith(
                fontSize: R.fs(context, 12),
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ];
    }

    final rows = <Widget>[];

    for (final answer in answers) {
      // Some APIs may return a grouped answer object such as:
      //
      // {
      //   "label": "...",
      //   "answers": [...]
      // }
      //
      // Handle that without assuming every item is a simple
      // label/value map.
      if (answer is Map && answer['answers'] is List) {
        final groupAnswers = answer['answers'] as List;

        if (groupAnswers.isNotEmpty) {
          for (final nestedAnswer in groupAnswers) {
            rows.add(
              ReportKeyValueRow(
                label: _answerLabel(nestedAnswer),
                value: _answerValue(nestedAnswer),
              ),
            );
          }

          continue;
        }
      }

      rows.add(
        ReportKeyValueRow(
          label: _answerLabel(answer),
          value: _answerValue(answer),
        ),
      );
    }

    return rows;
  }

  // ================================================================
  // BUILD THERMAL RECEIPT
  // Same existing Receipt system used by the Service invoice flow.
  // ================================================================
  Receipt _buildReceiptFromServiceJob(
    dynamic job,
    String? storeName,
    String? storeAddress,
    String? storePhone,
    String? gstNumber,
    String? logoPath,
  ) {
    final serviceName =
        job.serviceType.toString().trim().isEmpty
            ? 'Service Job'
            : job.serviceType.toString().trim();

    final amount = (job.serviceFee as num).toDouble();

    return Receipt(
      receiptId: widget.jobId,
      timestamp: job.date,
      cashierName: 'Staff',
      storeName: storeName,
      storeAddress: storeAddress,
      storePhone: storePhone,
      gstNumber: gstNumber,
      logoPath: logoPath,
      paymentMode: null,
      items: [
        ReceiptItem(
          itemName: serviceName,
          quantity: 1,
          unitPrice: amount,
          totalAmount: amount,
        ),
      ],
      subTotal: amount,
      taxAmount: 0,
      grandTotal: amount,
    );
  }

  // ================================================================
  // PRINT SERVICE SLIP
  // ================================================================
  Future<void> _printServiceSlip(
    BuildContext context,
    dynamic job,
  ) async {
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
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No printer set up yet. Add one in Settings → Printers & Hardware.',
            ),
          ),
        );

        return;
      }

      final profile =
          ref.read(settingsControllerProvider)
              .valueOrNull
              ?.profile;

      final receipt = _buildReceiptFromServiceJob(
        job,
        profile?.storeName,
        profile?.businessAddress,
        profile?.phoneNumber,
        profile?.gstNumber,
        profile?.logoPath,
      );

      final success =
          await printerNotifier.printReceipt(receipt);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Printed on ${printer.name}'
                : 'Print failed. Please try again.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to print service slip. Please try again.',
          ),
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

  @override
  Widget build(
    BuildContext context,
  ) {
    final detailAsync =
        ref.watch(
          serviceJobDetailProvider(widget.jobId),
        );

    return ReportScaffold(
      title: 'Service Slip Details',

      // IMPORTANT:
      // rangeLabel is intentionally omitted.
      // This removes "All Time (Live)" from the app bar.
      onRefresh: () async {
        ref.invalidate(
          serviceJobDetailProvider(widget.jobId),
        );
      },

      child: ReportAsyncView(
        value: detailAsync,
        builder: (context, job) {
          final answers = job.answers;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------------
              // SERVICE JOB HEADER
              // ----------------------------------------------------------
              ReportSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.serviceType.trim().isEmpty
                          ? 'Service Job'
                          : job.serviceType,
                      style: AppTextStyles.cardValue.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: R.fs(context, 15),
                      ),
                    ),
                    SizedBox(
                      height: R.sp(context, 4),
                    ),
                    Text(
                      'Service: ${job.serviceType.trim().isEmpty ? 'Service Job' : job.serviceType}',
                      style: AppTextStyles.small.copyWith(
                        fontSize: R.fs(context, 12),
                      ),
                    ),
                    SizedBox(
                      height: R.sp(context, 2),
                    ),
                    Text(
                      formatReportDate(job.date),
                      style: AppTextStyles.small.copyWith(
                        fontSize: R.fs(context, 12),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // ----------------------------------------------------------
              // DYNAMIC ANSWERS
              // ----------------------------------------------------------
              if (answers.isNotEmpty)
                ReportSectionCard(
                  title:
                      'DYNAMIC QUESTION ANSWERS (SCHEMA LINKED)',
                  child: Column(
                    children: _buildAnswerRows(
                      context,
                      answers,
                    ),
                  ),
                ),

              // ----------------------------------------------------------
              // ATTACHED DOCUMENT
              // ----------------------------------------------------------
              if (job.attachedDocument != null &&
                  job.attachedDocument
                      .toString()
                      .trim()
                      .isNotEmpty)
                ReportSectionCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.attach_file_rounded,
                        color: AppColors.primary,
                        size: R.icon(context, 16),
                      ),
                      SizedBox(
                        width: R.sp(context, 6),
                      ),
                      Expanded(
                        child: Text(
                          job.attachedDocument.toString(),
                          style:
                              AppTextStyles.cardValue.copyWith(
                            color: AppColors.primary,
                            fontSize: R.fs(context, 12),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              // ----------------------------------------------------------
              // SERVICE FEE
              // ----------------------------------------------------------
              ReportSectionCard(
                child: ReportKeyValueRow(
                  label: 'Total Service Charge',
                  value: formatRupee(job.serviceFee),
                  bold: true,
                ),
              ),

              SizedBox(
                height: R.sp(context, AppSpacing.sm),
              ),

              // ----------------------------------------------------------
              // PRINT BUTTON
              // ----------------------------------------------------------
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(
                    R.radius(
                      context,
                      AppSizes.radiusMd,
                    ),
                  ),
                ),
                child: ElevatedButton.icon(
                  onPressed: _isPrinting
                      ? null
                      : () {
                          _printServiceSlip(
                            context,
                            job,
                          );
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
                      : const Icon(
                          Icons.print_rounded,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isPrinting
                        ? 'Printing...'
                        : 'Print Service Slip',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor:
                        Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: R.sp(context, 14),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        R.radius(
                          context,
                          AppSizes.radiusMd,
                        ),
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

