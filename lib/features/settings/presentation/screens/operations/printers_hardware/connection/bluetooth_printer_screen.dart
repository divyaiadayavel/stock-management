import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../core/constants/app_sizes.dart';
import '../../../../../../../core/constants/app_spacing.dart';
import '../../../../../domain/entities/printers_hardware/printer/printer_capability.dart';
import '../../../../../domain/entities/printers_hardware/printer/printer_configuration.dart';
import '../../../../../domain/entities/printers_hardware/printer/printer_device.dart';
import '../../../../providers/printers_hardware/connection/bluetooth_provider.dart';
import '../../../../providers/printers_hardware/printer_management/printers_hardware_provider.dart';
import '../../../../../domain/enums/printers_hardware/printer/printer_connection_type.dart';
enum _BtStage { scanning, deviceSelected, connecting, connected, failed, permissionDenied }

/// Screens 02–06 — Bluetooth printer discovery & pairing.
///
/// A single screen that walks through: live scan results (02), the
/// "no printers found" empty state (03), a connect-confirmation card (04),
/// a connecting spinner (05) and the final connected success state (06).
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(_titleForStage(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
          // Defer the setState until after this build completes.
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
                  Icon(Icons.bluetooth_searching, size: 16, color: AppColors.cyanDim),
                const SizedBox(width: 10),
                Text(
                  isSearching ? 'Searching for nearby printers…' : 'Scan complete',
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
            child: Text(
              'Devices found · ${devices.length}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.2),
            ),
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
              onPressed: () => ref.read(bluetoothPrintersProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh, size: 17),
              label: const Text('Scan again', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _deviceRow(PrinterDevice device) {
    // Signal strength isn't part of the PrinterDevice entity, so default
    // to a neutral "available" indicator for now.
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.cyan.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Icon(Icons.bluetooth, size: 16, color: AppColors.cyanDim),
      ),
      title: Text(device.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
      subtitle: Row(
        children: [
          _signalBars(3),
          const SizedBox(width: 6),
          const Text('Available', style: TextStyle(fontSize: 9.5, color: AppColors.textSecondary)),
        ],
      ),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          textStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
        ),
        onPressed: () => setState(() {
          _selectedDevice = device;
          _stage = _BtStage.deviceSelected;
        }),
        child: const Text('Connect'),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(color: AppColors.surface2, shape: BoxShape.circle),
            child: Icon(Icons.search_off, size: 34, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          const Text('No printers found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 6),
          const Text(
            "Catalystack couldn't detect a printer nearby.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          _checkRow('Printer is switched on'),
          _checkRow('Bluetooth is enabled'),
          _checkRow('Printer is within range'),
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
              onPressed: () => ref.read(bluetoothPrintersProvider.notifier).refresh(),
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

  // ── Screen 04 — Connect confirmation ────────────────────────────────

  Widget _buildConfirm() {
    final device = _selectedDevice!;
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
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 8))],
            ),
            child: const Icon(Icons.print, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 12),
          Text(device.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: AppColors.cyan.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(999)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bluetooth, size: 12, color: AppColors.cyanDim),
                SizedBox(width: 4),
                Text('Bluetooth', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.cyanDim)),
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
            child: Column(
              children: [
                _specRow('Paper size', '${device.capabilities.paperWidthMm} mm'),
                const Divider(height: 1, indent: 14, endIndent: 14),
                _specRow('Signal strength', null, trailing: Row(children: [_signalBars(3), const SizedBox(width: 6), const Text('Excellent', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))])),
              ],
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
              child: const Text('Connect', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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
              onPressed: () => setState(() => _stage = _BtStage.scanning),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _specRow(String label, String? value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          trailing ?? Text(value ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
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
          const SizedBox(height: 40),
          SizedBox(
            width: 78,
            height: 78,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(
                  width: 78,
                  height: 78,
                  child: CircularProgressIndicator(strokeWidth: 4, color: AppColors.cyan),
                ),
                const Icon(Icons.print, color: AppColors.primary, size: 26),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('Connecting…', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          const Text('Please wait', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: const Text(
              'Keep your printer close to the device during connection.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: AppColors.cyanDim, fontWeight: FontWeight.w500),
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
          Text(
            '${_selectedDevice!.name} is ready to use.',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _switchRow(
                  icon: Icons.print,
                  label: 'Set as Default Printer',
                  value: _setAsDefault,
                  onChanged: (v) => setState(() => _setAsDefault = v),
                ),
                const Divider(height: 1, indent: 14, endIndent: 14),
                _switchRow(
                  icon: Icons.refresh,
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

  Widget _switchRow({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: AppColors.cyan.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 14, color: AppColors.cyanDim),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5))),
          Switch(
            value: value,
            activeColor: Colors.white,
            activeTrackColor: AppColors.primary,
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
          const SizedBox(height: 24),
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(color: AppColors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.bluetooth_disabled, color: AppColors.orange, size: 36),
          ),
          const SizedBox(height: 14),
          const Text('Bluetooth Permission Needed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          const Text(
            'Allow "Nearby devices" access so the app can find and connect to your printer.',
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
              onPressed: () => setState(() => _stage = _BtStage.scanning),
              child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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
              onPressed: () => openAppSettings(),
              child: const Text('Open App Settings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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
              onPressed: _connect,
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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
              onPressed: () => setState(() => _stage = _BtStage.scanning),
              child: const Text('Reconnect', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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