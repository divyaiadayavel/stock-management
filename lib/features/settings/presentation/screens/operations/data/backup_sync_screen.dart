import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_sizes.dart';
import '../../../../../../core/constants/app_spacing.dart';
import '../../../../../../core/constants/app_text_styles.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/backup_sync/backup_sync_provider.dart';
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

    await ref
        .read(backupSyncRepositoryProvider)
        .saveBackupSettings(settings: {key: value.toString()});

    await _loadSettings();

    if (mounted) {
      setState(() {});
    }
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
                    title: backupState.isConnected
                        ? "Google Drive (${backupState.account?.email ?? ''})"
                        : "Google Drive Backup",
                    subtitle: backupState.isConnected
                        ? (backupState.lastSync != null
                              ? "Last backup: ${DateFormat('dd MMM yyyy, hh:mm a').format(backupState.lastSync!)}"
                              : "Connected (Ready to sync)")
                        : "Not connected",
                    value: backupState.isConnected,
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
                  const SizedBox(height: AppSpacing.lg),
                  _sectionHeader("Restore"),
                  _actionCard(
                    icon: Icons.restore,
                    iconColor: AppColors.red,
                    title: "Restore from Backup",
                    subtitle: "Restore data from Google Drive backup",
                    onTap: () => _showRestoreDialog(backupController),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Center(
                    child: Text(
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
                        final info = await backupController.backupNow();
                        if (mounted) {
                          if (info != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Google Drive backup completed successfully.",
                                ),
                              ),
                            );
                            await NotificationService.showBackupNotification();
                          } else {
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

  // ── Helper: Show restore dialog with history ─────────────────────
  Future<void> _showRestoreDialog(BackupSyncController controller) async {
    // Use a local variable to avoid using context after it's disposed.
    if (!mounted) return;
    final history = await controller.fetchHistory();
    if (!mounted) return;
    if (history.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No backups found')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from Backup'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: history.length,
            itemBuilder: (_, index) {
              final entry = history[index];
              return ListTile(
                title: Text(entry.backupName),
                subtitle: Text(
                  '${entry.fileName} - ${DateFormat('dd MMM yyyy HH:mm').format(entry.createdAt)}',
                ),
                trailing: Text(
                  '${(entry.fileSize / 1024).toStringAsFixed(1)} KB',
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  // Confirm dialog
                  final confirm = await showDialog<bool>(
                    context: ctx,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Confirm Restore'),
                      content: Text(
                        'Restore backup from ${entry.backupName}? '
                        'This will replace all current data.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Restore'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await controller.restoreFromDrive(entry.driveFileId!);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Restore completed successfully!'),
                          ),
                        );
                        await controller.refreshStatus();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Restore failed: $e')),
                        );
                      }
                    }
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
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
