import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../providers/settings_provider.dart';

class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() =>
      _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
  Map<String, dynamic> profileData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await ref
        .read(settingsRepositoryProvider)
        .getBusinessProfile();
    if (mounted) {
      setState(() {
        profileData = profile.toMap();
        isLoading = false;
      });
    }
  }

  // ── Simple, clean edit dialog — plain AlertDialog so Flutter
  //    handles keyboard avoidance automatically (no manual padding hacks) ──
  void _openEditDialog(
    String title,
    String dbKey,
    String currentValue, {
    bool required = true,
  }) {
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

              if (required && newValue.isEmpty) {
                setDialogState(() => errorText = "$title cannot be empty");
                return;
              }

              setDialogState(() {
                isSaving = true;
                errorText = null;
              });

              try {
                await ref
                    .read(settingsRepositoryProvider)
                    .updateProfileField(dbKey, newValue);

                if (!mounted) return;
                Navigator.pop(dialogContext);
                await _loadData();

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
          "Business Profile",
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
                    icon: Icons.store_mall_directory_outlined,
                    iconColor: AppColors.primary,
                    title: "Business Name",
                    value: (profileData['storeName']?.isEmpty ?? true)
                        ? "Not set"
                        : profileData['storeName'],
                    dbKey: "storeName",
                  ),
                  _fieldCard(
                    icon: Icons.location_on_outlined,
                    iconColor: AppColors.cyan,
                    title: "Business Address",
                    value: (profileData['businessAddress']?.isEmpty ?? true)
                        ? "Not set"
                        : profileData['businessAddress'],
                    dbKey: "businessAddress",
                    required: false,
                  ),
                  _fieldCard(
                    icon: Icons.phone_outlined,
                    iconColor: AppColors.green,
                    title: "Phone Number",
                    value: (profileData['phoneNumber']?.isEmpty ?? true)
                        ? "Not set"
                        : profileData['phoneNumber'],
                    dbKey: "phoneNumber",
                    required: false,
                  ),
                  _fieldCard(
                    icon: Icons.email_outlined,
                    iconColor: AppColors.orange,
                    title: "Email Address",
                    value: (profileData['emailAddress']?.isEmpty ?? true)
                        ? "Not set"
                        : profileData['emailAddress'],
                    dbKey: "emailAddress",
                    required: false,
                  ),
                  _fieldCard(
                    icon: Icons.receipt_long_outlined,
                    iconColor: AppColors.primaryHover,
                    title: "GST Number",
                    value: (profileData['gstNumber']?.isEmpty ?? true)
                        ? "Not set"
                        : profileData['gstNumber'],
                    dbKey: "gstNumber",
                    required: false,
                  ),
                  _fieldCard(
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: AppColors.cyanDim,
                    title: "Tax Registration Type",
                    value:
                        (profileData['taxRegistrationType']?.isEmpty ?? true)
                        ? "Regular"
                        : profileData['taxRegistrationType'],
                    dbKey: "taxRegistrationType",
                    required: false,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _fieldCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String dbKey,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          onTap: () => _openEditDialog(
            title,
            dbKey,
            value == "Not set" ? "" : value,
            required: required,
          ),
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
}