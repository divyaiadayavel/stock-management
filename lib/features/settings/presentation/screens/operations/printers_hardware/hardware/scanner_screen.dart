import 'package:flutter/material.dart';

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../core/constants/app_sizes.dart';
import '../../../../../../../core/constants/app_spacing.dart';
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Barcode Scanner', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                    color: (_listening ? AppColors.green : AppColors.textSecondary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Icon(Icons.qr_code_scanner, color: _listening ? AppColors.green : AppColors.textSecondary, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_listening ? 'Listening for scans' : 'Scanner idle', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      const Text(
                        'Works with any handheld scanner connected as a keyboard.',
                        style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _listening,
                  activeColor: Colors.white,
                  activeTrackColor: AppColors.primary,
                  onChanged: (_) => _toggleListening(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_listening)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: const Text(
                'Scan a barcode now — it will appear below.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: AppColors.cyanDim, fontWeight: FontWeight.w500),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text('Recent scans · ${_recentScans.length}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          if (_recentScans.isEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: const Text(
                'No scans yet. Turn on the scanner above and scan any barcode.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < _recentScans.length; i++) ...[
                    if (i != 0) const Divider(height: 1, indent: 48),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.qr_code, size: 18, color: AppColors.textSecondary),
                      title: Text(_recentScans[i], style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12.5, fontWeight: FontWeight.w600)),
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