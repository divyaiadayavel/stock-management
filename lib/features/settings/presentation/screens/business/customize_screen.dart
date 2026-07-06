import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../providers/settings_provider.dart';

class CustomizeScreen extends ConsumerStatefulWidget {
  const CustomizeScreen({super.key});

  @override
  ConsumerState<CustomizeScreen> createState() => _CustomizeScreenState();
}

class _CustomizeScreenState extends ConsumerState<CustomizeScreen> {
  bool isLoading = true;

  // Default values
  bool barcodeEnabled = true;
  bool lowStockAlert = true;
  String lowStockLimit = "5";
  bool stockManagement = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await ref.read(settingsRepositoryProvider).getSettings();

    String? barcodeStr = settings["barcodeEnabled"];
    barcodeEnabled = barcodeStr == null ? true : barcodeStr == "true";

    String? alertStr = settings["lowStockAlert"];
    lowStockAlert = alertStr == null ? true : alertStr == "true";

    lowStockLimit = settings["lowStockLimit"] ?? "5";

    String? stockStr = settings["stockManagement"];
    stockManagement = stockStr == null ? true : stockStr == "true";

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateToggleSetting(String dbKey, bool newValue) async {
    await ref
        .read(settingsRepositoryProvider)
        .saveSetting(dbKey, newValue.toString());
    setState(() {
      if (dbKey == "barcodeEnabled") barcodeEnabled = newValue;
      if (dbKey == "lowStockAlert") lowStockAlert = newValue;
      if (dbKey == "stockManagement") stockManagement = newValue;
    });
  }

  // ── Simple AlertDialog — Adapted from InvoiceTaxScreen ──
  void _openEditDialog(String title, String dbKey, String currentValue, {TextInputType? keyboardType}) {
    final TextEditingController ctrl = TextEditingController(
      text: currentValue,
    );
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;
        String? errorText;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> handleSave() async {
              final newValue = ctrl.text.trim();

              setDialogState(() {
                isSaving = true;
                errorText = null;
              });

              try {
                await ref
                    .read(settingsRepositoryProvider)
                    .saveSetting(dbKey, newValue);

                if (!mounted) return;
                Navigator.pop(dialogContext);
                await _loadSettings();

                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text("$title updated")),
                );
              } catch (e) {
                setDialogState(() {
                  isSaving = false;
                  errorText = "Failed to save. Try again.";
                });
              }
            }

            return AlertDialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              titlePadding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              contentPadding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              title: Text(
                title,
                style: AppTextStyles.cardValue.copyWith(
                  fontSize: 17,
                  fontFamily: AppTextStyles.fontDisplay,
                ),
              ),
              content: TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: keyboardType,
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (errorText != null) {
                    setDialogState(() => errorText = null);
                  }
                },
                onSubmitted: (_) => handleSave(),
                style: AppTextStyles.cardValue.copyWith(
                  fontFamily: AppTextStyles.fontBody,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  errorText: errorText,
                  filled: true,
                  fillColor: AppColors.surface2,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: const BorderSide(color: AppColors.red),
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(
                    "Cancel",
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: isSaving ? null : handleSave,
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          "Save",
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
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
        titleSpacing: 0,
        title: Text(
          "Customize (Products & Units)",
          style: AppTextStyles.cardValue.copyWith(
            fontSize: 22,
            fontFamily: AppTextStyles.fontDisplay,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _navCard(
                    icon: Icons.category_outlined,
                    iconColor: AppColors.red,
                    title: "Product Categories",
                    subtitle: "Manage your product categories",
                    onTap: () {
                      // Navigate to Categories Screen
                    },
                  ),
                  _navCard(
                    icon: Icons.ad_units,
                    iconColor: AppColors.orange,
                    title: "Units",
                    subtitle: "Manage product units",
                    onTap: () {
                      // Navigate to Units Screen
                    },
                  ),
                  _toggleCard(
                    icon: Icons.qr_code_scanner,
                    iconColor: AppColors.green,
                    title: "Barcode Settings",
                    value: barcodeEnabled,
                    dbKey: "barcodeEnabled",
                  ),
                  _toggleCard(
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppColors.orange,
                    title: "Low Stock Alert",
                    value: lowStockAlert,
                    dbKey: "lowStockAlert",
                  ),
                  _fieldCard(
                    icon: Icons.sim_card_outlined,
                    iconColor: AppColors.cyan,
                    title: "Low Stock Limit",
                    value: lowStockLimit,
                    dbKey: "lowStockLimit",
                    keyboardType: TextInputType.number,
                  ),
                  _toggleCard(
                    icon: Icons.inventory_2_outlined,
                    iconColor: AppColors.primary,
                    title: "Stock Management",
                    value: stockManagement,
                    dbKey: "stockManagement",
                  ),
                ],
              ),
            ),
    );
  }

  // ── Field Card: own rounded card per field with text value ──
  Widget _fieldCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String dbKey,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          onTap: () => _openEditDialog(title, dbKey, value, keyboardType: keyboardType),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.cardPadding,
              vertical: AppSpacing.lg,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.surface2,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: AppSizes.iconMd),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.cardValue.copyWith(
                          fontSize: 16,
                          fontFamily: AppTextStyles.fontDisplay,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        style: AppTextStyles.small.copyWith(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Nav Card: Similar to field card, but for navigation triggers ──
  Widget _navCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.cardPadding,
              vertical: AppSpacing.lg,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.surface2,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: AppSizes.iconMd),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.cardValue.copyWith(
                          fontSize: 16,
                          fontFamily: AppTextStyles.fontDisplay,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: AppTextStyles.small.copyWith(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Toggle Card: Uses a switch instead of tap ──
  Widget _toggleCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool value,
    required String dbKey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.surface2,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: AppSizes.iconMd),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.cardValue.copyWith(
                  fontSize: 16,
                  fontFamily: AppTextStyles.fontDisplay,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ),
            Switch(
              value: value,
              activeThumbColor: AppColors.textWhite,
              activeTrackColor: AppColors.primary,
              inactiveThumbColor: AppColors.textWhite,
              inactiveTrackColor: AppColors.borderStrong,
              onChanged: (newValue) => _updateToggleSetting(dbKey, newValue),
            ),
          ],
        ),
      ),
    );
  }
}