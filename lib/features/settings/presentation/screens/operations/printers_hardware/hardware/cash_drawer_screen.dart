import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../core/constants/app_sizes.dart';
import '../../../../../../../core/constants/app_spacing.dart';
import '../../../../../../../core/constants/app_text_styles.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        title: Text(
          'Cash Drawer',
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: const Icon(Icons.point_of_sale_rounded, color: AppColors.green, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        printer == null ? 'No printer connected' : 'Linked via ${printer.name}',
                        style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        printer == null
                            ? 'Connect a printer that supports a drawer kick'
                            : supportsKick
                                ? 'Drawer-kick supported'
                                : 'This printer does not support a drawer kick',
                        style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Center(child: _stageContent(printer != null && supportsKick)),
          const SizedBox(height: AppSpacing.xxl),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              border: Border.all(color: AppColors.borderStrong),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Open drawer automatically on cash sale', 
                    style: AppTextStyles.cardValue.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Switch.adaptive(
                  value: _openOnSale,
                  activeThumbColor: AppColors.textWhite,
                  activeTrackColor: AppColors.primary,
                  inactiveThumbColor: AppColors.textWhite,
                  inactiveTrackColor: AppColors.borderStrong,
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
              width: 80,
              height: 80,
              decoration: const BoxDecoration(color: AppColors.surface2, shape: BoxShape.circle),
              child: const Icon(Icons.point_of_sale_rounded, size: 36, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Test the drawer kick', style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              'Sends a pulse to open the drawer right now.',
              style: AppTextStyles.small.copyWith(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
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
                onPressed: canOpen ? _openDrawer : null,
                icon: const Icon(Icons.lock_open_rounded, size: 18),
                label: Text('Open Drawer', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        );
      case _DrawerStage.opening:
        return Column(
          children: [
            const SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(width: 80, height: 80, child: CircularProgressIndicator(strokeWidth: 4, color: AppColors.cyan)),
                  Icon(Icons.lock_clock_rounded, color: AppColors.primary, size: 30),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Opening…', style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        );
      case _DrawerStage.success:
        return Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: AppColors.green, size: 40),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Drawer Opened', style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: () => setState(() => _stage = _DrawerStage.idle),
              child: Text('Test again', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          ],
        );
      case _DrawerStage.failed:
        return Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, color: AppColors.red, size: 40),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Could not open drawer', style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 4),
            Text('Check the printer connection and try again.', style: AppTextStyles.small.copyWith(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: () => setState(() => _stage = _DrawerStage.idle),
              child: Text('Try again', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
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