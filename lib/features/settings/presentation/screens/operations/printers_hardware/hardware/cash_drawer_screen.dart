import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../core/constants/app_sizes.dart';
import '../../../../../../../core/constants/app_spacing.dart';
import '../../../../providers/printers_hardware/printer_management/printers_hardware_provider.dart';

enum _DrawerStage { idle, opening, success, failed }

/// Cash drawer control screen.
///
/// A cash drawer doesn't pair on its own — it's kicked open through the
/// connected receipt printer's drawer port — so this screen surfaces the
/// printer link, an open/test action, and an auto-open-on-sale toggle.
class CashDrawerScreen extends ConsumerStatefulWidget {
  const CashDrawerScreen({super.key});

  @override
  ConsumerState<CashDrawerScreen> createState() => _CashDrawerScreenState();
}

class _CashDrawerScreenState extends ConsumerState<CashDrawerScreen> {
  _DrawerStage _stage = _DrawerStage.idle;
  bool _openOnSale = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(printersHardwareProvider);
    final printer = state.connectedPrinter;
    final supportsKick = printer?.capabilities.supportsCashDrawerKick ?? false;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Cash Drawer', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: const Icon(Icons.point_of_sale, color: AppColors.green, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        printer == null ? 'No printer connected' : 'Linked via ${printer.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        printer == null
                            ? 'Connect a printer that supports a drawer kick'
                            : supportsKick
                                ? 'Drawer-kick supported'
                                : 'This printer does not support a drawer kick',
                        style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(child: _stageContent(printer != null && supportsKick)),
          const SizedBox(height: AppSpacing.xl),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text('Open drawer automatically on cash sale', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                Switch(
                  value: _openOnSale,
                  activeColor: Colors.white,
                  activeTrackColor: AppColors.primary,
                  onChanged: (printer != null && supportsKick) ? (v) => setState(() => _openOnSale = v) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stageContent(bool canOpen) {
    switch (_stage) {
      case _DrawerStage.idle:
        return Column(
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(color: AppColors.surface2, shape: BoxShape.circle),
              child: Icon(Icons.point_of_sale, size: 32, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text('Test the drawer kick', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            const Text(
              'Sends a pulse to open the drawer right now.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: AppSizes.buttonHeightLg,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
                ),
                onPressed: canOpen ? _openDrawer : null,
                icon: const Icon(Icons.lock_open, size: 18),
                label: const Text('Open Drawer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ],
        );
      case _DrawerStage.opening:
        return const Column(
          children: [
            SizedBox(width: 78, height: 78, child: CircularProgressIndicator(strokeWidth: 4, color: AppColors.cyan)),
            SizedBox(height: 16),
            Text('Opening…', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        );
      case _DrawerStage.success:
        return Column(
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check, color: AppColors.green, size: 34),
            ),
            const SizedBox(height: 16),
            const Text('Drawer Opened', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _stage = _DrawerStage.idle),
              child: const Text('Test again', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      case _DrawerStage.failed:
        return Column(
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.close, color: AppColors.red, size: 34),
            ),
            const SizedBox(height: 16),
            const Text('Could not open drawer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('Check the printer connection and try again.', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _stage = _DrawerStage.idle),
              child: const Text('Try again', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
    }
  }

  Future<void> _openDrawer() async {
    setState(() => _stage = _DrawerStage.opening);
    try {
      await ref.read(printersHardwareProvider.notifier).kickCashDrawer();
      if (!mounted) return;
      setState(() => _stage = _DrawerStage.success);
    } catch (_) {
      if (!mounted) return;
      setState(() => _stage = _DrawerStage.failed);
    }
  }
}