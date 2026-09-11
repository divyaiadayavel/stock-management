import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../core/constants/app_sizes.dart';
import '../../../../../../../core/constants/app_spacing.dart';
import '../../../../../../../core/constants/app_text_styles.dart';
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
    // Dynamic string generation to match standard configurations securely
    _paperSize = '${widget.printer.capabilities.paperWidthMm} mm';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(printersHardwareProvider);
    final isConnected = state.connectedPrinter?.id == widget.printer.id;
    final type = widget.printer.configuration.connectionType;

    // FIX: Safely construct dropdown options so it dynamically accommodates document printers (like 148 mm A5)
    final List<String> paperOptions = ['58 mm', '80 mm'];
    if (!paperOptions.contains(_paperSize)) {
      paperOptions.add(_paperSize);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        title: Text(
          'Printer Details',
          style: AppTextStyles.cardValue.copyWith(
            fontSize: 22,
            fontFamily: AppTextStyles.fontDisplay,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              border: Border.all(color: AppColors.borderStrong),
            ),
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                  child: const Icon(Icons.print_rounded, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.printer.name, style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 6),
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
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              border: Border.all(color: AppColors.borderStrong),
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
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              border: Border.all(color: AppColors.borderStrong),
            ),
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              children: [
                _dropdownTile('Paper size', _paperSize, paperOptions, (v) => setState(() => _paperSize = v)),
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
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Settings saved')),
                      );
                    },
                    child: Text('Save Settings', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (!isConnected) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
                onPressed: () => _reconnectPrinter(context),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'Reconnect',
                  style: AppTextStyles.button.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          _sectionLabel('Test Print'),
          _TestPrintCard(printer: widget.printer),
          const SizedBox(height: AppSpacing.xl),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Column(
              children: [
                ListTile(
                  title: Text('Disconnect', style: AppTextStyles.cardValue.copyWith(color: AppColors.red, fontWeight: FontWeight.w700, fontSize: 14)),
                  onTap: isConnected
                      ? () async {
                          await ref.read(printersHardwareProvider.notifier).disconnect();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Printer disconnected')));
                          Navigator.pop(context);
                        }
                      : null,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.borderStrong),
                ListTile(
                  title: Text('Forget Device', style: AppTextStyles.cardValue.copyWith(color: AppColors.red, fontWeight: FontWeight.w700, fontSize: 14)),
                  onTap: () => _confirmForget(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  void _confirmForget(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
        title: Text('Forget this printer?', style: AppTextStyles.cardValue.copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text('${widget.printer.name} will be removed from your saved printers.', style: AppTextStyles.small.copyWith(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), 
            child: Text('Cancel', style: AppTextStyles.button.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: AppColors.textWhite,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
            ),
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);
              final removed = await ref
                  .read(printersHardwareProvider.notifier)
                  .removePrinter(widget.printer.id);
              navigator.pop();
              if (!context.mounted) return;
              if (removed) {
                messenger.showSnackBar(
                  SnackBar(content: Text('${widget.printer.name} removed')),
                );
                Navigator.pop(context);
              } else {
                final err = ref.read(printersHardwareProvider).errorMessage;
                messenger.showSnackBar(
                  SnackBar(content: Text(err ?? 'Could not remove printer')),
                );
              }
            },
            child: const Text('Forget'),
          ),
        ],
      ),
    );
  }

  Future<void> _reconnectPrinter(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref
        .read(printersHardwareProvider.notifier)
        .connectToPrinter(widget.printer);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? '${widget.printer.name} connected' : 'Reconnect failed'),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isConnected ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            isConnected ? 'Connected' : 'Disconnected',
            style: AppTextStyles.small.copyWith(fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
        child: Text(text, style: AppTextStyles.cardValue.copyWith(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimaryDark)),
      );

  Widget _divider() => const Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.borderStrong);

  Widget _specRow(String label, String value, {bool mono = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.small.copyWith(fontSize: 13, color: AppColors.textSecondary)),
          Text(
            value,
            style: AppTextStyles.cardValue.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimaryDark,
              fontFamily: mono ? 'JetBrains Mono' : AppTextStyles.fontBody,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownTile(String label, String value, List<String> options, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.small.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderStrong),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              color: AppColors.background,
            ),
            child: DropdownButton<String>(
              value: value,
              underline: const SizedBox.shrink(),
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textSecondary),
              style: AppTextStyles.cardValue.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
              items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
              onChanged: (v) => v != null ? onChanged(v) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AppTextStyles.small.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark))),
          Switch.adaptive(
            value: value,
            activeThumbColor: AppColors.textWhite,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: AppColors.textWhite,
            inactiveTrackColor: AppColors.borderStrong,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _stepperTile(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.small.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark)),
          Row(
            children: [
              _stepperButton(Icons.remove_rounded, () => onChanged(value > 1 ? value - 1 : 1)),
              SizedBox(
                width: 32, 
                child: Text('$value', textAlign: TextAlign.center, style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              _stepperButton(Icons.add_rounded, () => onChanged(value < 9 ? value + 1 : 9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppSizes.radiusSm)),
        child: Icon(icon, size: 18, color: AppColors.primary),
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.borderStrong),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
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
          width: 80,
          height: 80,
          decoration: BoxDecoration(color: AppColors.cyan.withValues(alpha: 0.08), shape: BoxShape.circle),
          child: const Icon(Icons.receipt_long_rounded, color: AppColors.cyanDim, size: 36),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Ready to print a sample receipt.', textAlign: TextAlign.center, style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 4),
        Text('This helps verify your printer setup.', style: AppTextStyles.small.copyWith(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.xl),
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
            onPressed: _printTest,
            child: Text('Print Test', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ],
    );
  }

  Widget _printing() {
    return Column(
      children: [
        const SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(strokeWidth: 4, color: AppColors.cyan),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Printing…', style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 4),
        Text('Sending receipt to the printer…', style: AppTextStyles.small.copyWith(fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _success() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: AppColors.green, size: 40),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Receipt Printed', style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 4),
        Text('Your printer is working correctly.', style: AppTextStyles.small.copyWith(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderStrong),
                    foregroundColor: AppColors.textPrimaryDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                  ),
                  onPressed: () => setState(() => _stage = _TestPrintStage.idle),
                  child: Text('Done', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                  ),
                  onPressed: _printTest,
                  child: Text('Print Again', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
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
          width: 80,
          height: 80,
          decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.close_rounded, color: AppColors.red, size: 40),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Printing Failed', style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 4),
        Text('Printer is disconnected or not responding.', textAlign: TextAlign.center, style: AppTextStyles.small.copyWith(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.xl),
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
            onPressed: _printTest,
            child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: () => setState(() => _stage = _TestPrintStage.idle),
          child: Text('Cancel', style: AppTextStyles.button.copyWith(color: AppColors.red, fontWeight: FontWeight.w700, fontSize: 14)),
        ),
      ],
    );
  }
}
