import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../core/constants/app_sizes.dart';
import '../../../../../../../core/constants/app_spacing.dart';
import '../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../domain/entities/printers_hardware/printer/printer_capability.dart';
import '../../../../../domain/entities/printers_hardware/printer/printer_configuration.dart';
import '../../../../../domain/entities/printers_hardware/printer/printer_device.dart';
import '../../../../providers/printers_hardware/connection/bluetooth_provider.dart';
import '../../../../providers/printers_hardware/printer_management/printers_hardware_provider.dart';
import '../../../../../domain/enums/printers_hardware/printer/printer_connection_type.dart';

enum _BtStage { scanning, deviceSelected, connecting, connected, failed, permissionDenied }

class BluetoothPrinterScreen extends ConsumerStatefulWidget {
  const BluetoothPrinterScreen({super.key});

  @override
  ConsumerState<BluetoothPrinterScreen> createState() => _BluetoothPrinterScreenState();
}

class _BluetoothPrinterScreenState extends ConsumerState<BluetoothPrinterScreen> {
  _BtStage _stage = _BtStage.scanning;
  PrinterDevice? _selectedDevice;
  bool _setAsDefault = true;
  bool _autoConnect = true;

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
          _titleForStage(),
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
          _BtStage.scanning => _buildScanning(),
          _BtStage.deviceSelected => _buildConfirm(),
          _BtStage.connecting => _buildConnecting(),
          _BtStage.connected => _buildConnected(),
          _BtStage.failed => _buildFailed(),
          _BtStage.permissionDenied => _buildPermissionDenied(),
        },
      ),
    );
  }

  String _titleForStage() {
    switch (_stage) {
      case _BtStage.scanning:
        return 'Scan Printers';
      case _BtStage.deviceSelected:
        return 'Connect Printer';
      case _BtStage.connecting:
        return 'Connect Printer';
      case _BtStage.connected:
        return 'Printer Connected';
      case _BtStage.failed:
        return 'Connection Failed';
      case _BtStage.permissionDenied:
        return 'Permission Needed';
    }
  }

  // ── Screen 02 / 03 — Scan results / empty state ─────────────────────

  Widget _buildScanning() {
    final scanState = ref.watch(bluetoothPrintersProvider);

    return scanState.when(
      loading: () => _scanningList(devices: const [], isSearching: true),
      error: (err, st) {
        if (err is BluetoothPermissionDeniedException) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _stage = _BtStage.permissionDenied);
          });
        }
        return _emptyState();
      },
      data: (devices) {
        if (devices.isEmpty) return _emptyState();
        return _scanningList(devices: devices, isSearching: false);
      },
    );
  }

  Widget _scanningList({required List<PrinterDevice> devices, required bool isSearching}) {
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
                  const Icon(Icons.bluetooth_searching, size: 16, color: AppColors.cyanDim),
                const SizedBox(width: 10),
                Text(
                  isSearching ? 'Searching for nearby printers…' : 'Scan complete',
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
              onPressed: () => ref.read(bluetoothPrintersProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh, size: 17),
              label: Text('Scan again', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
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
        decoration: BoxDecoration(
          color: AppColors.cyan.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: const Icon(Icons.bluetooth, size: 20, color: AppColors.cyanDim),
      ),
      title: Text(device.name, style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: Row(
        children: [
          _signalBars(3),
          const SizedBox(width: 6),
          Text('Available', style: AppTextStyles.small.copyWith(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
        ),
        onPressed: () => setState(() {
          _selectedDevice = device;
          _stage = _BtStage.deviceSelected;
        }),
        child: Text('Connect', style: AppTextStyles.button.copyWith(fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _signalBars(int strength) {
    final color = strength >= 3
        ? AppColors.green
        : strength == 2
            ? AppColors.orange
            : AppColors.red;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final active = i < strength + 1;
        return Container(
          width: 3,
          height: 4.0 + (i * 3),
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: active ? color : AppColors.borderStrong,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 78,
            height: 78,
            decoration: const BoxDecoration(color: AppColors.surface2, shape: BoxShape.circle),
            child: const Icon(Icons.search_off, size: 34, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('No printers found', style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            "Catalystack couldn't detect a printer nearby.",
            textAlign: TextAlign.center,
            style: AppTextStyles.small.copyWith(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          _checkRow('Printer is switched on'),
          _checkRow('Bluetooth is enabled'),
          _checkRow('Printer is within range'),
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
              onPressed: () => ref.read(bluetoothPrintersProvider.notifier).refresh(),
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

  // ── Screen 04 — Connect confirmation ────────────────────────────────

  Widget _buildConfirm() {
    final device = _selectedDevice!;
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
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: const Icon(Icons.print_rounded, color: AppColors.textPrimaryDark, size: 40),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(device.name, style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.cyan.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bluetooth, size: 14, color: AppColors.cyanDim),
                SizedBox(width: 4),
                Text('Bluetooth', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.cyanDim)),
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
            child: Column(
              children: [
                _specRow('Paper size', '${device.capabilities.paperWidthMm} mm'),
                const Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.borderStrong),
                _specRow('Signal strength', null, trailing: Row(children: [_signalBars(3), const SizedBox(width: 6), Text('Excellent', style: AppTextStyles.small.copyWith(fontSize: 12, fontWeight: FontWeight.w700))])),
              ],
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
              child: Text('Connect', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
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
              onPressed: () => setState(() => _stage = _BtStage.scanning),
              child: Text('Cancel', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _specRow(String label, String? value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.small.copyWith(fontSize: 13, color: AppColors.textSecondary)),
          trailing ?? Text(value ?? '', style: AppTextStyles.cardValue.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Screen 05 — Connecting ───────────────────────────────────────────

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
                SizedBox(
                  width: 78,
                  height: 78,
                  child: CircularProgressIndicator(strokeWidth: 4, color: AppColors.cyan),
                ),
                Icon(Icons.print_rounded, color: AppColors.primary, size: 30),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Connecting…', style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 20)),
          const SizedBox(height: 4),
          Text('Please wait', style: AppTextStyles.small.copyWith(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xxl),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Text(
              'Keep your printer close to the device during connection.',
              textAlign: TextAlign.center,
              style: AppTextStyles.small.copyWith(fontSize: 13, color: AppColors.cyanDim, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connect() async {
    setState(() => _stage = _BtStage.connecting);
    final ok = await ref.read(printersHardwareProvider.notifier).connectToPrinter(_selectedDevice!);
    if (!mounted) return;
    setState(() => _stage = ok ? _BtStage.connected : _BtStage.failed);
  }

  // ── Screen 06 — Connected ────────────────────────────────────────────

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
            '${_selectedDevice!.name} is ready to use.',
            style: AppTextStyles.small.copyWith(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Column(
              children: [
                _switchRow(
                  icon: Icons.print_rounded,
                  label: 'Set as Default Printer',
                  value: _setAsDefault,
                  onChanged: (v) => setState(() => _setAsDefault = v),
                ),
                const Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.borderStrong),
                _switchRow(
                  icon: Icons.refresh_rounded,
                  label: 'Auto Connect',
                  value: _autoConnect,
                  onChanged: (v) => setState(() => _autoConnect = v),
                ),
              ],
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

  Widget _switchRow({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.cyan.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 18, color: AppColors.cyanDim),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w600, fontSize: 14))),
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

  // ── Permission denied ────────────────────────────────────────────────

  Widget _buildPermissionDenied() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: AppColors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.bluetooth_disabled_rounded, color: AppColors.orange, size: 40),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Bluetooth Permission Needed', style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            'Allow "Nearby devices" access so the app can find and connect to your printer.',
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
              onPressed: () => setState(() => _stage = _BtStage.scanning),
              child: Text('Try Again', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
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
              onPressed: () => openAppSettings(),
              child: Text('Open App Settings', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Failed (timeout / connect error) ────────────────────────────────

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
              onPressed: _connect,
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
              onPressed: () => setState(() => _stage = _BtStage.scanning),
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

/// Helper used by other screens (printer details) to build a [PrinterDevice]
/// preview without needing a live scan result.
PrinterDevice buildMockBluetoothDevice(String name) {
  return PrinterDevice(
    id: name,
    name: name,
    configuration: const PrinterConfiguration(connectionType: PrinterConnectionType.bluetooth),
    capabilities: const PrinterCapability(paperWidthMm: 58),
  );
}
