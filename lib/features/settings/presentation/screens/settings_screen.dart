import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../notifications/presentation/screens/notification_settings_screen.dart';
import '../providers/settings_provider.dart';
import 'business/business_profile_screen.dart';
import 'business/invoice_tax_screen.dart';
import 'business/customize_screen.dart';
import 'operations/data/backup_sync_screen.dart';
import 'operations/printers_hardware/printer_management/printers_hardware_screen.dart';
import '../../service_management/presentation/screens/services_categories_screen.dart';
import '../../domain/entities/user_profile.dart';
import '../../../../core/network/api_config.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    try {
      final profile = await ref
          .read(settingsRepositoryProvider)
          .getUserProfile();

      if (!mounted) return;
      ref.read(profileNameProvider.notifier).state = profile.name;
      ref.read(profileRoleProvider.notifier).state = profile.role;
      ref.read(profilePictureProvider.notifier).state = profile.profilePicture;
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  void openEditDialog() {
    final storeName = ref.read(profileNameProvider);
    final tagline = ref.read(profileRoleProvider);
    final nameCtrl = TextEditingController(text: storeName);
    final taglineCtrl = TextEditingController(text: tagline);
    String? tempLogo = ref.read(profilePictureProvider);

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              ),
              title: const Text("Edit Profile"),
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

  if (file == null) return;

  setPopupState(() {
    tempLogo = file.path;
  });
},
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_enhance_outlined,
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
                        labelText: "Name",
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
                        labelText: "Role",
                        enabled: false,
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
      String? serverProfilePicture;

      // --------------------------------------------------
      // 1. Upload newly selected profile picture
      // --------------------------------------------------

      if (tempLogo != null &&
          tempLogo!.trim().isNotEmpty) {
        final localFile = File(tempLogo!);

        if (await localFile.exists()) {
          serverProfilePicture = await ref
              .read(
                settingsControllerProvider.notifier,
              )
              .uploadProfilePicture(localFile);
        } else {
          // Existing server image path.
          serverProfilePicture = tempLogo;
        }
      }

      // --------------------------------------------------
      // 2. Keep existing server picture if no new image
      // --------------------------------------------------

      final profilePicture =
          serverProfilePicture ??
          ref.read(profilePictureProvider) ??
          "";

      // --------------------------------------------------
      // 3. Save profile name + role
      // --------------------------------------------------

      await ref
          .read(
            settingsControllerProvider.notifier,
          )
          .saveUserProfile(
            UserProfile(
              id: 1,
              name: nameCtrl.text.trim(),
              role: taglineCtrl.text.trim(),
              profilePicture: profilePicture,
            ),
          );

      // --------------------------------------------------
      // 4. Close dialog
      // --------------------------------------------------

      if (!context.mounted) return;

      Navigator.pop(context);

      // --------------------------------------------------
      // 5. Reload from server
      // --------------------------------------------------

      await loadUserProfile();

      if (!mounted) return;

      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(
          content: Text(
            "Profile Saved Successfully",
          ),
        ),
      );

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to save: $e",
          ),
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

  Widget profileHeader() {
    final storeName = ref.watch(profileNameProvider);
    final tagline = ref.watch(profileRoleProvider);
    final logoPath = ref.watch(profilePictureProvider);

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
                      storeName.isEmpty ? "Your Name" : storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardValue.copyWith(
                        fontSize: 19,
                        fontFamily: AppTextStyles.fontDisplay,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tagline.isEmpty ? "Administrator" : tagline,
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
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
                            Icons.person,
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
                        Icons.camera_enhance_outlined,
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
                    loadUserProfile();
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
                _tile(
                  Icons.miscellaneous_services,
                  "Service Management",
                  "Categories, services, questions",
                  iconBg: AppColors.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ServicesCategoriesScreen(),
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
                        builder: (context) =>
                            const NotificationSettingsScreen(),
                      ),
                    );
                  },
                ),
              ]),

              const SizedBox(height: AppSpacing.xl),

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
    if (logoPath == null || logoPath.trim().isEmpty) {
      return null;
    }

    if (logoPath.startsWith("http")) {
      return NetworkImage(logoPath);
    }

    if (logoPath.startsWith("uploads/")) {
      return NetworkImage('${ApiConfig.baseUrl}/$logoPath');
    }

    if (File(logoPath).existsSync()) {
      return FileImage(File(logoPath));
    }

    return null;
  }
}
