import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/settings_provider.dart';

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

  void _openEditDialog(String title, String dbKey, String currentValue) {
    final TextEditingController ctrl = TextEditingController(
      text: currentValue,
    );
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text("Edit $title"),
          content: TextField(
            controller: ctrl,
            decoration: InputDecoration(
              labelText: title,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(dialogContext);
                String newValue = ctrl.text.trim();
                await ref
                    .read(settingsRepositoryProvider)
                    .updateProfileField(dbKey, newValue);

                if (!mounted) return;
                navigator.pop();
                _loadData();
                messenger.showSnackBar(
                  SnackBar(content: Text("$title updated successfully")),
                );
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Business Profile",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                      child: Text(
                        "Business Information",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    _buildListItem(
                      icon: Icons.store_mall_directory_outlined,
                      title: "Business Name",
                      value: profileData['storeName']?.isEmpty ?? true
                          ? "Not set"
                          : profileData['storeName'],
                      dbKey: "storeName",
                    ),
                    _buildDivider(),
                    _buildListItem(
                      icon: Icons.location_on_outlined,
                      title: "Business Address",
                      value: profileData['businessAddress']?.isEmpty ?? true
                          ? "Not set"
                          : profileData['businessAddress'],
                      dbKey: "businessAddress",
                    ),
                    _buildDivider(),
                    _buildListItem(
                      icon: Icons.phone_outlined,
                      title: "Phone Number",
                      value: profileData['phoneNumber']?.isEmpty ?? true
                          ? "Not set"
                          : profileData['phoneNumber'],
                      dbKey: "phoneNumber",
                    ),
                    _buildDivider(),
                    _buildListItem(
                      icon: Icons.email_outlined,
                      title: "Email Address",
                      value: profileData['emailAddress']?.isEmpty ?? true
                          ? "Not set"
                          : profileData['emailAddress'],
                      dbKey: "emailAddress",
                    ),
                    _buildDivider(),
                    _buildListItem(
                      icon: Icons.receipt_long_outlined,
                      title: "GST Number",
                      value: profileData['gstNumber']?.isEmpty ?? true
                          ? "Not set"
                          : profileData['gstNumber'],
                      dbKey: "gstNumber",
                    ),
                    _buildDivider(),
                    _buildListItem(
                      icon: Icons.account_balance_wallet_outlined,
                      title: "Tax Registration Type",
                      value: profileData['taxRegistrationType']?.isEmpty ?? true
                          ? "Regular"
                          : profileData['taxRegistrationType'],
                      dbKey: "taxRegistrationType",
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      color: Color(0xFFEEEEEE),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    required String value,
    required String dbKey,
  }) {
    return InkWell(
      onTap: () =>
          _openEditDialog(title, dbKey, value == "Not set" ? "" : value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.indigo.shade400, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
