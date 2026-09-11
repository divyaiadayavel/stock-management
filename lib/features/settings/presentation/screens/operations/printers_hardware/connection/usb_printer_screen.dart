import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../core/constants/app_sizes.dart';
import '../../../../../../../core/constants/app_spacing.dart';
import '../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../domain/entities/printers_hardware/printer/printer_device.dart';
import '../../../../providers/printers_hardware/printer_management/printers_hardware_provider.dart';
import '../../../../providers/printers_hardware/connection/usb_provider.dart';

enum _UsbStage { scanning, connecting, connected, failed }

class UsbPrinterScreen extends ConsumerStatefulWidget {
  const UsbPrinterScreen({super.key});

  @override
  ConsumerState<UsbPrinterScreen> createState() => _UsbPrinterScreenState();
}

class _UsbPrinterScreenState extends ConsumerState<UsbPrinterScreen> {
  _UsbStage _stage = _UsbStage.scanning;
  PrinterDevice? _selected;

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
          'USB Printer',
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
          _UsbStage.scanning => _buildScanning(),
          _UsbStage.connecting => _buildConnecting(),
          _UsbStage.connected => _buildConnected(),
          _UsbStage.failed => _buildFailed(),
        },
      ),
    );
  }

  Widget _buildScanning() {
    final scanState = ref.watch(usbPrintersProvider);

    return scanState.when(
      loading: () => _list(devices: const [], isSearching: true),
      error: (err, st) => _emptyState(),
      data: (devices) => devices.isEmpty ? _emptyState() : _list(devices: devices, isSearching: false),
    );
  }

  Widget _list({required List<PrinterDevice> devices, required bool isSearching}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.md, AppSpacing.screenPadding, 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Row(
              children: [
                if (isSearching)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.cyanDim),
                  )
                else
                  const Icon(Icons.usb, size: 16, color: AppColors.cyanDim),
                const SizedBox(width: 10),
                Text(
                  isSearching ? 'Checking for connected USB printers…' : 'Scan complete',
                  style: AppTextStyles.small.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.cyanDim),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Devices found · ${devices.length}',
              style: AppTextStyles.small.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            itemCount: devices.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 56, color: AppColors.borderStrong),
            itemBuilder: (context, i) => _deviceRow(devices[i]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 8, AppSpacing.screenPadding, AppSpacing.lg),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderStrong),
                foregroundColor: AppColors.textPrimaryDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
              ),
              onPressed: () => ref.read(usbPrintersProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh, size: 17),
              label: Text('Check again', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _deviceRow(PrinterDevice device) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.cyan.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
        child: const Icon(Icons.usb, size: 20, color: AppColors.cyanDim),
      ),
      title: Text(device.name, style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: Text('Wired · ready to pair', style: AppTextStyles.small.copyWith(fontSize: 11, color: AppColors.textSecondary)),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
        ),
        onPressed: () => _connect(device),
        child: Text('Connect', style: AppTextStyles.button.copyWith(fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 78,
            height: 78,
            decoration: const BoxDecoration(color: AppColors.surface2, shape: BoxShape.circle),
            child: const Icon(Icons.usb_off, size: 34, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('No USB printers found', style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            "Catalystack couldn't detect a wired printer.",
            textAlign: TextAlign.center,
            style: AppTextStyles.small.copyWith(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          _checkRow('Printer is switched on'),
          _checkRow('USB cable is firmly connected'),
          _checkRow('Printer drivers are installed'),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
              ),
              onPressed: () => ref.read(usbPrintersProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text('Try again', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 12, color: AppColors.green),
          ),
          const SizedBox(width: 8),
          Text(text, style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Future<void> _connect(PrinterDevice device) async {
    setState(() {
      _selected = device;
      _stage = _UsbStage.connecting;
    });
    final ok = await ref.read(printersHardwareProvider.notifier).connectToPrinter(device);
    if (!mounted) return;
    setState(() => _stage = ok ? _UsbStage.connected : _UsbStage.failed);
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(width: 78, height: 78, child: CircularProgressIndicator(strokeWidth: 4, color: AppColors.cyan)),
                Icon(Icons.usb_rounded, color: AppColors.primary, size: 30),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Connecting…', style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 20)),
          const SizedBox(height: 4),
          Text('Please wait', style: AppTextStyles.small.copyWith(fontSize: 14, color: AppColors.textSecondary)),
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
          Text('Printer Connected', style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            '${_selected?.name ?? 'Printer'} is ready to use.',
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
                messenger.showSnackBar(SnackBar(content: Text(ok ? 'Test receipt sent' : 'Print failed')));
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
          Text('Connection Failed', style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            'Printer is disconnected or not responding.',
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
              onPressed: () => _selected != null ? _connect(_selected!) : setState(() => _stage = _UsbStage.scanning),
              child: Text('Retry', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
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
              onPressed: () => setState(() => _stage = _UsbStage.scanning),
              child: Text('Reconnect', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTextStyles.button.copyWith(color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
