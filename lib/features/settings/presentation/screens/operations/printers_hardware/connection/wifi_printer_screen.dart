import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../core/constants/app_sizes.dart';
import '../../../../../../../core/constants/app_spacing.dart';
import '../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../domain/entities/printers_hardware/printer/printer_capability.dart';
import '../../../../../domain/entities/printers_hardware/printer/printer_configuration.dart';
import '../../../../../domain/entities/printers_hardware/printer/printer_device.dart';
import '../../../../providers/printers_hardware/printer_management/printers_hardware_provider.dart';
import '../../../../providers/printers_hardware/connection/wifi_provider.dart';
import '../../../../../domain/enums/printers_hardware/printer/printer_connection_type.dart';

enum _WifiMode { scan, manual }

class WifiPrinterScreen extends ConsumerStatefulWidget {
  const WifiPrinterScreen({super.key});

  @override
  ConsumerState<WifiPrinterScreen> createState() => _WifiPrinterScreenState();
}

class _WifiPrinterScreenState extends ConsumerState<WifiPrinterScreen> {
  _WifiMode _mode = _WifiMode.scan;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Office Wi-Fi Printer');
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '9100');
  String _paperSize = '80 mm';
  bool _isConnecting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

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
          'Add Wi-Fi Printer',
          style: AppTextStyles.cardValue.copyWith(
            fontSize: 22,
            fontFamily: AppTextStyles.fontDisplay,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _modeToggle(),
            Expanded(
              child: _mode == _WifiMode.scan ? _buildScan() : _buildManual(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _mode == _WifiMode.manual ? _manualBottomBar() : null,
    );
  }

  // ── Mode toggle ────────────────────────────────────────────────────────

  Widget _modeToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.md, AppSpacing.screenPadding, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        child: Row(
          children: [
            Expanded(child: _modeTab('Scan Network', Icons.wifi_find, _WifiMode.scan)),
            Expanded(child: _modeTab('Enter IP Manually', Icons.edit_outlined, _WifiMode.manual)),
          ],
        ),
      ),
    );
  }

  Widget _modeTab(String label, IconData icon, _WifiMode mode) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          boxShadow: selected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.small.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Scan mode ──────────────────────────────────────────────────────────

  Widget _buildScan() {
    final scanState = ref.watch(wifiPrintersProvider);

    return scanState.when(
      loading: () => _scanList(devices: const [], isSearching: true, error: null),
      error: (err, st) => _scanList(devices: const [], isSearching: false, error: err.toString()),
      data: (devices) => _scanList(devices: devices, isSearching: false, error: null),
    );
  }

  Widget _scanList({required List<PrinterDevice> devices, required bool isSearching, String? error}) {
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
                  const Icon(Icons.wifi_find, size: 16, color: AppColors.cyanDim),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isSearching
                        ? 'Scanning your network for printers…'
                        : (error != null ? 'Scan failed' : 'Scan complete'),
                    style: AppTextStyles.small.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.cyanDim),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 4, AppSpacing.screenPadding, 0),
            child: Text(error, style: AppTextStyles.small.copyWith(fontSize: 11, color: AppColors.red)),
          ),
        if (devices.isEmpty && !isSearching)
          Expanded(child: _emptyScanState())
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Printers found · ${devices.length}', style: AppTextStyles.small.copyWith(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              itemCount: devices.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 56, color: AppColors.borderStrong),
              itemBuilder: (context, i) => _deviceRow(devices[i]),
            ),
          ),
        ],
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
              onPressed: isSearching ? null : () => ref.read(wifiPrintersProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh, size: 17),
              label: Text('Scan again', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _deviceRow(PrinterDevice device) {
    final ip = device.configuration.ipAddress ?? '';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.cyan.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
        child: const Icon(Icons.print_outlined, size: 20, color: AppColors.cyanDim),
      ),
      title: Text(device.name, style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: Text(
        '$ip · port ${device.configuration.port ?? 9100}',
        style: AppTextStyles.small.copyWith(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'JetBrains Mono'),
      ),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
        ),
        onPressed: () => _connectDevice(device),
        child: Text('Connect', style: AppTextStyles.button.copyWith(fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _emptyScanState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: const BoxDecoration(color: AppColors.surface2, shape: BoxShape.circle),
            child: const Icon(Icons.wifi_off, size: 34, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('No network printers found', style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            "We checked your Wi-Fi network's usual printer port (9100) and didn't find one.",
            textAlign: TextAlign.center,
            style: AppTextStyles.small.copyWith(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          _checkRow('Printer is powered on'),
          _checkRow('Phone and printer are on the same Wi-Fi'),
          _checkRow("Printer's network mode is enabled"),
          const SizedBox(height: AppSpacing.xl),
          TextButton(
            onPressed: () => setState(() => _mode = _WifiMode.manual),
            child: Text('Enter the IP address manually instead', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
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

  Future<void> _connectDevice(PrinterDevice device) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(printersHardwareProvider.notifier).connectToPrinter(device);
    if (!mounted) return;
    if (ok) {
      messenger.showSnackBar(SnackBar(content: Text('${device.name} connected')));
      Navigator.pop(context);
    } else {
      final err = ref.read(printersHardwareProvider).errorMessage;
      messenger.showSnackBar(SnackBar(content: Text(err ?? 'Could not connect to that printer')));
    }
  }

  // ── Manual mode ────────────────────────────────────────────────────────

  Widget _buildManual() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Text(
              "Find the printer's IP from its network settings page or a printed status ticket.",
              style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.cyanDim, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _fieldLabel('Printer name'),
          _textField(
            controller: _nameController,
            hint: 'e.g. Office Wi-Fi Printer',
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a printer name' : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          _fieldLabel('IP address'),
          _textField(
            controller: _ipController,
            hint: '192.168.1.100',
            monospace: true,
            keyboardType: TextInputType.number,
            validator: _validateIp,
          ),
          const SizedBox(height: AppSpacing.lg),
          _fieldLabel('Port'),
          _textField(
            controller: _portController,
            hint: '9100',
            monospace: true,
            keyboardType: TextInputType.number,
            validator: _validatePort,
          ),
          const SizedBox(height: AppSpacing.lg),
          _fieldLabel('Paper size'),
          _dropdownField(),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _manualBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 8, AppSpacing.screenPadding, AppSpacing.screenPadding),
        child: Row(
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
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700)),
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
                  onPressed: _isConnecting ? null : _connectManual,
                  child: _isConnecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.textWhite),
                        )
                      : Text('Connect', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text,
          style: AppTextStyles.small.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    bool monospace = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: AppTextStyles.cardValue.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: monospace ? 'JetBrains Mono' : AppTextStyles.fontBody,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.small.copyWith(fontSize: 14),
        filled: true,
        fillColor: AppColors.surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.red),
        ),
      ),
    );
  }

  Widget _dropdownField() {
    return DropdownButtonFormField<String>(
      initialValue: _paperSize,
      items: const ['58 mm', '80 mm']
          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: AppTextStyles.cardValue.copyWith(fontSize: 14))))
          .toList(),
      onChanged: (v) => setState(() => _paperSize = v ?? _paperSize),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  String? _validateIp(String? value) {
    final v = value?.trim() ?? '';
    final regex = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');
    final match = regex.firstMatch(v);
    if (match == null) return 'Enter a valid IP address';
    for (int i = 1; i <= 4; i++) {
      final octet = int.tryParse(match.group(i)!) ?? -1;
      if (octet < 0 || octet > 255) return 'Enter a valid IP address';
    }
    return null;
  }

  String? _validatePort(String? value) {
    final v = value?.trim() ?? '';
    final port = int.tryParse(v);
    if (port == null || port < 1 || port > 65535) return 'Enter a valid port (1-65535)';
    return null;
  }

  Future<void> _connectManual() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isConnecting = true);

    final device = PrinterDevice(
      id: '${_ipController.text.trim()}:${_portController.text.trim()}',
      name: _nameController.text.trim(),
      configuration: PrinterConfiguration(
        connectionType: PrinterConnectionType.wifi,
        ipAddress: _ipController.text.trim(),
        port: int.tryParse(_portController.text.trim()) ?? 9100,
      ),
      capabilities: PrinterCapability(paperWidthMm: _paperSize == '58 mm' ? 58 : 80),
    );

    final ok = await ref.read(printersHardwareProvider.notifier).connectToPrinter(device);

    if (!mounted) return;
    setState(() => _isConnecting = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${device.name} connected')),
      );
      Navigator.pop(context);
    } else {
      final err = ref.read(printersHardwareProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Could not reach the printer at that address')),
      );
    }
  }
}