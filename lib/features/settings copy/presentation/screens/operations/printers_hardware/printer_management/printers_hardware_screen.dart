import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../core/constants/app_sizes.dart';
import '../../../../../../../core/constants/app_spacing.dart';
import '../../../../../../../core/constants/app_text_styles.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        title: Text(
          'Printers & Hardware',
          style: AppTextStyles.cardValue.copyWith(
            fontSize: 22,
            fontFamily: AppTextStyles.fontDisplay,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add new printer',
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            onPressed: () => _showAddPrinterSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(printersHardwareProvider);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.md,
          ),
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
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 8, AppSpacing.screenPadding, AppSpacing.screenPadding),
          child: SizedBox(
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
              onPressed: () => _showAddPrinterSheet(context),
              icon: const Icon(Icons.search_rounded, size: 20),
              label: Text(
                'Scan for printer',
                style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
        child: Text(
          text,
          style: AppTextStyles.cardValue.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
      );

  Widget _noPrinterCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.borderStrong),
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.surface2,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.print_disabled_rounded, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No printer connected',
                  style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Scan to pair a Bluetooth, Wi-Fi or USB printer',
                  style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.textSecondary),
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
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.borderStrong),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PrinterDetailsScreen(printer: printer),
              ),
            ),
            child: Padding(
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
                    child: const Icon(Icons.print_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          printer.name,
                          style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        _statusChip('Connected', AppColors.green),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderStrong, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.cardPadding, 4, AppSpacing.cardPadding, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_connectionLabel(type)} · ${printer.capabilities.paperWidthMm} mm',
                  style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await ref.read(printersHardwareProvider.notifier).printTestReceipt();
                    if (!context.mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text(ok ? 'Test receipt sent' : 'Print failed')),
                    );
                  },
                  child: Text('Test print', style: AppTextStyles.button.copyWith(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w700)),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.small.copyWith(fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.3),
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
      childAspectRatio: 2.1,
      children: [
        _quickActionTile(
          icon: Icons.search_rounded,
          label: 'Scan printer',
          onTap: () => _showAddPrinterSheet(context),
        ),
        _quickActionTile(
          icon: Icons.tune_rounded,
          label: 'Receipt settings',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReceiptSettingsScreen()),
            );
          },
        ),
        _quickActionTile(
          icon: Icons.receipt_long_rounded,
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
          icon: Icons.history_rounded,
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
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.borderStrong),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Icon(icon, size: 16, color: AppColors.cyanDim),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardValue.copyWith(
                    fontSize: 13, 
                    fontWeight: FontWeight.w600, 
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ),
            ],
          ),
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
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          border: Border.all(color: AppColors.borderStrong),
        ),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Text(
          'No printers saved yet. Scan and connect a printer to see it here.',
          style: AppTextStyles.small.copyWith(fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }

    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.borderStrong),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Column(
        children: [
          for (int i = 0; i < printers.length; i++) ...[
            if (i != 0) const Divider(height: 1, indent: 60, color: AppColors.borderStrong),
            _savedPrinterRow(
              context,
              printers[i],
              isDefault: connected?.id == printers[i].id || (connected == null && i == 0),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Icon(_iconForType(type), color: AppColors.textPrimaryDark, size: 18),
      ),
      title: Text(
        printer.name,
        style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      subtitle: Text(
        '${_connectionLabel(type)} · ${printer.capabilities.paperWidthMm} mm',
        style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: isDefault
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Default',
                style: AppTextStyles.small.copyWith(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            )
          : const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
    );
  }

  IconData _iconForType(PrinterConnectionType type) {
    switch (type) {
      case PrinterConnectionType.bluetooth:
        return Icons.bluetooth_rounded;
      case PrinterConnectionType.wifi:
        return Icons.wifi_rounded;
      case PrinterConnectionType.usb:
        return Icons.usb_rounded;
      case PrinterConnectionType.ethernet:
        return Icons.settings_ethernet_rounded;
      case PrinterConnectionType.system:
        return Icons.print_rounded;
    }
  }

  Widget _otherHardwareCard(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.borderStrong),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding, vertical: 2),
            leading: _hardwareIcon(Icons.qr_code_scanner_rounded, Colors.teal),
            title: Text('Barcode Scanner', style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text('Not connected', style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen())),
          ),
          const Divider(height: 1, indent: 60, color: AppColors.borderStrong),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding, vertical: 2),
            leading: _hardwareIcon(Icons.point_of_sale_rounded, AppColors.green),
            title: Text('Cash Drawer', style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text('Not connected', style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CashDrawerScreen())),
          ),
        ],
      ),
    );
  }

  Widget _hardwareIcon(IconData icon, Color color) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  void _showAddPrinterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.borderStrong,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Text('Add a printer', style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: AppSpacing.lg),
                _sheetOption(
                  sheetContext,
                  icon: Icons.bluetooth_rounded,
                  title: 'Bluetooth printer',
                  subtitle: 'Pair a nearby thermal printer',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BluetoothPrinterScreen()));
                  },
                ),
                _sheetOption(
                  sheetContext,
                  icon: Icons.wifi_rounded,
                  title: 'Wi-Fi printer',
                  subtitle: 'Add a printer by IP address',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const WifiPrinterScreen()));
                  },
                ),
                _sheetOption(
                  sheetContext,
                  icon: Icons.usb_rounded,
                  title: 'USB printer',
                  subtitle: 'Connect a wired thermal printer',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const UsbPrinterScreen()));
                  },
                ),
                _sheetOption(
                  sheetContext,
                  icon: Icons.print_rounded,
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
                color: AppColors.cyan.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(icon, color: AppColors.cyanDim, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(subtitle, style: AppTextStyles.small.copyWith(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
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
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: AppColors.borderStrong, borderRadius: BorderRadius.circular(99)),
                  ),
                ),
                Text('Manage printers', style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: AppSpacing.lg),
                if (printers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No saved printers yet.',
                      style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.textSecondary),
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
                      foregroundColor: AppColors.textPrimaryDark,
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