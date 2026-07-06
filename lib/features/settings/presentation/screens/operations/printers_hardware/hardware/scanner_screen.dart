import 'package:flutter/material.dart';

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../core/constants/app_sizes.dart';
import '../../../../../../../core/constants/app_spacing.dart';
import '../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../data/datasources/printers_hardware/hardware/scanner_datasource.dart';

/// Barcode Scanner hardware screen.
///
/// Catalystack's scanner support is a keyboard-wedge listener
/// (see [ScannerDataSource]) rather than a Bluetooth/USB pairing flow —
/// any handheld scanner that types into the OS like a keyboard works the
/// moment it's plugged in or paired at the OS level. This screen lets the
/// cashier verify that scans are being picked up and review recent reads.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ScannerDataSource _scannerDataSource = ScannerDataSourceImpl();
  final List<String> _recentScans = [];
  bool _listening = false;

  @override
  void dispose() {
    if (_listening) {
      _scannerDataSource.stopListening();
    }
    super.dispose();
  }

  void _toggleListening() {
    if (_listening) {
      _scannerDataSource.stopListening();
      setState(() => _listening = false);
      return;
    }

    _scannerDataSource.startListening();
    _scannerDataSource.barcodeStream.listen((code) {
      if (!mounted) return;
      setState(() => _recentScans.insert(0, code));
    });
    setState(() => _listening = true);
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
          'Barcode Scanner',
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
                    color: (_listening ? AppColors.green : AppColors.textSecondary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded, 
                    color: _listening ? AppColors.green : AppColors.textSecondary, 
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _listening ? 'Listening for scans' : 'Scanner idle', 
                        style: AppTextStyles.cardValue.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Works with any handheld scanner connected as a keyboard.',
                        style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _listening,
                  activeThumbColor: AppColors.textWhite,
                  activeTrackColor: AppColors.primary,
                  inactiveThumbColor: AppColors.textWhite,
                  inactiveTrackColor: AppColors.borderStrong,
                  onChanged: (_) => _toggleListening(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_listening)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: Text(
                'Scan a barcode now — it will appear below.',
                textAlign: TextAlign.center,
                style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.cyanDim, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
            child: Text(
              'Recent scans · ${_recentScans.length}', 
              style: AppTextStyles.small.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          if (_recentScans.isEmpty)
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                border: Border.all(color: AppColors.borderStrong),
              ),
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.document_scanner_outlined, size: 32, color: AppColors.borderStrong),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No scans yet',
                    style: AppTextStyles.cardValue.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Turn on the scanner above and scan any barcode.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.small.copyWith(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                border: Border.all(color: AppColors.borderStrong),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < _recentScans.length; i++) ...[
                    if (i != 0) const Divider(height: 1, indent: 48, color: AppColors.borderStrong),
                    ListTile(
                      dense: true,
                      leading: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        ),
                        child: const Icon(Icons.qr_code_rounded, size: 16, color: AppColors.textSecondary),
                      ),
                      title: Text(
                        _recentScans[i], 
                        style: AppTextStyles.cardValue.copyWith(fontFamily: 'JetBrains Mono', fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}