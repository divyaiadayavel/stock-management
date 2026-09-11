import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../core/constants/app_sizes.dart';
import '../../../../../../../core/constants/app_spacing.dart';
import '../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../domain/entities/printers_hardware/printer/printer_settings.dart';
import '../../../../providers/printers_hardware/receipt/receipt_settings_provider.dart';

class ReceiptSettingsScreen extends ConsumerWidget {
  const ReceiptSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(receiptSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        title: Text(
          'Receipt Settings',
          style: AppTextStyles.cardValue.copyWith(
            fontSize: 22,
            fontFamily: AppTextStyles.fontDisplay,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
          ),
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
            const Divider(height: 1, color: AppColors.borderStrong),
            _switchRow(
              title: 'Print GST number',
              value: _showGst,
              onChanged: (value) => setState(() => _showGst = value),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _card(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          children: [
            Text(
              'Paper size',
              style: AppTextStyles.cardValue.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                style: SegmentedButton.styleFrom(
                  selectedForegroundColor: AppColors.textWhite,
                  selectedBackgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  side: const BorderSide(color: AppColors.borderStrong),
                ),
                segments: [
                  ButtonSegment(
                    value: 'mm58', 
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text('58 mm', style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600, color: _paperSize == 'mm58' ? AppColors.textWhite : AppColors.textPrimaryDark)),
                    )
                  ),
                  ButtonSegment(
                    value: 'mm80', 
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text('80 mm', style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600, color: _paperSize == 'mm80' ? AppColors.textWhite : AppColors.textPrimaryDark)),
                    )
                  ),
                ],
                selected: {_paperSize},
                onSelectionChanged: (values) {
                  setState(() => _paperSize = values.first);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _card(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          children: [
            Text(
              'Footer message',
              style: AppTextStyles.cardValue.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _footerController,
              minLines: 2,
              maxLines: 3,
              style: AppTextStyles.cardValue.copyWith(fontSize: 14, fontFamily: AppTextStyles.fontBody),
              decoration: InputDecoration(
                hintText: 'Thank you for shopping with us!',
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
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
            onPressed: isSaving ? null : _save,
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.textWhite),
                  )
                : Text(
                    'Save Settings',
                    style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _card({required List<Widget> children, EdgeInsetsGeometry padding = EdgeInsets.zero}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.borderStrong),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.cardValue.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
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
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 40),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Failed to load settings',
              style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.small.copyWith(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                ),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text('Retry', style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
