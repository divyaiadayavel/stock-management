import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../core/constants/app_sizes.dart';
import '../../../../../../../core/constants/app_spacing.dart';
import '../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../domain/entities/printers_hardware/printer/printer_capability.dart';
import '../../../../../domain/entities/printers_hardware/printer/printer_configuration.dart';
import '../../../../../domain/entities/printers_hardware/printer/printer_device.dart';
import '../../../../../domain/enums/printers_hardware/printer/printer_connection_type.dart';
import '../../../../../domain/enums/printers_hardware/printer/printer_type.dart';
import '../../../../providers/printers_hardware/printer_management/printers_hardware_provider.dart';

enum _InkjetStage { confirm, connecting, connected, failed }

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
    configuration: PrinterConfiguration(
      connectionType: PrinterConnectionType.system,
      type: PrinterType.document,
    ),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        title: Text(
          'Document Printer',
          style: AppTextStyles.cardValue.copyWith(
            fontSize: 22,
            fontFamily: AppTextStyles.fontDisplay,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
          ),
        ),
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
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              border: Border.all(color: AppColors.borderStrong),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.print_rounded, color: AppColors.textPrimaryDark, size: 40),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Document Printer', style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.cyan.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.print_outlined, size: 14, color: AppColors.cyanDim),
                SizedBox(width: 4),
                Text('Inkjet / Laser (A5)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.cyanDim)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              border: Border.all(color: AppColors.borderStrong),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Uses your printer’s normal Wi-Fi/USB print service (Canon, HP, Epson, '
              'Brother, etc.). Each time you print, you’ll pick the exact printer from '
              'your device’s print dialog — receipts are formatted for half-page (A5) paper.',
              style: AppTextStyles.small.copyWith(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
              ),
              onPressed: _connect,
              child: Text('Use This Printer', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderStrong),
                foregroundColor: AppColors.textPrimaryDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnecting() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          const SizedBox(height: 60),
          const SizedBox(
            width: 78,
            height: 78,
            child: CircularProgressIndicator(strokeWidth: 4, color: AppColors.cyan),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Setting up…', style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 20)),
        ],
      ),
    );
  }

  Widget _buildConnected() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: AppColors.green, size: 40),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Document Printer Ready', style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            'Test Print will open your device’s print dialog.',
            textAlign: TextAlign.center,
            style: AppTextStyles.small.copyWith(fontSize: 14, color: AppColors.textSecondary),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final ok = await ref.read(printersHardwareProvider.notifier).printTestReceipt();
                if (!context.mounted) return;
                messenger.showSnackBar(SnackBar(content: Text(ok ? 'Sent to print dialog' : 'Print failed')));
              },
              child: Text('Test Print', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderStrong),
                foregroundColor: AppColors.textPrimaryDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text('Done', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
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
          const SizedBox(height: AppSpacing.xxl),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.close_rounded, color: AppColors.red, size: 40),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Setup Failed', style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            'Could not register the document printer on this device.',
            textAlign: TextAlign.center,
            style: AppTextStyles.small.copyWith(fontSize: 14, color: AppColors.textSecondary),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
              ),
              onPressed: _connect,
              child: Text('Retry', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
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
