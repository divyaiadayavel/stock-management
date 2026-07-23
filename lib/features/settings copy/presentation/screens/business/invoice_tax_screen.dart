import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../providers/settings_provider.dart';

class InvoiceTaxScreen extends ConsumerStatefulWidget {
  const InvoiceTaxScreen({super.key});

  @override
  ConsumerState<InvoiceTaxScreen> createState() => _InvoiceTaxScreenState();
}

class _InvoiceTaxScreenState extends ConsumerState<InvoiceTaxScreen> {
  bool isLoading = true;

  // Default values
  String invoicePrefix = "INV";
  String invoiceFormat = "INV-0001";
  String nextInvoiceNumber = "INV-000123";
  String defaultDueDate = "15 Days";
  bool showGst = true;
  bool showDiscount = true;
  String invoiceFooter = "Thanks for your business!";
  String termsConditions = "No return without permission.";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await ref.read(settingsRepositoryProvider).getSettings();

    invoicePrefix = settings["invoicePrefix"] ?? "INV";
    invoiceFormat = settings["invoiceFormat"] ?? "INV-0001";
    nextInvoiceNumber = settings["nextInvoiceNumber"] ?? "INV-000123";
    defaultDueDate = settings["defaultDueDate"] ?? "15 Days";

    String? gstStored = settings["showGst"];
    showGst = gstStored == null ? true : gstStored == "true";

    String? discountStored = settings["showDiscount"];
    showDiscount = discountStored == null ? true : discountStored == "true";

    invoiceFooter = settings["invoiceFooter"] ?? "Thanks for your business!";
    termsConditions =
        settings["termsConditions"] ?? "No return without permission.";

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
      if (dbKey == "showGst") showGst = newValue;
      if (dbKey == "showDiscount") showDiscount = newValue;
    });
  }

  // ── Simple AlertDialog — Flutter handles keyboard avoidance itself ──
  void _openEditDialog(String title, String dbKey, String currentValue) {
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
          "Invoice & Tax",
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
                  _fieldCard(
                    icon: Icons.receipt_outlined,
                    iconColor: AppColors.primary,
                    title: "Invoice Prefix",
                    value: invoicePrefix,
                    dbKey: "invoicePrefix",
                  ),
                  _fieldCard(
                    icon: Icons.numbers,
                    iconColor: AppColors.cyan,
                    title: "Invoice Number Format",
                    value: invoiceFormat,
                    dbKey: "invoiceFormat",
                  ),
                  _fieldCard(
                    icon: Icons.tag,
                    iconColor: AppColors.primaryHover,
                    title: "Next Invoice Number",
                    value: nextInvoiceNumber,
                    dbKey: "nextInvoiceNumber",
                  ),
                  _fieldCard(
                    icon: Icons.calendar_today_outlined,
                    iconColor: AppColors.textSecondary,
                    title: "Default Due Date",
                    value: defaultDueDate,
                    dbKey: "defaultDueDate",
                  ),
                  _toggleCard(
                    icon: Icons.percent,
                    iconColor: AppColors.red,
                    title: "Show GST in Invoice",
                    value: showGst,
                    dbKey: "showGst",
                  ),
                  _toggleCard(
                    icon: Icons.discount_outlined,
                    iconColor: AppColors.green,
                    title: "Show Discount in Invoice",
                    value: showDiscount,
                    dbKey: "showDiscount",
                  ),
                  _fieldCard(
                    icon: Icons.format_align_center,
                    iconColor: AppColors.cyanDim,
                    title: "Invoice Footer",
                    value: invoiceFooter,
                    dbKey: "invoiceFooter",
                  ),
                  _fieldCard(
                    icon: Icons.article_outlined,
                    iconColor: AppColors.orange,
                    title: "Terms & Conditions",
                    value: termsConditions,
                    dbKey: "termsConditions",
                  ),
                ],
              ),
            ),
    );
  }

  // ── Modes & Routines-style card: own rounded card per field,
  //    icon in light grey circle, no chevron, gap below ──
  Widget _fieldCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String dbKey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          onTap: () => _openEditDialog(title, dbKey, value),
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

  // ── Same card shell, but with a Switch instead of a subtitle/tap ──
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