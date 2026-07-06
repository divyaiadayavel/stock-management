import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../core/constants/app_sizes.dart';
import '../../../../../../../core/constants/app_spacing.dart';
import '../../../../../domain/entities/printers_hardware/printer/printer_settings.dart';
import '../../../../providers/printers_hardware/receipt/receipt_settings_provider.dart';

class ReceiptSettingsScreen extends ConsumerWidget {
  const ReceiptSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(receiptSettingsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Receipt Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: settingsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(receiptSettingsProvider),
        ),
        data: (settings) => _ReceiptSettingsForm(settings: settings),
      ),
    );
  }
}

class _ReceiptSettingsForm extends ConsumerStatefulWidget {
  const _ReceiptSettingsForm({required this.settings});

  final PrinterSettings settings;

  @override
  ConsumerState<_ReceiptSettingsForm> createState() =>
      _ReceiptSettingsFormState();
}

class _ReceiptSettingsFormState extends ConsumerState<_ReceiptSettingsForm> {
  late bool _showLogo;
  late bool _showGst;
  late String _paperSize;
  late TextEditingController _footerController;

  @override
  void initState() {
    super.initState();
    _showLogo = widget.settings.showLogo;
    _showGst = widget.settings.showGst;
    _paperSize = widget.settings.paperSize == 'mm58' ? 'mm58' : 'mm80';
    _footerController = TextEditingController(
      text: widget.settings.footerText,
    );
  }

  @override
  void dispose() {
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(receiptSettingsProvider).isLoading;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        _card(
          children: [
            _switchRow(
              title: 'Print store logo',
              value: _showLogo,
              onChanged: (value) => setState(() => _showLogo = value),
            ),
            const Divider(height: 1),
            _switchRow(
              title: 'Print GST number',
              value: _showGst,
              onChanged: (value) => setState(() => _showGst = value),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _card(
          children: [
            const Text(
              'Paper size',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'mm58', label: Text('58 mm')),
                ButtonSegment(value: 'mm80', label: Text('80 mm')),
              ],
              selected: {_paperSize},
              onSelectionChanged: (values) {
                setState(() => _paperSize = values.first);
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _card(
          children: [
            const Text(
              'Footer message',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _footerController,
              minLines: 2,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Thank you for shopping with us!',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          height: AppSizes.buttonHeightLg,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
            ),
            onPressed: isSaving ? null : _save,
            child: Text(
              isSaving ? 'Saving...' : 'Save Settings',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _switchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      value: value,
      activeThumbColor: Colors.white,
      activeTrackColor: AppColors.primary,
      onChanged: onChanged,
    );
  }

  Future<void> _save() async {
    final settings = widget.settings.copyWith(
      showLogo: _showLogo,
      showGst: _showGst,
      paperSize: _paperSize,
      footerText: _footerController.text.trim(),
    );

    await ref.read(receiptSettingsProvider.notifier).save(settings);
    if (!mounted) return;

    final latest = ref.read(receiptSettingsProvider);
    final messenger = ScaffoldMessenger.of(context);
    latest.whenOrNull(
      data: (_) => messenger.showSnackBar(
        const SnackBar(content: Text('Receipt settings saved')),
      ),
      error: (error, _) => messenger.showSnackBar(
        SnackBar(content: Text('Save failed: $error')),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.red, size: 36),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
