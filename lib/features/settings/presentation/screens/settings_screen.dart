import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_curve.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/business_profile.dart';

import '../providers/settings_provider.dart';

// business/
import 'business/business_profile_screen.dart';
import 'business/invoice_tax_screen.dart';
import 'business/customize_screen.dart';

// staff/
import 'staff/roles_permissions_screen.dart';

// operations/hardware/
import 'operations/hardware/printers_hardware_screen.dart';

// operations/data/
import 'operations/data/backup_sync_screen.dart';
import 'operations/data/notifications_screen.dart';

// operations/inventory/
import 'operations/inventory/inventory_preferences_screen.dart';

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
                borderRadius: BorderRadius.circular(20),
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
                          backgroundColor: Colors.blue.shade50,
                          backgroundImage: _logoImageProvider(tempLogo),
                          child: (tempLogo?.isEmpty ?? true)
                              ? const Icon(
                                  Icons.store,
                                  size: 45,
                                  color: Colors.blue,
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
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: "App Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: taglineCtrl,
                      decoration: InputDecoration(
                        labelText: "Tagline",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
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
                          backgroundColor: Colors.red,
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

  Widget profileCard() {
    final storeName = ref.watch(storeNameProvider);
    final tagline = ref.watch(taglineProvider);
    final logoPath = ref.watch(logoPathProvider);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue.shade50,
                backgroundImage: _logoImageProvider(logoPath),
                child: (logoPath == null || logoPath.isEmpty)
                    ? const Icon(Icons.store, size: 45, color: Colors.blue)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: openEditDialog,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            storeName.isEmpty ? "Your Store Name" : storeName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tagline.isEmpty ? "Add your tagline" : tagline,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final currentRole = authState.currentRole.isEmpty
        ? 'admin'
        : authState.currentRole;

    return Scaffold(
      backgroundColor: AppColors.primary,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Container(
        color: AppColors.primary,

        child: ClipRRect(
          borderRadius: AppCurve.top(context),

          child: Container(
            color: Colors.grey.shade100,

            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  profileCard(),
                  const SizedBox(height: 20),
                  const Text(
                    "ACCOUNT",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _tile(
                    Icons.logout,
                    "Logout",
                    "${authState.displayName} - $currentRole",
                    onTap: _confirmLogout,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "BUSINESS",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // ✅ Updated Tile to handle navigation
                  _tile(
                    Icons.store,
                    "Business Profile",
                    "Store details, address",
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BusinessProfileScreen(),
                        ),
                      );
                      loadProfile(); // Reload in case store name was updated
                    },
                  ),

                  _tile(
                    Icons.receipt_long,
                    "Invoice & Tax",
                    "GST, invoice, taxes",
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CustomizeScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "HARDWARE",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _tile(
                    Icons.print,
                    "Printers & Hardware",
                    "Bluetooth, Thermal, Barcode",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrintersHardwareScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "STAFF",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _tile(
                    Icons.people,
                    "User Roles & Permissions",
                    "Manage staff and access",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserRolesScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "DATA & PREFERENCES",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _tile(
                    Icons.backup,
                    "Backup & Sync",
                    "Auto backup and restore",
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Added onTap parameter and wrapped in InkWell
  Widget _tile(IconData icon, String title, String sub, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: Icon(icon, color: Colors.black54),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(sub, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
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
