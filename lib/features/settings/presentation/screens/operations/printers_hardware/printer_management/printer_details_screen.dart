import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../core/constants/app_sizes.dart';
import '../../../../../../../core/constants/app_spacing.dart';
import '../../../../../domain/entities/printers_hardware/printer/printer_device.dart';
import '../../../../providers/printers_hardware/printer_management/printers_hardware_provider.dart';
import '../../../../../domain/enums/printers_hardware/printer/printer_connection_type.dart';

enum _TestPrintStage { idle, printing, success, failed }

class PrinterDetailsScreen extends ConsumerStatefulWidget {
  const PrinterDetailsScreen({super.key, required this.printer});

  final PrinterDevice printer;

  @override
  ConsumerState<PrinterDetailsScreen> createState() => _PrinterDetailsScreenState();
}

class _PrinterDetailsScreenState extends ConsumerState<PrinterDetailsScreen> {
  String _paperSize = '58 mm';
  int _copies = 1;
  bool _autoConnect = true;
  String _density = 'Medium';
  String _speed = 'Normal';
  String _cutPaper = 'Auto';
  String _cashDrawer = 'Off';

  @override
  void initState() {
    super.initState();
    _paperSize = '${widget.printer.capabilities.paperWidthMm} mm';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(printersHardwareProvider);
    final isConnected = state.connectedPrinter?.id == widget.printer.id;
    final type = widget.printer.configuration.connectionType;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Printer Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                  child: const Icon(Icons.print, color: Colors.white, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.printer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      const SizedBox(height: 4),
                      _statusChip(isConnected),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _specRow('Printer Name', widget.printer.name),
                _divider(),
                _specRow('Bluetooth Address', widget.printer.configuration.macAddress ?? '—', mono: true),
                _divider(),
                _specRow('IP Address', widget.printer.configuration.ipAddress ?? '—', mono: true),
                _divider(),
                _specRow('Paper Size', '${widget.printer.capabilities.paperWidthMm} mm'),
                _divider(),
                _specRow('Status', isConnected ? 'Connected' : 'Disconnected', valueColor: isConnected ? AppColors.green : AppColors.red),
                _divider(),
                _specRow('Connection Type', _connectionLabel(type)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _sectionLabel('Printer Settings'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              children: [
                _dropdownTile('Paper size', _paperSize, const ['58 mm', '80 mm'], (v) => setState(() => _paperSize = v)),
                const SizedBox(height: AppSpacing.sm),
                _stepperTile('Receipt copies', _copies, (v) => setState(() => _copies = v)),
                const SizedBox(height: AppSpacing.sm),
                _switchTile('Auto connect on app open', _autoConnect, (v) => setState(() => _autoConnect = v)),
                const SizedBox(height: AppSpacing.sm),
                _dropdownTile('Print density', _density, const ['Light', 'Medium', 'Dark'], (v) => setState(() => _density = v)),
                const SizedBox(height: AppSpacing.sm),
                _dropdownTile('Print speed', _speed, const ['Slow', 'Normal', 'Fast'], (v) => setState(() => _speed = v)),
                const SizedBox(height: AppSpacing.sm),
                _dropdownTile('Cut paper', _cutPaper, const ['Auto', 'Manual', 'Off'], (v) => setState(() => _cutPaper = v)),
                if (widget.printer.capabilities.supportsCashDrawerKick) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _dropdownTile('Cash drawer', _cashDrawer, const ['Off', 'On open', 'On print'], (v) => setState(() => _cashDrawer = v)),
                ],
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  height: AppSizes.buttonHeight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Settings saved')),
                      );
                    },
                    child: const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _sectionLabel('Test Print'),
          _TestPrintCard(printer: widget.printer),
          const SizedBox(height: AppSpacing.xl),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Disconnect', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600, fontSize: 12.5)),
                  onTap: isConnected
                      ? () async {
                          await ref.read(printersHardwareProvider.notifier).disconnect();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Printer disconnected')));
                          Navigator.pop(context);
                        }
                      : null,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  title: const Text('Forget Device', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600, fontSize: 12.5)),
                  onTap: () => _confirmForget(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  void _confirmForget(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusXl)),
        title: const Text('Forget this printer?'),
        content: Text('${widget.printer.name} will be removed from your saved printers.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              await ref.read(printersHardwareProvider.notifier).disconnect();
              navigator.pop();
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Forget', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  String _connectionLabel(PrinterConnectionType type) {
    switch (type) {
      case PrinterConnectionType.bluetooth:
        return 'Bluetooth';
      case PrinterConnectionType.wifi:
        return 'Wi-Fi';
      case PrinterConnectionType.usb:
        return 'USB';
      case PrinterConnectionType.ethernet:
        return 'Ethernet';
      case PrinterConnectionType.system:
        return 'System Print';
    }
  }

  Widget _statusChip(bool isConnected) {
    final color = isConnected ? AppColors.green : AppColors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isConnected ? Icons.check_circle : Icons.cancel, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            isConnected ? 'Connected' : 'Disconnected',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
      );

  Widget _divider() => const Divider(height: 1, indent: 14, endIndent: 14);

  Widget _specRow(String label, String value, {bool mono = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
              fontFamily: mono ? 'JetBrains Mono' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownTile(String label, String value, List<String> options, ValueChanged<String> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderStrong),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: DropdownButton<String>(
            value: value,
            underline: const SizedBox.shrink(),
            isDense: true,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black87),
            items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
            onChanged: (v) => v != null ? onChanged(v) : null,
          ),
        ),
      ],
    );
  }

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600))),
        Switch(
          value: value,
          activeColor: Colors.white,
          activeTrackColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _stepperTile(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
        Row(
          children: [
            _stepperButton(Icons.remove, () => onChanged(value > 1 ? value - 1 : 1)),
            SizedBox(width: 24, child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
            _stepperButton(Icons.add, () => onChanged(value < 9 ? value + 1 : 9)),
          ],
        ),
      ],
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 14, color: AppColors.primary),
      ),
    );
  }
}

class _TestPrintCard extends ConsumerStatefulWidget {
  const _TestPrintCard({required this.printer});

  final PrinterDevice printer;

  @override
  ConsumerState<_TestPrintCard> createState() => _TestPrintCardState();
}

class _TestPrintCardState extends ConsumerState<_TestPrintCard> {
  _TestPrintStage _stage = _TestPrintStage.idle;

  Future<void> _printTest() async {
    setState(() => _stage = _TestPrintStage.printing);
    final ok = await ref.read(printersHardwareProvider.notifier).printTestReceipt();
    if (!mounted) return;
    setState(() => _stage = ok ? _TestPrintStage.success : _TestPrintStage.failed);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: switch (_stage) {
        _TestPrintStage.idle => _idle(),
        _TestPrintStage.printing => _printing(),
        _TestPrintStage.success => _success(),
        _TestPrintStage.failed => _failed(),
      },
    );
  }

  Widget _idle() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(color: AppColors.cyan.withValues(alpha: 0.08), shape: BoxShape.circle),
          child: Icon(Icons.receipt_long, color: AppColors.cyanDim, size: 26),
        ),
        const SizedBox(height: 10),
        const Text('Ready to print a sample receipt.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 3),
        const Text('This helps verify your printer setup.', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: AppSizes.buttonHeight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
            ),
            onPressed: _printTest,
            child: const Text('Print Test', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _printing() {
    return Column(
      children: [
        const SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.cyan),
        ),
        const SizedBox(height: 12),
        const Text('Printing…', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 3),
        const Text('Sending receipt to the printer…', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _success() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.check, color: AppColors.green, size: 28),
        ),
        const SizedBox(height: 10),
        const Text('Receipt Printed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 3),
        const Text('Your printer is working correctly.', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.borderStrong),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
                ),
                onPressed: () => setState(() => _stage = _TestPrintStage.idle),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
                ),
                onPressed: _printTest,
                child: const Text('Print Again', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _failed() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.close, color: AppColors.red, size: 28),
        ),
        const SizedBox(height: 10),
        const Text('Printing Failed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 3),
        const Text('Printer is disconnected or not responding.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: AppSizes.buttonHeight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
            ),
            onPressed: _printTest,
            child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _stage = _TestPrintStage.idle),
          child: const Text('Cancel', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
      ],
    );
  }
}