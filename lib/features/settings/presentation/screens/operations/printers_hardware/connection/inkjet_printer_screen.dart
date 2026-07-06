import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../core/constants/app_sizes.dart';
import '../../../../../../../core/constants/app_spacing.dart';
import '../../../../../domain/entities/printers_hardware/printer/printer_capability.dart';
import '../../../../../domain/entities/printers_hardware/printer/printer_configuration.dart';
import '../../../../../domain/entities/printers_hardware/printer/printer_device.dart';
import '../../../../../domain/enums/printers_hardware/printer/printer_connection_type.dart';
import '../../../../providers/printers_hardware/printer_management/printers_hardware_provider.dart';

enum _InkjetStage { confirm, connecting, connected, failed }

/// Inkjet/laser printers (Canon, HP, Epson document printers, etc.) are
/// addressed through the device's OS print system rather than a direct
/// socket connection — there's no list of nearby devices to scan for.
/// Printing opens the native print dialog, where the user picks the exact
/// printer (Wi-Fi, AirPrint, or USB-attached via its print service).
///
/// This screen just registers that "system printing" is the chosen path
/// for the default printer; actual printer selection happens per print job.
class InkjetPrinterScreen extends ConsumerStatefulWidget {
  const InkjetPrinterScreen({super.key});

  @override
  ConsumerState<InkjetPrinterScreen> createState() => _InkjetPrinterScreenState();
}

class _InkjetPrinterScreenState extends ConsumerState<InkjetPrinterScreen> {
  _InkjetStage _stage = _InkjetStage.confirm;

  static const PrinterDevice _device = PrinterDevice(
    id: 'system-printer',
    name: 'Document Printer',
    configuration: PrinterConfiguration(connectionType: PrinterConnectionType.system),
    capabilities: PrinterCapability(
      paperWidthMm: 148, // A5 short edge
      supports58mm: false,
      supports80mm: false,
      supportsA4: true,
      supportsLetter: true,
      supportsBarcode: false,
      supportsQrCode: false,
      supportsCashDrawerKick: false,
      supportsPdf: true,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Document Printer', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: SafeArea(
        child: switch (_stage) {
          _InkjetStage.confirm => _buildConfirm(),
          _InkjetStage.connecting => _buildConnecting(),
          _InkjetStage.connected => _buildConnected(),
          _InkjetStage.failed => _buildFailed(),
        },
      ),
    );
  }

  Widget _buildConfirm() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: const Icon(Icons.print, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 12),
          const Text('Document Printer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: AppColors.cyan.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(999)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.print_outlined, size: 12, color: AppColors.cyanDim),
                SizedBox(width: 4),
                Text('Inkjet / Laser (A5)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.cyanDim)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: const Text(
              'Uses your printer’s normal Wi-Fi/USB print service (Canon, HP, Epson, '
              'Brother, etc.). Each time you print, you’ll pick the exact printer from '
              'your device’s print dialog — receipts are formatted for half-page (A5) paper.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeightLg,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
              ),
              onPressed: _connect,
              child: const Text('Use This Printer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeightLg,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderStrong),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnecting() {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          SizedBox(height: 40),
          SizedBox(
            width: 78,
            height: 78,
            child: CircularProgressIndicator(strokeWidth: 4, color: AppColors.cyan),
          ),
          SizedBox(height: 18),
          Text('Setting up…', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildConnected() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check, color: AppColors.green, size: 36),
          ),
          const SizedBox(height: 14),
          const Text('Document Printer Ready', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          const Text(
            'Test Print will open your device’s print dialog.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeightLg,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final ok = await ref.read(printersHardwareProvider.notifier).printTestReceipt();
                if (!context.mounted) return;
                messenger.showSnackBar(SnackBar(content: Text(ok ? 'Sent to print dialog' : 'Print failed')));
              },
              child: const Text('Test Print', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeightLg,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderStrong),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailed() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.close, color: AppColors.red, size: 36),
          ),
          const SizedBox(height: 14),
          const Text('Setup Failed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          const Text(
            'Could not register the document printer on this device.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeightLg,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
              ),
              onPressed: _connect,
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connect() async {
    setState(() => _stage = _InkjetStage.connecting);
    final ok = await ref.read(printersHardwareProvider.notifier).connectToPrinter(_device);
    if (!mounted) return;
    setState(() => _stage = ok ? _InkjetStage.connected : _InkjetStage.failed);
  }
}
