import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/storage/db_helper.dart';
import '../../core/constants/app_colors.dart';
import 'business_profile_screen.dart'; // Add this import
import 'invoice_tax_screen.dart'; // Add this at the top
import 'customize_screen.dart';
import 'printers_hardware_screen.dart';
import 'user_roles_screen.dart';
import 'backup_sync_screen.dart';
import 'notifications_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';

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
      final data = await DBHelper.getProfile();

      if (data != null) {
        if (!mounted) return;

        ref.read(storeNameProvider.notifier).state = data['storeName'] ?? "";

        ref.read(taglineProvider.notifier).state = data['tagline'] ?? "";

        ref.read(logoPathProvider.notifier).state = data['logoPath'];
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  void openEditDialog() {
    final storeName = ref.read(storeNameProvider);
    final tagline = ref.read(taglineProvider);
    final logoPath = ref.read(logoPathProvider);
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
                          backgroundImage:
                              tempLogo != null && tempLogo!.isNotEmpty
                              ? FileImage(File(tempLogo!))
                              : null,
                          child: (tempLogo == null || tempLogo!.isEmpty)
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
                      await DBHelper.saveProfile(
                        storeName: nameCtrl.text.trim(),
                        tagline: taglineCtrl.text.trim(),
                        logoPath: tempLogo ?? "",
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                      }

                      await loadProfile();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Profile Saved Successfully"),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Failed to save: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
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
                backgroundImage: logoPath != null && logoPath!.isNotEmpty
                    ? FileImage(File(logoPath!))
                    : null,
                child: (logoPath == null || logoPath!.isEmpty)
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
    final storeName = ref.watch(storeNameProvider);

    final tagline = ref.watch(taglineProvider);

    final logoPath = ref.watch(logoPathProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            profileCard(),
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
            const Text("STAFF", style: TextStyle(fontWeight: FontWeight.bold)),
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
}
