import 'package:flutter/material.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/printers_hardware/printer/printer_device.dart';
import '../../../../domain/enums/printers_hardware/printer/printer_connection_type.dart';
/// A list tile shown during a BT/WiFi/USB scan for a [PrinterDevice]
/// that has been discovered but not yet connected.
///
/// Tapping the tile calls [onTap] so the parent screen can start
/// the connect flow.
class DiscoveredPrinterTile extends StatelessWidget {
  const DiscoveredPrinterTile({
    super.key,
    required this.printer,
    required this.onTap,
  });

  final PrinterDevice printer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    printer.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitleFor(printer),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
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

  String _subtitleFor(PrinterDevice p) {
    final cfg = p.configuration;
    switch (cfg.connectionType) {
      case PrinterConnectionType.bluetooth:
        return cfg.macAddress ?? 'Bluetooth';
      case PrinterConnectionType.wifi:
        final port = cfg.port != null ? ':${cfg.port}' : '';
        return '${cfg.ipAddress ?? ''}$port';
      case PrinterConnectionType.usb:
        return 'USB device';
      case PrinterConnectionType.ethernet:
        final port = cfg.port != null ? ':${cfg.port}' : '';
        return '${cfg.ipAddress ?? ''}$port';
      case PrinterConnectionType.system:
        return 'System print';
    }
  }
}
