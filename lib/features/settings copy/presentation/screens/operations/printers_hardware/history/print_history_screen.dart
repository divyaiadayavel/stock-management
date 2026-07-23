import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../core/constants/app_sizes.dart';
import '../../../../../../../core/constants/app_spacing.dart';
import '../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../domain/entities/printers_hardware/history/print_history_entry.dart';
import '../../../../providers/printers_hardware/printer_management/printers_hardware_provider.dart';

final printHistoryProvider =
    FutureProvider.autoDispose<List<PrintHistoryEntry>>((ref) {
  return ref
      .read(printersHardwareRepositoryProvider)
      .getPrintHistory(limit: 100);
});

class PrintHistoryScreen extends ConsumerWidget {
  const PrintHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(printHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        title: Text(
          'Print History',
          style: AppTextStyles.cardValue.copyWith(
            fontSize: 22,
            fontFamily: AppTextStyles.fontDisplay,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(printHistoryProvider.future),
        color: AppColors.primary,
        child: historyState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _MessageState(
            icon: Icons.error_outline_rounded,
            title: 'Could not load print history',
            message: error.toString().replaceFirst('Exception: ', ''),
          ),
          data: (entries) {
            if (entries.isEmpty) {
              return const _MessageState(
                icon: Icons.history_rounded,
                title: 'No print history',
                message: 'Printed bills and failed attempts will appear here.',
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: entries.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) => _HistoryTile(
                entry: entries[index],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final PrintHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final statusColor = entry.isSuccess ? AppColors.green : AppColors.red;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.borderStrong),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.billReference.isEmpty
                      ? 'Print #${entry.id}'
                      : entry.billReference,
                  style: AppTextStyles.cardValue.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _statusChip(entry.printStatus, statusColor),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _metaRow(
            Icons.print_rounded,
            entry.printerName ?? entry.printerId ?? 'Unknown printer',
          ),
          const SizedBox(height: 6),
          _metaRow(
            Icons.schedule_rounded,
            _formatDate(entry.printedAt ?? entry.createdAt),
          ),
          const SizedBox(height: 6),
          _metaRow(
            Icons.receipt_long_rounded,
            '${entry.itemCount} items - Rs. ${entry.grandTotal.toStringAsFixed(2)}',
          ),
          if (!entry.isSuccess && (entry.errorMessage?.isNotEmpty ?? false)) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Text(
                entry.errorMessage!,
                style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.red),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.small.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.small.copyWith(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Unknown time';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} ${two(value.hour)}:${two(value.minute)}';
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: AppColors.surface2,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 40, color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.cardValue.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.small.copyWith(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}