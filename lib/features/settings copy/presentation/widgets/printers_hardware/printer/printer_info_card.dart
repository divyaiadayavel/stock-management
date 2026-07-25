import 'package:flutter/material.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/printers_hardware/printer/printer_configuration.dart';
import '../../../../domain/entities/printers_hardware/printer/printer_device.dart';
import '../../../../domain/enums/printers_hardware/printer/printer_status.dart';
import '../../../widgets/printers_hardware/status/connection_status_chip.dart';
import '../../../../domain/enums/printers_hardware/printer/printer_connection_type.dart';
/// A prominent card showing a [PrinterDevice]'s full details —
/// used at the top of [PrinterDetailsScreen].
class PrinterInfoCard extends StatelessWidget {
  const PrinterInfoCard({
    super.key,
    required this.printer,
    required this.status,
  });

  final PrinterDevice printer;
  final PrinterStatus status;

  @override
  Widget build(BuildContext context) {
    final cfg = printer.configuration;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Big icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              _iconFor(cfg.connectionType),
              size: 26,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          // Details column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  printer.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _connectionDetail(cfg),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 8),
                ConnectionStatusChip(status: status),
              ],
            ),
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

  String _connectionDetail(PrinterConfiguration cfg) {
    switch (cfg.connectionType) {
      case PrinterConnectionType.bluetooth:
        return cfg.macAddress ?? 'Bluetooth';
      case PrinterConnectionType.wifi:
        final port = cfg.port != null ? ':${cfg.port}' : '';
        return '${cfg.ipAddress ?? 'Wi-Fi'}$port';
      case PrinterConnectionType.usb:
        if (cfg.vendorId != null && cfg.productId != null) {
          return 'VID: 0x${cfg.vendorId!.toRadixString(16).toUpperCase()}'
              '  PID: 0x${cfg.productId!.toRadixString(16).toUpperCase()}';
        }
        return 'USB';
      case PrinterConnectionType.ethernet:
        final port = cfg.port != null ? ':${cfg.port}' : '';
        return '${cfg.ipAddress ?? 'Ethernet'}$port';
      case PrinterConnectionType.system:
        return 'System Print';
    }
  }
}
