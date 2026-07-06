import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../core/constants/app_sizes.dart';
import '../../../../../../../core/constants/app_spacing.dart';
import '../../../../../domain/entities/printers_hardware/printer/printer_device.dart';
import '../../../../providers/printers_hardware/printer_management/printers_hardware_provider.dart';
import '../../../../providers/printers_hardware/connection/usb_provider.dart';

enum _UsbStage { scanning, connecting, connected, failed }

/// USB printer discovery & pairing — same flow shape as the Bluetooth
/// screens (02/05/06), simplified since USB has no signal strength and
/// devices appear the moment they're plugged in rather than via scan.
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('USB Printer', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
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
                  Icon(Icons.usb, size: 16, color: AppColors.cyanDim),
                const SizedBox(width: 10),
                Text(
                  isSearching ? 'Checking for connected USB printers…' : 'Scan complete',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.cyanDim),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Devices found · ${devices.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: devices.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
            itemBuilder: (context, i) => _deviceRow(devices[i]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderStrong),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
              ),
              onPressed: () => ref.read(usbPrintersProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh, size: 17),
              label: const Text('Check again', style: TextStyle(fontWeight: FontWeight.w600)),
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
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: AppColors.cyan.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
        child: Icon(Icons.usb, size: 16, color: AppColors.cyanDim),
      ),
      title: Text(device.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
      subtitle: const Text('Wired · ready to pair', style: TextStyle(fontSize: 9.5, color: AppColors.textSecondary)),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          textStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
        ),
        onPressed: () => _connect(device),
        child: const Text('Connect'),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(color: AppColors.surface2, shape: BoxShape.circle),
            child: Icon(Icons.usb_off, size: 34, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          const Text('No USB printers found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 6),
          const Text(
            "Catalystack couldn't detect a wired printer.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          _checkRow('Printer is switched on'),
          _checkRow('USB cable is firmly connected'),
          _checkRow('Printer drivers are installed'),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeightLg,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
              ),
              onPressed: () => ref.read(usbPrintersProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try again', style: TextStyle(fontWeight: FontWeight.w600)),
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
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 11, color: AppColors.green),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
          const SizedBox(height: 40),
          SizedBox(
            width: 78,
            height: 78,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(width: 78, height: 78, child: CircularProgressIndicator(strokeWidth: 4, color: AppColors.cyan)),
                const Icon(Icons.usb, color: AppColors.primary, size: 26),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('Connecting…', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          const Text('Please wait', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
          const Text('Printer Connected', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text('${_selected?.name ?? 'Printer'} is ready to use.', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
                messenger.showSnackBar(SnackBar(content: Text(ok ? 'Test receipt sent' : 'Print failed')));
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
          const Text('Connection Failed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          const Text(
            'Printer is disconnected or not responding.',
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
              onPressed: () => _selected != null ? _connect(_selected!) : setState(() => _stage = _UsbStage.scanning),
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}