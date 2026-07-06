import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../core/constants/app_sizes.dart';
import '../../../../../../../core/constants/app_spacing.dart';
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Print History',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(printHistoryProvider.future),
        child: historyState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _MessageState(
            icon: Icons.error_outline,
            title: 'Could not load print history',
            message: error.toString().replaceFirst('Exception: ', ''),
          ),
          data: (entries) {
            if (entries.isEmpty) {
              return const _MessageState(
                icon: Icons.history,
                title: 'No print history',
                message: 'Printed bills and failed attempts will appear here.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: entries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border),
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _statusChip(entry.printStatus, statusColor),
            ],
          ),
          const SizedBox(height: 8),
          _metaRow(
            Icons.print,
            entry.printerName ?? entry.printerId ?? 'Unknown printer',
          ),
          const SizedBox(height: 4),
          _metaRow(
            Icons.schedule,
            _formatDate(entry.printedAt ?? entry.createdAt),
          ),
          const SizedBox(height: 4),
          _metaRow(
            Icons.receipt_long,
            '${entry.itemCount} items - Rs. ${entry.grandTotal.toStringAsFixed(2)}',
          ),
          if (!entry.isSuccess && (entry.errorMessage?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            Text(
              entry.errorMessage!,
              style: const TextStyle(fontSize: 11, color: AppColors.red),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
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
        Icon(icon, size: 42, color: AppColors.textSecondary),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}