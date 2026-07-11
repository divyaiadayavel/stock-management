import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_sizes.dart';
import '../../../../../../core/constants/app_spacing.dart';
import '../../../../../../core/constants/app_text_styles.dart';
import '../../../providers/settings_provider.dart';

class BackupSyncScreen extends ConsumerStatefulWidget {
  const BackupSyncScreen({super.key});

  @override
  ConsumerState<BackupSyncScreen> createState() => _BackupSyncScreenState();
}

class _BackupSyncScreenState extends ConsumerState<BackupSyncScreen> {
  bool googleDrive = true;
  bool autoBackup = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await ref.read(settingsRepositoryProvider).getSettings();

    String? driveStr = settings["googleDriveBackup"];
    googleDrive = driveStr == null ? true : driveStr == "true";

    String? autoStr = settings["autoBackup"];
    autoBackup = autoStr == null ? true : autoStr == "true";

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateToggle(String key, bool value) async {
    await ref
        .read(settingsRepositoryProvider)
        .saveSetting(key, value.toString());
    setState(() {
      if (key == "googleDriveBackup") googleDrive = value;
      if (key == "autoBackup") autoBackup = value;
    });
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
          "Backup & Sync",
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
                  _sectionHeader("Backup"),
                  _toggleCard(
                    icon: Icons.cloud_queue,
                    iconColor: AppColors.green,
                    title: "Google Drive Backup",
                    subtitle: "Last backup: 20 May 2024, 10:30 AM",
                    value: googleDrive,
                    dbKey: "googleDriveBackup",
                  ),
                  _toggleCard(
                    icon: Icons.autorenew,
                    iconColor: AppColors.cyan,
                    title: "Auto Backup",
                    subtitle: "Daily at 10:00 PM",
                    value: autoBackup,
                    dbKey: "autoBackup",
                  ),
                  _actionCard(
                    icon: Icons.save_alt,
                    iconColor: AppColors.primary,
                    title: "Local Backup",
                    subtitle: "Create backup on this device",
                    onTap: () {},
                  ),
                  _actionCard(
                    icon: Icons.file_upload_outlined,
                    iconColor: AppColors.orange,
                    title: "Export Data",
                    subtitle: "Export data in Excel/CSV",
                    onTap: () {},
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  _sectionHeader("Restore"),
                  _actionCard(
                    icon: Icons.restore,
                    iconColor: AppColors.red,
                    title: "Restore from Backup",
                    subtitle: "Restore your previous backup",
                    onTap: () {},
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                  Center(
                    child: Text(
                      "Last synced: 20 May 2024, 10:30 AM",
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Syncing...")),
                        );
                      },
                      child: Text(
                        "Sync Now",
                        style: AppTextStyles.button.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm, top: AppSpacing.sm),
      child: Text(
        title,
        style: AppTextStyles.cardValue.copyWith(
          fontSize: 17,
          fontFamily: AppTextStyles.fontDisplay,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
        ),
      ),
    );
  }

  Widget _toggleCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
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
            Switch(
              value: value,
              activeThumbColor: AppColors.textWhite,
              activeTrackColor: AppColors.primary,
              inactiveThumbColor: AppColors.textWhite,
              inactiveTrackColor: AppColors.borderStrong,
              onChanged: (newValue) => _updateToggle(dbKey, newValue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard({
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
}