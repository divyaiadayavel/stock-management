import 'package:flutter/material.dart';

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/printers_hardware/printer/printer_device.dart';
import '../../../../domain/enums/printers_hardware/printer/printer_status.dart';
import '../../../widgets/printers_hardware/status/connection_status_chip.dart';
import '../../../../domain/enums/printers_hardware/printer/printer_connection_type.dart';
/// A full-width card for the currently-connected (default) printer,
/// displayed at the top of [PrintersHardwareScreen].
///
/// Provides quick [onPrint] and [onDisconnect] action buttons.
class PrinterCard extends StatelessWidget {
  const PrinterCard({
    super.key,
    required this.printer,
    required this.status,
    this.onPrint,
    this.onDisconnect,
    this.onViewDetails,
  });

  final PrinterDevice printer;
  final PrinterStatus status;
  final VoidCallback? onPrint;
  final VoidCallback? onDisconnect;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconFor(printer.configuration.connectionType),
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      printer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    ConnectionStatusChip(status: status),
                  ],
                ),
              ),
              if (onViewDetails != null)
                TextButton(
                  onPressed: onViewDetails,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('Details',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: status.isConnected ? onPrint : null,
                  icon: const Icon(Icons.print_outlined, size: 16),
                  label: const Text('Test Print'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDisconnect,
                  icon: const Icon(Icons.link_off, size: 16),
                  label: const Text('Disconnect'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(
                        color: Colors.redAccent.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFor(PrinterConnectionType type) {
    switch (type) {
      case PrinterConnectionType.bluetooth:
        return Icons.bluetooth;
      case PrinterConnectionType.wifi:
        return Icons.wifi;
      case PrinterConnectionType.usb:
        return Icons.usb;
      case PrinterConnectionType.ethernet:
        return Icons.lan;
      case PrinterConnectionType.system:
        return Icons.print;
    }
  }
}
