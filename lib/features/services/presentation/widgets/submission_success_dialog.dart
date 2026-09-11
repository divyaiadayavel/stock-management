// lib/features/services/presentation/widgets/submission_success_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';

Future<void> showSubmissionSuccessDialog(
  BuildContext context, {
  required String invoiceNumber,
  String? formattedDateTime,
  required VoidCallback onViewReceipt,
}) {
  final now = DateTime.now();
  final defaultDateTime =
      formattedDateTime ??
      '${now.day.toString().padLeft(2, '0')} ${_getMonthName(now.month)} ${now.year}, ${_formatTime(now)}';

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(R.radius(context, 16)),
        ),
        contentPadding: EdgeInsets.all(R.sp(context, 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Green Success Badge ───
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFF16A34A),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
            const SizedBox(height: 16),

            // ─── Title & Subtitle ───
            Text(
              'Submitted Successfully!',
              style: TextStyle(
                fontSize: R.fs(context, 18),
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your request has been submitted successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: R.fs(context, 13),
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 18),

            // ─── Invoice Number Card with Copy ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Text(
                    'Invoice Number',
                    style: TextStyle(
                      fontSize: R.fs(context, 12),
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        invoiceNumber,
                        style: TextStyle(
                          fontSize: R.fs(context, 18),
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF16A34A),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: invoiceNumber));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              duration: Duration(seconds: 1),
                              content: Text(
                                'Invoice number copied to clipboard',
                              ),
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    defaultDateTime,
                    style: TextStyle(
                      fontSize: R.fs(context, 11),
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ─── Dual Action Buttons ───
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(dialogContext);
                      onViewReceipt();
                    },
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF16A34A),
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        'View Receipt',
                        style: TextStyle(
                          fontSize: R.fs(context, 13),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Back to List',
                        style: TextStyle(
                          fontSize: R.fs(context, 13),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

String _getMonthName(int month) {
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

String _formatTime(DateTime dt) {
  final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}
