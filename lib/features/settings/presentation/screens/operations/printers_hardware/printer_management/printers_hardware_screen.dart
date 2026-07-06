import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../core/constants/app_sizes.dart';
import '../../../../../../../core/constants/app_spacing.dart';
import '../../../../../domain/entities/printers_hardware/printer/printer_device.dart';
import '../../../../providers/printers_hardware/printer_management/printers_hardware_provider.dart';
import '../../../../providers/printers_hardware/printer_management/printers_hardware_state.dart';
import '../connection/bluetooth_printer_screen.dart';
import '../connection/inkjet_printer_screen.dart';
import '../hardware/cash_drawer_screen.dart';
import '../history/print_history_screen.dart';
import '../printer_management/printer_details_screen.dart';
import '../receipt/receipt_settings_screen.dart';
import '../hardware/scanner_screen.dart';
import '../connection/usb_printer_screen.dart';
import '../connection/wifi_printer_screen.dart';
import '../../../../../domain/enums/printers_hardware/printer/printer_connection_type.dart';

class PrintersHardwareScreen extends ConsumerWidget {
  const PrintersHardwareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(printersHardwareProvider);
    final connected = state.connectedPrinter;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Printers & Hardware',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Add new printer',
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddPrinterSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(printersHardwareProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            _sectionLabel('Connected printer'),
            connected == null
                ? _noPrinterCard(context)
                : _connectedPrinterCard(context, ref, connected),
            const SizedBox(height: AppSpacing.xl),
            _sectionLabel('Quick actions'),
            _quickActionsGrid(context, ref, hasConnectedPrinter: connected != null),
            const SizedBox(height: AppSpacing.xl),
            _sectionLabel('Saved printers'),
            _savedPrintersCard(context, ref, state),
            const SizedBox(height: AppSpacing.xl),
            _sectionLabel('Other hardware'),
            _otherHardwareCard(context),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeightLg,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
              ),
              onPressed: () => _showAddPrinterSheet(context),
              icon: const Icon(Icons.search, size: 18),
              label: const Text(
                'Scan for printer',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 12),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.2,
          ),
        ),
      );

  Widget _noPrinterCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Icon(Icons.print_disabled, color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No printer connected',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                SizedBox(height: 2),
                Text(
                  'Scan to pair a Bluetooth, Wi-Fi or USB printer',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _connectedPrinterCard(
    BuildContext context,
    WidgetRef ref,
    PrinterDevice printer,
  ) {
    final type = printer.configuration.connectionType;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PrinterDetailsScreen(printer: printer),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: const Icon(Icons.print, color: Colors.white, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        printer.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _statusChip('Connected', AppColors.green),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Divider(height: 1),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_connectionLabel(type)} · ${printer.capabilities.paperWidthMm} mm',
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                ),
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await ref.read(printersHardwareProvider.notifier).printTestReceipt();
                    if (!context.mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text(ok ? 'Test receipt sent' : 'Print failed')),
                    );
                  },
                  child: const Text('Test print', style: TextStyle(fontSize: 11.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color),
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

  Widget _quickActionsGrid(BuildContext context, WidgetRef ref, {required bool hasConnectedPrinter}) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.65,
      children: [
        _quickActionTile(
          icon: Icons.search,
          label: 'Scan printer',
          onTap: () => _showAddPrinterSheet(context),
        ),
        _quickActionTile(
          icon: Icons.tune,
          label: 'Receipt settings',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReceiptSettingsScreen()),
            );
          },
        ),
        _quickActionTile(
          icon: Icons.receipt_long,
          label: 'Test print',
          onTap: () async {
            if (!hasConnectedPrinter) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Connect a printer first')),
              );
              return;
            }
            final messenger = ScaffoldMessenger.of(context);
            final ok = await ref.read(printersHardwareProvider.notifier).printTestReceipt();
            if (!context.mounted) return;
            messenger.showSnackBar(
              SnackBar(content: Text(ok ? 'Test receipt sent' : 'Print failed')),
            );
          },
        ),
        _quickActionTile(
          icon: Icons.history,
          label: 'Print history',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrintHistoryScreen()),
            );
          },
        ),
        _quickActionTile(
          icon: Icons.inventory_2_outlined,
          label: 'Manage printers',
          onTap: () => _showManagePrintersSheet(context, ref),
        ),
      ],
    );
  }

  Widget _quickActionTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(icon, size: 16, color: AppColors.cyanDim),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _savedPrintersCard(BuildContext context, WidgetRef ref, PrintersHardwareState state) {
    final connected = state.connectedPrinter;
    final printers = state.savedPrinters.isNotEmpty
        ? state.savedPrinters
        : connected == null
            ? <PrinterDevice>[]
            : <PrinterDevice>[connected];

    if (printers.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: const Text(
          'No printers saved yet. Scan and connect a printer to see it here.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < printers.length; i++) ...[
            if (i != 0) const Divider(height: 1, indent: 60),
            _savedPrinterRow(
              context,
              printers[i],
              isDefault: connected?.id == printers[i].id ||
                  (connected == null && i == 0),
            ),
          ],
        ],
      ),
    );
  }

  Widget _savedPrinterRow(BuildContext context, PrinterDevice printer, {required bool isDefault}) {
    final type = printer.configuration.connectionType;
    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PrinterDetailsScreen(printer: printer)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Icon(_iconForType(type), color: Colors.white, size: 17),
      ),
      title: Text(
        printer.name,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
      ),
      subtitle: Text(
        '${_connectionLabel(type)} · ${printer.capabilities.paperWidthMm} mm',
        style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
      ),
      trailing: isDefault
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Default',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            )
          : const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
    );
  }

  IconData _iconForType(PrinterConnectionType type) {
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

  Widget _otherHardwareCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
            leading: _hardwareIcon(Icons.qr_code_scanner, Colors.teal),
            title: const Text('Barcode Scanner', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
            subtitle: const Text('Not connected', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen())),
          ),
          const Divider(height: 1, indent: 60),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
            leading: _hardwareIcon(Icons.point_of_sale, Colors.green),
            title: const Text('Cash Drawer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
            subtitle: const Text('Not connected', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CashDrawerScreen())),
          ),
        ],
      ),
    );
  }

  Widget _hardwareIcon(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  void _showAddPrinterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const Text('Add a printer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 14),
                _sheetOption(
                  sheetContext,
                  icon: Icons.bluetooth,
                  title: 'Bluetooth printer',
                  subtitle: 'Pair a nearby thermal printer',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BluetoothPrinterScreen()));
                  },
                ),
                _sheetOption(
                  sheetContext,
                  icon: Icons.wifi,
                  title: 'Wi-Fi printer',
                  subtitle: 'Add a printer by IP address',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const WifiPrinterScreen()));
                  },
                ),
                _sheetOption(
                  sheetContext,
                  icon: Icons.usb,
                  title: 'USB printer',
                  subtitle: 'Connect a wired thermal printer',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const UsbPrinterScreen()));
                  },
                ),
                _sheetOption(
                  sheetContext,
                  icon: Icons.print,
                  title: 'Inkjet / Laser printer',
                  subtitle: 'Print half-page (A5) receipts via your OS print system',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const InkjetPrinterScreen()));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(icon, color: AppColors.cyanDim),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showManagePrintersSheet(BuildContext context, WidgetRef ref) {
    final state = ref.read(printersHardwareProvider);
    final connected = state.connectedPrinter;
    final printers = state.savedPrinters.isNotEmpty
        ? state.savedPrinters
        : connected == null
            ? <PrinterDevice>[]
            : <PrinterDevice>[connected];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(99)),
                  ),
                ),
                const Text('Manage printers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 14),
                if (printers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No saved printers yet.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...[
                    for (int i = 0; i < printers.length; i++) ...[
                      if (i != 0) const Divider(height: 1),
                      _savedPrinterRow(
                        context,
                        printers[i],
                        isDefault: connected?.id == printers[i].id ||
                            (connected == null && i == 0),
                      ),
                    ],
                  ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderStrong),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _showAddPrinterSheet(context);
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add New Printer'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}