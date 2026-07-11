import 'package:flutter/material.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/printers_hardware/printer/printer_device.dart';
import '../../../../domain/enums/printers_hardware/printer/printer_status.dart';
import '../../../widgets/printers_hardware/status/connection_status_chip.dart';
import '../../../../domain/enums/printers_hardware/printer/printer_connection_type.dart';
/// A compact list tile for a [PrinterDevice] in the saved-printers list.
///
/// Shows name, connection type badge, and live [status].
/// [onTap] opens the details screen; [onDelete] removes the printer.
class PrinterTile extends StatelessWidget {
  const PrinterTile({
    super.key,
    required this.printer,
    required this.status,
    this.isDefault = false,
    this.onTap,
    this.onDelete,
  });

  final PrinterDevice printer;
  final PrinterStatus status;
  final bool isDefault;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            // Connection type icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _iconFor(printer.configuration.connectionType),
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            // Name + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          printer.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  ConnectionStatusChip(status: status),
                ],
              ),
            ),
            // Delete button
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Colors.redAccent),
                onPressed: onDelete,
                tooltip: 'Remove printer',
              ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
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
