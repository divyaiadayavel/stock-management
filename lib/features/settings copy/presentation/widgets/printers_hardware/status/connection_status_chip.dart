import 'package:flutter/material.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../domain/enums/printers_hardware/printer/printer_status.dart';
/// Small rounded chip showing the live [PrinterStatus] of a printer.
/// Used in printer list tiles and the details screen header.
class ConnectionStatusChip extends StatelessWidget {
  const ConnectionStatusChip({super.key, required this.status});

  final PrinterStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = _colors(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == PrinterStatus.connecting || status == PrinterStatus.printing)
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: fg,
              ),
            )
          else
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _colors(PrinterStatus s) {
    switch (s) {
      case PrinterStatus.connected:
        return (AppColors.green.withOpacity(0.12), AppColors.green);
      case PrinterStatus.connecting:
      case PrinterStatus.printing:
        return (AppColors.orange.withOpacity(0.12), AppColors.orange);
      case PrinterStatus.error:
        return (AppColors.red.withOpacity(0.12), AppColors.red);
      case PrinterStatus.busy:
        return (AppColors.orange.withOpacity(0.12), AppColors.orange);
      case PrinterStatus.offline:
      case PrinterStatus.disconnected:
        return (Colors.grey.shade200, Colors.grey.shade600);
    }
  }
}
