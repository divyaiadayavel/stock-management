import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/business_profile.dart';

import '../providers/settings_provider.dart';

// business/
import 'business/business_profile_screen.dart';
import 'business/invoice_tax_screen.dart';
import 'business/customize_screen.dart';

// staff/
import 'staff/roles_permissions_screen.dart';

// operations/data/
import 'operations/data/backup_sync_screen.dart';
import 'operations/data/notifications_screen.dart';

// operations/inventory/
import 'operations/printers_hardware/printer_management/printers_hardware_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final profile = await ref
          .read(settingsRepositoryProvider)
          .getBusinessProfile();

      if (!mounted) return;

      ref.read(storeNameProvider.notifier).state = profile.storeName;
      ref.read(taglineProvider.notifier).state = profile.tagline;
      ref.read(logoPathProvider.notifier).state = profile.logoPath;
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  void openEditDialog() {
    final storeName = ref.read(storeNameProvider);
    final tagline = ref.read(taglineProvider);
    final nameCtrl = TextEditingController(text: storeName);
    final taglineCtrl = TextEditingController(text: tagline);
    String? tempLogo = ref.read(logoPathProvider);

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              ),
              title: const Text("Edit Branding"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.08,
                          ),
                          backgroundImage: _logoImageProvider(tempLogo),
                          child: (tempLogo?.isEmpty ?? true)
                              ? const Icon(
                                  Icons.store,
                                  size: 45,
                                  color: AppColors.primary,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final file = await picker.pickImage(
                                source: ImageSource.gallery,
                              );

                              if (file != null) {
                                final timestamp =
                                    DateTime.now().millisecondsSinceEpoch;
                                final dir =
                                    await getApplicationDocumentsDirectory();
                                final newPath =
                                    "${dir.path}/logo_$timestamp.png";

                                final savedImage = await File(
                                  file.path,
                                ).copy(newPath);

                                setPopupState(() {
                                  tempLogo = savedImage.path;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: AppColors.textWhite,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: "App Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusLg,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: taglineCtrl,
                      decoration: InputDecoration(
                        labelText: "Tagline",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusLg,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(settingsRepositoryProvider)
                          .saveProfile(
                            BusinessProfile(
                              storeName: nameCtrl.text.trim(),
                              tagline: taglineCtrl.text.trim(),
                              logoPath: tempLogo ?? "",
                            ),
                          );

                      if (!context.mounted) return;
                      Navigator.pop(context);

                      await loadProfile();

                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text("Profile Saved Successfully"),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text("Failed to save: $e"),
                          backgroundColor: AppColors.red,
                        ),
                      );
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          title: const Text("Logout"),
          content: const Text("Do you want to logout from this account?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) return;

    ref.read(authControllerProvider.notifier).logout();
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  // ── Samsung-style profile header (top card) ──
  Widget profileHeader() {
    final storeName = ref.watch(storeNameProvider);
    final tagline = ref.watch(taglineProvider);
    final logoPath = ref.watch(logoPathProvider);

    return _groupCard(
      child: InkWell(
        onTap: openEditDialog,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName.isEmpty ? "Your Store Name" : storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardValue.copyWith(
                        fontSize: 19,
                        fontFamily: AppTextStyles.fontDisplay,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.border, width: 1),
                        ),
                      ),
                      child: Text(
                        tagline.isEmpty ? "Tap to edit branding" : tagline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    backgroundImage: _logoImageProvider(logoPath),
                    child: (logoPath == null || logoPath.isEmpty)
                        ? const Icon(
                            Icons.store,
                            size: 26,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.card, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: AppColors.textWhite,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Samsung-style grouped card wrapper ──
  Widget _groupCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  // ── Samsung-style group: tiles + a divider inset evenly on BOTH sides ──
  // (matches the reference — the line doesn't start after the icon,
  // it sits centered inside the card's horizontal padding)
  Widget _group(List<Widget> tiles) {
    final children = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      children.add(tiles[i]);
      if (i != tiles.length - 1) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.cardPadding,
            ),
            child: const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.border,
            ),
          ),
        );
      }
    }
    return _groupCard(child: Column(children: children));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final currentRole = authState.currentRole.isEmpty
        ? 'admin'
        : authState.currentRole;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text("Settings", style: AppTextStyles.appBarTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              profileHeader(),
              const SizedBox(height: AppSpacing.sm),

              _group([
                _tile(
                  Icons.store,
                  "Business Profile",
                  "Store details, address",
                  iconBg: AppColors.primary,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BusinessProfileScreen(),
                      ),
                    );
                    loadProfile();
                  },
                ),
                _tile(
                  Icons.receipt_long,
                  "Invoice & Tax",
                  "GST, invoice, taxes",
                  iconBg: AppColors.cyan,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InvoiceTaxScreen(),
                      ),
                    );
                  },
                ),
                _tile(
                  Icons.tune,
                  "Customize",
                  "Category, Units",
                  iconBg: AppColors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CustomizeScreen(),
                      ),
                    );
                  },
                ),
              ]),

              _group([
                _tile(
                  Icons.print,
                  "Printers & Hardware",
                  "Bluetooth, Thermal, Barcode",
                  iconBg: AppColors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PrintersHardwareScreen(),
                      ),
                    );
                  },
                ),
              ]),

              _group([
                _tile(
                  Icons.people,
                  "User Roles & Permissions",
                  "Manage staff and access",
                  iconBg: AppColors.primaryHover,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserRolesScreen(),
                      ),
                    );
                  },
                ),
              ]),

              _group([
                _tile(
                  Icons.backup,
                  "Backup & Sync",
                  "Auto backup and restore",
                  iconBg: AppColors.cyanDim,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BackupSyncScreen(),
                      ),
                    );
                  },
                ),
                _tile(
                  Icons.notifications,
                  "Notifications",
                  "Alerts and updates",
                  iconBg: AppColors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
              ]),

              const SizedBox(height: AppSpacing.xl),

              // ── Logout pinned at the bottom of the list ──
              _group([
                _tile(
                  Icons.logout,
                  "Logout",
                  "${authState.displayName} - $currentRole",
                  iconBg: AppColors.red,
                  titleColor: AppColors.red,
                  onTap: _confirmLogout,
                ),
              ]),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  // ── Samsung-style tile: solid colored circle + white icon, flat row ──
  Widget _tile(
    IconData icon,
    String title,
    String sub, {
    required Color iconBg,
    VoidCallback? onTap,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(
                icon,
                color: AppColors.textWhite,
                size: AppSizes.iconMd,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.cardValue.copyWith(
                      fontSize: 15,
                      fontFamily: AppTextStyles.fontBody,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: AppTextStyles.small,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _logoImageProvider(String? logoPath) {
    if (logoPath == null || logoPath.isEmpty) return null;

    final uri = Uri.tryParse(logoPath);
    if (uri != null && uri.hasScheme && uri.scheme.startsWith('http')) {
      return NetworkImage(logoPath);
    }

    return FileImage(File(logoPath));
  }
}