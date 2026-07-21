import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_sizes.dart';
import '../../../../../../core/constants/app_spacing.dart';
import '../../../../../../core/constants/app_text_styles.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/backup_sync/backup_sync_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../../core/storage/db_helper.dart'; // Links your database helper class
import 'package:intl/intl.dart';
import '../../../../../../core/services/notification_service.dart';

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
    final backupState = ref.watch(backupSyncControllerProvider);
    final backupController = ref.read(backupSyncControllerProvider.notifier);

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
                    title: backupState.account != null
                        ? "Google Drive (${backupState.account!.email})"
                        : "Google Drive Backup",
                    // ✅ Updated subtitle logic: Shows "Connected" if logged in but not synced yet
                    subtitle: backupState.account == null
                        ? "Not connected"
                        : (backupState.lastSync != null
                              ? "Last backup: ${backupState.lastSync}"
                              : "Connected (Ready to sync)"),
                    value: backupState.account != null,
                    onChanged: (val) async {
                      if (val) {
                        await backupController.connectDrive();
                      } else {
                        await backupController.disconnectDrive();
                      }
                    },
                  ),
                  _toggleCard(
                    icon: Icons.autorenew,
                    iconColor: AppColors.cyan,
                    title: "Auto Backup",
                    subtitle: "Daily at 10:00 PM",
                    value: autoBackup,
                    onChanged: (newValue) =>
                        _updateToggle("autoBackup", newValue),
                  ),
                  _actionCard(
                    icon: Icons.save_alt,
                    iconColor: AppColors.primary,
                    title: "Local Backup",
                    subtitle: "Create backup on this device",
                    onTap: () async {
                      final info = await backupController.localBackupNow();
                      if (info != null && mounted) {
                        // ✅ Trigger the native system menu to save or share the database file
                        await Share.shareXFiles(
                          [
                            XFile(info.id),
                          ], // info.id contains the absolute file path
                          text: "Stock Management Database Backup",
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Backup complete: ${info.fileName}"),
                          ),
                        );
                      }
                    },
                  ),
                  _actionCard(
                    icon: Icons.file_upload_outlined,
                    iconColor: AppColors.orange,
                    title: "Export Data",
                    subtitle: "Export data in Excel/CSV",
                    onTap: () async {
                      final path = await backupController.exportNow();
                      if (path != null && mounted) {
                        // ✅ Trigger the native system menu to send or open the CSV spreadsheet file
                        await Share.shareXFiles([
                          XFile(path),
                        ], text: "Stock Management Inventory Report");

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Exported successfully!")),
                        );
                      }
                    },
                  ),
                  _actionCard(
                    icon: Icons.file_download_outlined,
                    iconColor: AppColors.cyan,
                    title: "Import Data",
                    subtitle: "Import products via Excel/CSV spreadsheet",
                    onTap: () async {
                      final importedCount = await backupController
                          .importCsvNow();
                      if (importedCount != null && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Success! Bulk imported $importedCount products.",
                            ),
                            backgroundColor: AppColors.green,
                          ),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  _sectionHeader("Restore"),
                  _actionCard(
                    icon: Icons.restore,
                    iconColor: AppColors.red,
                    title: "Restore from Backup",
                    subtitle: "Restore your previous backup",
                    onTap: () async {
                      // ✅ Corrected: Direct static method call matching the latest API update
                      FilePickerResult? result = await FilePicker.pickFiles(
                        type: FileType.any,
                      );

                      if (result != null && result.files.single.path != null) {
                        final filePath = result.files.single.path!;

                        // Lock the database file pool safely before swapping
                        await DBHelper.closeDb();

                        // Overwrite the old database with the chosen backup file
                        await ref
                            .read(backupSyncControllerProvider.notifier)
                            .ref
                            .read(backupSyncRepositoryProvider)
                            .restoreFromLocal(filePath);

                        // Reopen the connection pool
                        await DBHelper.reopenDb();

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Database restored successfully! Please restart the app.",
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                  Center(
                    child: Text(
                      // ✅ Dynamically reads the lastSync timestamp state and formats it nicely
                      backupState.lastSync != null
                          ? "Last synced: ${DateFormat('dd MMM yyyy, hh:mm a').format(backupState.lastSync!)}"
                          : "Last synced: Never",
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
                        side: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                        ),
                      ),
                      onPressed: () async {
                        // 1. Trigger the background backup logic
                        final info = await backupController.backupNow();

                        if (mounted) {
                          if (info != null) {
                            // ✅ Success Path: The backup completed successfully!

                            // Trigger the snackbar
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Google Drive backup completed successfully.",
                                ),
                              ),
                            );

                            // Trigger your Local Notification instantly
                            await NotificationService.showBackupNotification();
                          } else {
                            // ❌ Failure Path: Sync failed or Google Drive wasn't connected
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Sync failed / not connected"),
                              ),
                            );
                          }
                        }
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
      padding: const EdgeInsets.only(
        left: 4,
        bottom: AppSpacing.sm,
        top: AppSpacing.sm,
      ),
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
    required ValueChanged<bool> onChanged,
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
              onChanged: onChanged,
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
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
